package com.app.net_guard
import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.net.VpnService
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var pendingVpnStart: PendingVpnStart? = null
    private var pendingNotificationPermissionResult: MethodChannel.Result? = null
    private var initialNotificationPayload: Map<String, Any?>? = null
    private val vpnStatusListeners = mutableListOf<EventChannel.EventSink>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntentExtras(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntentExtras(intent)
    }

    private fun handleIntentExtras(intent: Intent?) {
        val route = intent?.getStringExtra("route")
        if (!route.isNullOrBlank()) {
            initialNotificationPayload = mapOf(
                "route" to route,
                "schedule_id" to intent.getStringExtra("schedule_id"),
                "schedule_name" to intent.getStringExtra("schedule_name"),
                "action" to intent.getStringExtra("action"),
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val trafficHandler: (MethodCall, MethodChannel.Result) -> Unit = { call, result ->
            handleTrafficMethodCall(call, result)
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            TRAFFIC_CHANNEL,
        ).setMethodCallHandler(trafficHandler)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LEGACY_TRAFFIC_CHANNEL,
        ).setMethodCallHandler(trafficHandler)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            VPN_STATUS_CHANNEL,
        ).setStreamHandler(createStatusStreamHandler())

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LEGACY_VPN_STATUS_CHANNEL,
        ).setStreamHandler(createStatusStreamHandler())
    }

    private fun createStatusStreamHandler(): EventChannel.StreamHandler {
        return object : EventChannel.StreamHandler {
            private var sink: EventChannel.EventSink? = null
            private var monitorListener: ((VpnStatusData) -> Unit)? = null

            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                val s = events ?: return
                sink = s
                synchronized(vpnStatusListeners) {
                    vpnStatusListeners.add(s)
                }
                val current = VpnStatusMonitor.getCurrentStatus(this@MainActivity)
                s.success(current.toMap())

                val listener: (VpnStatusData) -> Unit = { data ->
                    runOnUiThread {
                        try {
                            sink?.success(data.toMap())
                        } catch (_: Exception) {}
                    }
                }
                monitorListener = listener
                VpnStatusMonitor.addListener(listener)
            }

            override fun onCancel(arguments: Any?) {
                monitorListener?.let { VpnStatusMonitor.removeListener(it) }
                monitorListener = null
                sink?.let { s ->
                    synchronized(vpnStatusListeners) {
                        vpnStatusListeners.remove(s)
                    }
                }
                sink = null
            }
        }
    }

    override fun onDestroy() {
        pendingVpnStart?.result?.error(
            "activity_destroyed",
            "VPN permission request was interrupted.",
            null,
        )
        pendingVpnStart = null
        pendingNotificationPermissionResult?.error(
            "activity_destroyed",
            "Notification permission request was interrupted.",
            null,
        )
        pendingNotificationPermissionResult = null
        vpnStatusListeners.clear()
        super.onDestroy()
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != VPN_PERMISSION_REQUEST_CODE) return

        val pendingRequest = pendingVpnStart ?: return
        pendingVpnStart = null
        if (resultCode == RESULT_OK) {
            try {
                startVpnService(pendingRequest.blockedPackages, AppBlockerVpnService.ACTION_START)
                pendingRequest.result.success(null)
            } catch (e: Exception) {
                pendingRequest.result.error(
                    "vpn_start_error",
                    "Failed to start VPN service: ${e.message}",
                    null,
                )
            }
        } else {
            VpnStatusMonitor.update(
                VpnState.INACTIVE,
                pendingRequest.blockedPackages.size,
                "VPN permission was denied. Applications are unprotected.",
            )
            pendingRequest.result.error(
                "vpn_permission_denied",
                "VPN permission was denied. No applications were blocked.",
                null,
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == NOTIFICATION_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingNotificationPermissionResult?.success(granted)
            pendingNotificationPermissionResult = null
        }
    }

    private fun handleTrafficMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startVpnService" -> requestVpnStart(blockedPackages(call), result)
            "stopVpnService" -> {
                stopVpnService()
                result.success(null)
            }
            "updateBlockedList" -> updateBlockedList(blockedPackages(call), result)
            "toggleBlockStatus" -> toggleSinglePackage(call, result)
            "isVpnPermissionGranted" -> {
                val prepared = VpnService.prepare(this) == null
                result.success(prepared)
            }
            "requestVpnPermission" -> {
                val permissionIntent = VpnService.prepare(this)
                if (permissionIntent == null) {
                    result.success(true)
                } else {
                    if (pendingVpnStart != null) {
                        result.error("vpn_permission_pending", "A VPN permission request is already open.", null)
                        return
                    }
                    val currentPackages = AppBlockerVpnService.loadBlockedPackages(this)
                    pendingVpnStart = PendingVpnStart(currentPackages, result)
                    startActivityForResult(permissionIntent, VPN_PERMISSION_REQUEST_CODE)
                }
            }
            "getVpnStatus" -> {
                val status = VpnStatusMonitor.getCurrentStatus(this)
                result.success(status.toMap())
            }
            "restartVpn" -> {
                restartVpn(result)
            }
            "syncSchedules" -> {
                val json = when (val arg = call.arguments) {
                    is String -> arg
                    is Map<*, *> -> arg["schedules"] as? String
                    else -> null
                }
                if (!json.isNullOrBlank()) {
                    NativeScheduleStore.saveSchedulesJson(this, json)
                }
                try {
                    ScheduleAlarmManager.reconcileAndApply(this)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("schedule_sync_error", "Failed to sync schedules: ${e.message}", null)
                }
            }
            "canScheduleExactAlarms" -> {
                result.success(ScheduleAlarmManager.canScheduleExactAlarms(this))
            }
            "requestExactAlarmPermission" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                        data = Uri.parse("package:$packageName")
                    }
                    try {
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("permission_error", "Failed to open exact alarm settings: ${e.message}", null)
                    }
                } else {
                    result.success(true)
                }
            }
            "areNotificationsEnabled" -> {
                val enabled = NotificationManagerCompat.from(this).areNotificationsEnabled()
                result.success(enabled)
            }
            "requestNotificationPermission" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
                        result.success(true)
                    } else {
                        if (pendingNotificationPermissionResult != null) {
                            result.error("permission_pending", "A notification permission request is already in progress.", null)
                            return
                        }
                        pendingNotificationPermissionResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                            NOTIFICATION_PERMISSION_REQUEST_CODE,
                        )
                    }
                } else {
                    val enabled = NotificationManagerCompat.from(this).areNotificationsEnabled()
                    result.success(enabled)
                }
            }
            "getInitialNotificationPayload" -> {
                val payload = initialNotificationPayload
                initialNotificationPayload = null
                result.success(payload)
            }
            "syncTemporaryPauses" -> {
                val pausesJson = call.argument<String>("pauses")
                if (pausesJson != null) {
                    NativeTemporaryPauseStore.savePausesJson(this, pausesJson)
                    try {
                        ScheduleAlarmManager.reconcileAndApply(this)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("pause_sync_error", "Failed to sync temporary pauses: ${e.message}", null)
                    }
                } else {
                    result.error("invalid_arguments", "pauses argument is required.", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun restartVpn(result: MethodChannel.Result) {
        val packages = AppBlockerVpnService.loadBlockedPackages(this)
        if (packages.isEmpty()) {
            result.success(null)
            return
        }

        val permissionIntent = VpnService.prepare(this)
        if (permissionIntent != null) {
            if (pendingVpnStart != null) {
                result.error("vpn_permission_pending", "A VPN permission request is already open.", null)
                return
            }
            pendingVpnStart = PendingVpnStart(packages, result)
            startActivityForResult(permissionIntent, VPN_PERMISSION_REQUEST_CODE)
            return
        }

        try {
            startVpnService(packages, AppBlockerVpnService.ACTION_RESTART)
            result.success(null)
        } catch (e: Exception) {
            result.error("vpn_restart_error", "Failed to restart VPN service: ${e.message}", null)
        }
    }

    private fun requestVpnStart(
        packages: Set<String>,
        result: MethodChannel.Result,
    ) {
        if (packages.isEmpty()) {
            stopVpnService()
            result.success(null)
            return
        }
        val permissionIntent = VpnService.prepare(this)
        if (permissionIntent == null) {
            startVpnService(packages, AppBlockerVpnService.ACTION_START)
            result.success(null)
            return
        }
        if (pendingVpnStart != null) {
            result.error("vpn_permission_pending", "A VPN permission request is already open.", null)
            return
        }
        pendingVpnStart = PendingVpnStart(packages, result)
        startActivityForResult(permissionIntent, VPN_PERMISSION_REQUEST_CODE)
    }

    private fun updateBlockedList(
        packages: Set<String>,
        result: MethodChannel.Result,
    ) {
        NativeScheduleStore.saveManualBlockedPackages(this, packages)
        try {
            ScheduleAlarmManager.reconcileAndApply(this)
            result.success(null)
        } catch (e: Exception) {
            result.error("vpn_update_error", "Failed to update blocked list: ${e.message}", null)
        }
    }

    private fun toggleSinglePackage(call: MethodCall, result: MethodChannel.Result) {
        val packageName = call.argument<String>("packageName")
        val isBlocked = call.argument<Boolean>("isBlocked")
        if (packageName.isNullOrBlank() || isBlocked == null) {
            result.error("invalid_arguments", "packageName and isBlocked are required.", null)
            return
        }
        val currentManual = NativeScheduleStore.loadManualBlockedPackages(this).toMutableSet()
        if (isBlocked) currentManual.add(packageName) else currentManual.remove(packageName)
        NativeScheduleStore.saveManualBlockedPackages(this, currentManual)
        try {
            ScheduleAlarmManager.reconcileAndApply(this)
            result.success(null)
        } catch (e: Exception) {
            result.error("vpn_update_error", "Failed to toggle package: ${e.message}", null)
        }
    }

    private fun startVpnService(packages: Set<String>, action: String) {
        val intent = Intent(this, AppBlockerVpnService::class.java)
            .setAction(action)
            .putStringArrayListExtra(
                AppBlockerVpnService.EXTRA_BLOCKED_PACKAGES,
                ArrayList(packages),
            )
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to start VPN service: ${e.message}")
        }
    }

    private fun stopVpnService() {
        // NOTE: Do NOT wipe NativeScheduleStore.manualBlockedPackages here.
        // updateBlockedList already persists the correct manual packages when the user
        // manually unblocks all apps. Wiping here would corrupt the manual rules when
        // stopVpnService is called from schedule sync code.
        AppBlockerVpnService.saveBlockedPackages(this, emptySet())
        VpnStatusMonitor.update(VpnState.INACTIVE, 0, null)
        if (AppBlockerVpnService.isServiceRunning) {
            val intent = Intent(this, AppBlockerVpnService::class.java).apply {
                action = AppBlockerVpnService.ACTION_STOP
            }
            try {
                // ACTION_STOP does not require foreground service start — use startService.
                startService(intent)
            } catch (_: Exception) {}
        } else {
            try {
                stopService(Intent(this, AppBlockerVpnService::class.java))
            } catch (_: Exception) {}
        }
    }

    private fun blockedPackages(call: MethodCall): Set<String> =
        (when (val arguments = call.arguments) {
            is List<*> -> arguments
            is Map<*, *> -> arguments["blockedPackages"] as? List<*>
            else -> null
        })
            ?.filterIsInstance<String>()
            ?.filter { it.isNotBlank() }
            ?.toSet()
            ?: emptySet()

    private data class PendingVpnStart(
        val blockedPackages: Set<String>,
        val result: MethodChannel.Result,
    )

    companion object {
        private const val TRAFFIC_CHANNEL = "com.app.net_guard/traffic"
        private const val LEGACY_TRAFFIC_CHANNEL = "com.example.blocker/traffic"
        private const val VPN_STATUS_CHANNEL = "com.app.net_guard/vpn_status"
        private const val LEGACY_VPN_STATUS_CHANNEL = "com.example.blocker/vpn_status"
        private const val VPN_PERMISSION_REQUEST_CODE = 4142
        private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 4143
    }
}
