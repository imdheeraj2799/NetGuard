package com.app.net_guard

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
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

    @Volatile
    private var isDraining = false

    @Volatile
    private var currentBlockedPackages: Set<String> = emptySet()

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                try {
                    startForeground(NOTIFICATION_ID, createNotification(0))
                } catch (_: Exception) {
                }
                stopVpn()
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_START, ACTION_UPDATE, null -> {
                val blockedPackages = intent?.getStringArrayListExtra(EXTRA_BLOCKED_PACKAGES)?.toSet()
                    ?: loadBlockedPackages(this)

                currentBlockedPackages = blockedPackages

                if (blockedPackages.isEmpty()) {
                    try {
                        startForeground(NOTIFICATION_ID, createNotification(0))
                    } catch (_: Exception) {
                    }
                    stopVpn()
                    stopSelf()
                    return START_NOT_STICKY
                }

                saveBlockedPackages(this, blockedPackages)
                try {
                    startForeground(NOTIFICATION_ID, createNotification(blockedPackages.size))
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start foreground notification: ${e.message}")
                }
                try {
                    configureVpn(blockedPackages)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to configure VPN: ${e.message}")
                }
            }
        }
        return START_STICKY
    }

    override fun onRevoke() {
        saveBlockedPackages(this, emptySet())
        stopVpn()
        stopSelf()
        super.onRevoke()
    }

    override fun onDestroy() {
        stopVpn()
        packetExecutor.shutdownNow()
        super.onDestroy()
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
            Log.e(TAG, "Failed to establish VPN interface: ${e.message}")
            null
        }

        if (newDescriptor == null) {
            Log.e(TAG, "builder.establish() returned null")
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

    private fun createNotification(blockedAppsCount: Int): Notification {
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

        return notificationBuilder
            .setSmallIcon(android.R.drawable.stat_sys_warning)
            .setContentTitle(getString(R.string.vpn_notification_title))
            .setContentText(getString(R.string.vpn_notification_text, blockedAppsCount))
            .setContentIntent(openAppIntent)
            .setOngoing(true)
            .build()
    }

    companion object {
        private const val TAG = "AppBlockerVpnService"
        const val ACTION_START = "com.app.net_guard.action.START_VPN"
        const val ACTION_STOP = "com.app.net_guard.action.STOP_VPN"
        const val ACTION_UPDATE = "com.app.net_guard.action.UPDATE_BLOCKED_PACKAGES"

        const val EXTRA_BLOCKED_PACKAGES = "blocked_packages"

        private const val PREFERENCES_NAME = "app_blocker_vpn"
        private const val BLOCKED_PACKAGES_KEY = "blocked_packages"
        private const val NOTIFICATION_ID = 1001
        private const val NOTIFICATION_CHANNEL_ID = "app_blocker_vpn"
        private const val IPV4_ADDRESS = "10.120.0.2"
        private const val IPV6_ADDRESS = "fd00:120::2"
        private const val MAX_PACKET_SIZE = 32767

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
