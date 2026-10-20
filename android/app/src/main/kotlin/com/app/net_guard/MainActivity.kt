package com.app.net_guard

import android.content.Intent
import android.net.VpnService
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var pendingVpnStart: PendingVpnStart? = null

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
    }

    override fun onDestroy() {
        pendingVpnStart?.result?.error(
            "activity_destroyed",
            "VPN permission request was interrupted.",
            null,
        )
        pendingVpnStart = null
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
            pendingRequest.result.error(
                "vpn_permission_denied",
                "VPN permission was denied. No applications were blocked.",
                null,
            )
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
            else -> result.notImplemented()
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
        if (packages.isEmpty()) {
            stopVpnService()
            result.success(null)
            return
        }
        if (VpnService.prepare(this) != null) {
            requestVpnStart(packages, result)
            return
        }
        startVpnService(packages, AppBlockerVpnService.ACTION_UPDATE)
        result.success(null)
    }

    private fun toggleSinglePackage(call: MethodCall, result: MethodChannel.Result) {
        val packageName = call.argument<String>("packageName")
        val isBlocked = call.argument<Boolean>("isBlocked")
        if (packageName.isNullOrBlank() || isBlocked == null) {
            result.error("invalid_arguments", "packageName and isBlocked are required.", null)
            return
        }
        val updatedPackages = AppBlockerVpnService.loadBlockedPackages(this).toMutableSet()
        if (isBlocked) updatedPackages.add(packageName) else updatedPackages.remove(packageName)

        if (updatedPackages.isEmpty()) {
            stopVpnService()
            result.success(null)
        } else {
            requestVpnStart(updatedPackages, result)
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
        AppBlockerVpnService.saveBlockedPackages(this, emptySet())
        val intent = Intent(this, AppBlockerVpnService::class.java).apply {
            action = AppBlockerVpnService.ACTION_STOP
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        } catch (_: Exception) {
            try {
                startService(intent)
            } catch (_: Exception) {}
        }
        try {
            stopService(Intent(this, AppBlockerVpnService::class.java))
        } catch (_: Exception) {}
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
        private const val VPN_PERMISSION_REQUEST_CODE = 4142
    }
}
