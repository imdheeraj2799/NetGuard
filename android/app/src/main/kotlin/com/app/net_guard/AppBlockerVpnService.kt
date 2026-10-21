package com.app.net_guard

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.VpnService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.util.Log
import java.io.FileInputStream
import java.io.IOException
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.Future

/**
 * A local loopback VPN service acting as a per-app sinkhole firewall.
 * It routes network packets from designated blocked applications into the
 * local loopback TUN interface where they are discarded. All other applications
 * bypass the VPN and access the internet directly.
 */
class AppBlockerVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private var tunInput: FileInputStream? = null
    private var drainFuture: Future<*>? = null
    private val packetExecutor: ExecutorService = Executors.newSingleThreadExecutor()

    private val retryHandler = Handler(Looper.getMainLooper())
    private var retryRunnable: Runnable? = null
    private var retryCount = 0

    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    @Volatile
    private var isDraining = false

    @Volatile
    private var currentBlockedPackages: Set<String> = emptySet()

    override fun onCreate() {
        super.onCreate()
        isServiceRunning = true
        registerNetworkCallback()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        when (action) {
            ACTION_STOP -> {
                cancelPendingRetry()
                try {
                    startForeground(NOTIFICATION_ID, createNotification(0, VpnState.INACTIVE))
                } catch (_: Exception) {
                }
                stopVpn()
                VpnStatusMonitor.update(VpnState.INACTIVE, 0, "Firewall stopped.")
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_RESTART -> {
                retryCount = 0
                cancelPendingRetry()
                val packages = intent.getStringArrayListExtra(EXTRA_BLOCKED_PACKAGES)?.toSet()
                    ?: loadBlockedPackages(this)
                handleStartOrUpdate(packages)
            }
            ACTION_START, ACTION_UPDATE, null -> {
                val packages = intent?.getStringArrayListExtra(EXTRA_BLOCKED_PACKAGES)?.toSet()
                    ?: loadBlockedPackages(this)
                handleStartOrUpdate(packages)
            }
        }
        return START_STICKY
    }

    private fun handleStartOrUpdate(blockedPackages: Set<String>) {
        currentBlockedPackages = blockedPackages

        if (blockedPackages.isEmpty()) {
            cancelPendingRetry()
            try {
                startForeground(NOTIFICATION_ID, createNotification(0, VpnState.INACTIVE))
            } catch (_: Exception) {
            }
            stopVpn()
            VpnStatusMonitor.update(VpnState.INACTIVE, 0, null)
            stopSelf()
            return
        }

        saveBlockedPackages(this, blockedPackages)
        try {
            startForeground(NOTIFICATION_ID, createNotification(blockedPackages.size, VpnState.ACTIVE))
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start foreground notification: ${e.message}")
        }

        configureVpn(blockedPackages)
    }

    override fun onRevoke() {
        Log.w(TAG, "VPN permission revoked by Android system or another VPN")
        cancelPendingRetry()
        val count = currentBlockedPackages.size.coerceAtLeast(loadBlockedPackages(this).size)
        // Keep saved blocked packages intact!
        stopVpn()
        VpnStatusMonitor.update(
            VpnState.INACTIVE,
            count,
            "VPN permission revoked. Tap to restore protection.",
        )
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            notificationManager?.notify(NOTIFICATION_ID, createNotification(count, VpnState.INACTIVE))
        } catch (_: Exception) {
        }
        stopSelf()
        super.onRevoke()
    }

    override fun onDestroy() {
        cancelPendingRetry()
        unregisterNetworkCallback()
        stopVpn()
        isServiceRunning = false
        isVpnEstablished = false
        VpnStatusMonitor.update(
            VpnState.INACTIVE,
            currentBlockedPackages.size,
            "VPN service stopped.",
        )
        packetExecutor.shutdownNow()
        super.onDestroy()
    }

    private fun registerNetworkCallback() {
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager ?: return
        if (networkCallback != null) return

        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                super.onAvailable(network)
                Log.d(TAG, "Network became available: $network")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    try {
                        setUnderlyingNetworks(arrayOf(network))
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to set underlying networks: ${e.message}")
                    }
                }
                ensureVpnActive()
            }

            override fun onLost(network: Network) {
                super.onLost(network)
                Log.d(TAG, "Network connection lost: $network")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    try {
                        setUnderlyingNetworks(null)
                    } catch (_: Exception) {}
                }
            }

            override fun onCapabilitiesChanged(network: Network, networkCapabilities: NetworkCapabilities) {
                super.onCapabilitiesChanged(network, networkCapabilities)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    try {
                        setUnderlyingNetworks(arrayOf(network))
                    } catch (_: Exception) {}
                }
            }
        }

        networkCallback = callback
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                cm.registerDefaultNetworkCallback(callback)
            } else {
                val request = NetworkRequest.Builder()
                    .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                    .build()
                cm.registerNetworkCallback(request, callback)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register network callback: ${e.message}")
        }
    }

    private fun unregisterNetworkCallback() {
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager ?: return
        networkCallback?.let {
            try {
                cm.unregisterNetworkCallback(it)
            } catch (_: Exception) {}
        }
        networkCallback = null
    }

    private fun ensureVpnActive() {
        val packages = if (currentBlockedPackages.isNotEmpty()) {
            currentBlockedPackages
        } else {
            loadBlockedPackages(this)
        }

        if (packages.isNotEmpty() && (vpnInterface == null || !isDraining)) {
            Log.i(TAG, "Ensuring VPN tunnel active after network event...")
            configureVpn(packages)
        }
    }

    private fun configureVpn(blockedPackages: Set<String>) {
        if (blockedPackages.isEmpty()) {
            stopVpn()
            stopSelf()
            return
        }

        val builder = Builder()
            .setSession(getString(R.string.app_name))
            .setMtu(1500)
            .addAddress(IPV4_ADDRESS, 32)

        try {
            builder.addAddress(IPV6_ADDRESS, 128)
        } catch (e: Exception) {
            Log.w(TAG, "IPv6 address assignment unsupported: ${e.message}")
        }

        builder.addRoute("0.0.0.0", 0)
        try {
            builder.addRoute("::", 0)
        } catch (e: Exception) {
            Log.w(TAG, "IPv6 default route unsupported: ${e.message}")
        }

        // Direct traffic exclusively for the blocked packages into this VPN sinkhole
        blockedPackages.forEach { pkg ->
            try {
                builder.addAllowedApplication(pkg)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to add allowed application $pkg: ${e.message}")
            }
        }

        val newDescriptor = try {
            builder.establish()
        } catch (e: Exception) {
            Log.e(TAG, "Exception establishing VPN interface: ${e.message}", e)
            null
        }

        if (newDescriptor == null) {
            Log.e(TAG, "builder.establish() returned null")
            isVpnEstablished = false
            handleConfigurationFailure(blockedPackages)
            return
        }

        // Seamless handover: close previous interface AFTER the new interface is established
        val oldDescriptor = vpnInterface
        val oldInput = tunInput

        vpnInterface = newDescriptor
        val newInput = FileInputStream(newDescriptor.fileDescriptor)
        tunInput = newInput

        try {
            oldInput?.close()
        } catch (_: Exception) {
        }
        try {
            oldDescriptor?.close()
        } catch (_: Exception) {
        }

        isDraining = true
        drainFuture?.cancel(true)
        drainFuture = packetExecutor.submit {
            processTunPackets(newInput, newDescriptor)
        }

        // Success: Reset retry counters and announce ACTIVE status
        retryCount = 0
        cancelPendingRetry()
        isVpnEstablished = true
        VpnStatusMonitor.update(VpnState.ACTIVE, blockedPackages.size, null)
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            notificationManager?.notify(
                NOTIFICATION_ID,
                createNotification(blockedPackages.size, VpnState.ACTIVE),
            )
        } catch (_: Exception) {}
    }

    private fun handleConfigurationFailure(blockedPackages: Set<String>) {
        if (VpnService.prepare(this) != null) {
            Log.w(TAG, "VPN permission is no longer granted.")
            VpnStatusMonitor.update(
                VpnState.INACTIVE,
                blockedPackages.size,
                "VPN permission revoked. Tap to restore protection.",
            )
            updateNotification(blockedPackages.size, VpnState.INACTIVE)
            return
        }

        if (retryCount >= MAX_RETRIES) {
            Log.e(TAG, "Max restart attempts ($MAX_RETRIES) reached. Halting auto-restart.")
            VpnStatusMonitor.update(
                VpnState.INACTIVE,
                blockedPackages.size,
                "Automatic recovery failed after $MAX_RETRIES attempts. Tap to restore.",
            )
            updateNotification(blockedPackages.size, VpnState.INACTIVE)
            return
        }

        retryCount++
        val delayMs = (1000L * (1 shl (retryCount - 1))).coerceAtMost(8000L)
        Log.w(TAG, "VPN configure failed. Scheduling retry $retryCount/$MAX_RETRIES in ${delayMs}ms")
        val reason = "Restarting firewall (attempt $retryCount/$MAX_RETRIES)..."
        VpnStatusMonitor.update(VpnState.RESTARTING, blockedPackages.size, reason)
        updateNotification(blockedPackages.size, VpnState.RESTARTING)

        cancelPendingRetry()
        val runnable = Runnable {
            try {
                configureVpn(blockedPackages)
            } catch (e: Exception) {
                Log.e(TAG, "Retry configuration error: ${e.message}")
                handleConfigurationFailure(blockedPackages)
            }
        }
        retryRunnable = runnable
        retryHandler.postDelayed(runnable, delayMs)
    }

    private fun cancelPendingRetry() {
        retryRunnable?.let { retryHandler.removeCallbacks(it) }
        retryRunnable = null
    }

    private fun updateNotification(blockedCount: Int, state: VpnState) {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            notificationManager?.notify(NOTIFICATION_ID, createNotification(blockedCount, state))
        } catch (e: Exception) {
            Log.w(TAG, "Failed to update notification: ${e.message}")
        }
    }

    private fun processTunPackets(
        input: FileInputStream,
        descriptor: ParcelFileDescriptor,
    ) {
        val buffer = ByteArray(MAX_PACKET_SIZE)
        try {
            while (isDraining && vpnInterface === descriptor) {
                val length = input.read(buffer)
                if (length <= 0) break
                // Sinkhole: packets from blocked applications are discarded here.
            }
        } catch (_: IOException) {
            // Expected when the TUN descriptor is closed
        }
    }

    private fun stopVpn() {
        isDraining = false
        isVpnEstablished = false
        drainFuture?.cancel(true)
        drainFuture = null
        try {
            tunInput?.close()
        } catch (_: IOException) {
        }
        tunInput = null
        try {
            vpnInterface?.close()
        } catch (_: IOException) {
        }
        vpnInterface = null
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        try {
            notificationManager?.cancel(NOTIFICATION_ID)
        } catch (_: Exception) {
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    private fun createNotification(blockedAppsCount: Int, state: VpnState): Notification {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    NOTIFICATION_CHANNEL_ID,
                    getString(R.string.vpn_notification_channel_name),
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = getString(R.string.vpn_notification_channel_description)
                    setShowBadge(false)
                },
            )
        }
        val openAppIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notificationBuilder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }

        val (title, text) = when (state) {
            VpnState.ACTIVE -> Pair(
                getString(R.string.vpn_notification_title),
                getString(R.string.vpn_notification_text, blockedAppsCount),
            )
            VpnState.RESTARTING -> Pair(
                getString(R.string.vpn_notification_restarting_title),
                getString(R.string.vpn_notification_restarting_text),
            )
            VpnState.INACTIVE -> Pair(
                getString(R.string.vpn_notification_inactive_title),
                getString(R.string.vpn_notification_inactive_text, blockedAppsCount),
            )
        }

        return notificationBuilder
            .setSmallIcon(android.R.drawable.stat_sys_warning)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(openAppIntent)
            .setOngoing(state == VpnState.ACTIVE || state == VpnState.RESTARTING)
            .build()
    }

    companion object {
        private const val TAG = "AppBlockerVpnService"
        const val ACTION_START = "com.app.net_guard.action.START_VPN"
        const val ACTION_STOP = "com.app.net_guard.action.STOP_VPN"
        const val ACTION_UPDATE = "com.app.net_guard.action.UPDATE_BLOCKED_PACKAGES"
        const val ACTION_RESTART = "com.app.net_guard.action.RESTART_VPN"

        const val EXTRA_BLOCKED_PACKAGES = "blocked_packages"

        private const val PREFERENCES_NAME = "app_blocker_vpn"
        private const val BLOCKED_PACKAGES_KEY = "blocked_packages"
        private const val NOTIFICATION_ID = 1001
        private const val NOTIFICATION_CHANNEL_ID = "app_blocker_vpn"
        private const val IPV4_ADDRESS = "10.120.0.2"
        private const val IPV6_ADDRESS = "fd00:120::2"
        private const val MAX_PACKET_SIZE = 32767
        private const val MAX_RETRIES = 3

        @Volatile
        var isServiceRunning = false
            private set

        @Volatile
        var isVpnEstablished = false
            private set

        fun saveBlockedPackages(context: Context, packages: Set<String>) {
            context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
                .edit()
                .putStringSet(BLOCKED_PACKAGES_KEY, packages)
                .commit()
        }

        fun loadBlockedPackages(context: Context): Set<String> =
            context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
                .getStringSet(BLOCKED_PACKAGES_KEY, emptySet())
                ?.toSet()
                ?: emptySet()
    }
}
