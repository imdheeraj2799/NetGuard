package com.app.net_guard

import android.app.AppOpsManager
import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.ConnectivityManager
import android.net.Uri
import android.net.VpnService
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterFragmentActivity() {
    private var pendingVpnStart: PendingVpnStart? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Traffic channels (supports new com.app.net_guard and legacy com.example.blocker)
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

        // DNS Filter channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DNS_FILTER_CHANNEL,
        ).setMethodCallHandler { call, result ->
            handleDnsMethodCall(call, result)
        }

        // Analytics channels
        val analyticsHandler: (MethodCall, MethodChannel.Result) -> Unit = { call, result ->
            handleAnalyticsMethodCall(call, result)
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ANALYTICS_CHANNEL,
        ).setMethodCallHandler(analyticsHandler)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LEGACY_ANALYTICS_CHANNEL,
        ).setMethodCallHandler(analyticsHandler)
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
            else -> result.notImplemented()
        }
    }

    private fun handleDnsMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "updateDnsBlacklist" -> {
                val domains = extractDomains(call)
                updateDnsBlacklist(domains, result)
            }
            "setCustomDnsResolver" -> {
                val dnsServer = call.argument<String>("dnsServer") ?: "1.1.1.1"
                setCustomDnsResolver(dnsServer, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun setCustomDnsResolver(dnsServer: String, result: MethodChannel.Result) {
        AppBlockerVpnService.saveCustomDnsServer(this, dnsServer)
        val currentPackages = AppBlockerVpnService.loadBlockedPackages(this)
        val currentBlacklist = AppBlockerVpnService.loadDnsBlacklist(this)
        if (currentPackages.isNotEmpty() || currentBlacklist.isNotEmpty()) {
            if (VpnService.prepare(this) == null) {
                val intent = Intent(this, AppBlockerVpnService::class.java)
                    .setAction(AppBlockerVpnService.ACTION_UPDATE_CUSTOM_DNS)
                    .putExtra(AppBlockerVpnService.EXTRA_CUSTOM_DNS, dnsServer)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(intent)
                } else {
                    startService(intent)
                }
            }
        }
        result.success(null)
    }

    private fun requestVpnStart(
        packages: Set<String>,
        result: MethodChannel.Result,
    ) {
        val currentBlacklist = AppBlockerVpnService.loadDnsBlacklist(this)
        if (packages.isEmpty() && currentBlacklist.isEmpty()) {
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
        val currentBlacklist = AppBlockerVpnService.loadDnsBlacklist(this)
        if (packages.isEmpty() && currentBlacklist.isEmpty()) {
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

    private fun updateDnsBlacklist(
        domains: Set<String>,
        result: MethodChannel.Result,
    ) {
        AppBlockerVpnService.saveDnsBlacklist(this, domains)
        val currentPackages = AppBlockerVpnService.loadBlockedPackages(this)

        if (domains.isEmpty() && currentPackages.isEmpty()) {
            stopVpnService()
            result.success(null)
            return
        }

        if (VpnService.prepare(this) == null) {
            val intent = Intent(this, AppBlockerVpnService::class.java)
                .setAction(AppBlockerVpnService.ACTION_UPDATE_DNS_BLACKLIST)
                .putStringArrayListExtra(
                    AppBlockerVpnService.EXTRA_DNS_BLACKLIST,
                    ArrayList(domains),
                )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        }
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
        val currentBlacklist = AppBlockerVpnService.loadDnsBlacklist(this)

        if (updatedPackages.isEmpty() && currentBlacklist.isEmpty()) {
            stopVpnService()
            result.success(null)
        } else {
            requestVpnStart(updatedPackages, result)
        }
    }

    private fun startVpnService(packages: Set<String>, action: String) {
        val blacklist = AppBlockerVpnService.loadDnsBlacklist(this)
        val intent = Intent(this, AppBlockerVpnService::class.java)
            .setAction(action)
            .putStringArrayListExtra(
                AppBlockerVpnService.EXTRA_BLOCKED_PACKAGES,
                ArrayList(packages),
            )
            .putStringArrayListExtra(
                AppBlockerVpnService.EXTRA_DNS_BLACKLIST,
                ArrayList(blacklist),
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
        AppBlockerVpnService.saveDnsBlacklist(this, emptySet())
        try {
            stopService(Intent(this, AppBlockerVpnService::class.java))
        } catch (_: Exception) {
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

    private fun extractDomains(call: MethodCall): Set<String> =
        (when (val arguments = call.arguments) {
            is List<*> -> arguments
            is Map<*, *> -> arguments["domains"] as? List<*>
            else -> null
        })
            ?.filterIsInstance<String>()
            ?.filter { it.isNotBlank() }
            ?.toSet()
            ?: emptySet()

    private fun handleAnalyticsMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkUsagePermission" -> {
                result.success(checkUsagePermission())
            }
            "requestUsagePermission" -> {
                requestUsagePermission()
                result.success(null)
            }
            "getAppUsageAnalytics" -> {
                if (!checkUsagePermission()) {
                    result.error("permission_denied", "PACKAGE_USAGE_STATS permission is not granted", null)
                    return
                }
                val timeRange = call.argument<String>("timeRange") ?: "week"
                try {
                    val data = getAppUsageAnalyticsData(timeRange)
                    result.success(data)
                } catch (e: Exception) {
                    result.error("analytics_error", "Failed to retrieve analytics: ${e.message}", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun checkUsagePermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager ?: return false
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsagePermission() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
            data = Uri.parse("package:$packageName")
        }
        try {
            startActivity(intent)
        } catch (_: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                })
            } catch (_: Exception) {}
        }
    }

    private fun getAppUsageAnalyticsData(timeRange: String): Map<String, Any> {
        val now = System.currentTimeMillis()
        val calendar = Calendar.getInstance()

        val startTime = when (timeRange.lowercase()) {
            "day" -> {
                calendar.set(Calendar.HOUR_OF_DAY, 0)
                calendar.set(Calendar.MINUTE, 0)
                calendar.set(Calendar.SECOND, 0)
                calendar.set(Calendar.MILLISECOND, 0)
                calendar.timeInMillis
            }
            "month" -> {
                calendar.add(Calendar.DAY_OF_YEAR, -30)
                calendar.set(Calendar.HOUR_OF_DAY, 0)
                calendar.set(Calendar.MINUTE, 0)
                calendar.set(Calendar.SECOND, 0)
                calendar.set(Calendar.MILLISECOND, 0)
                calendar.timeInMillis
            }
            else -> { // "week"
                calendar.add(Calendar.DAY_OF_YEAR, -6)
                calendar.set(Calendar.HOUR_OF_DAY, 0)
                calendar.set(Calendar.MINUTE, 0)
                calendar.set(Calendar.SECOND, 0)
                calendar.set(Calendar.MILLISECOND, 0)
                calendar.timeInMillis
            }
        }

        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
        val stats = usageStatsManager?.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            now,
        ) ?: emptyList()

        val screenTimeByPackage = mutableMapOf<String, Long>()
        for (stat in stats) {
            val prev = screenTimeByPackage[stat.packageName] ?: 0L
            screenTimeByPackage[stat.packageName] = prev + stat.totalTimeInForeground
        }

        val dailyBuckets = mutableListOf<Long>()
        val dayLabels = mutableListOf<String>()
        val dayOfWeekChars = arrayOf("S", "M", "T", "W", "T", "F", "S")
        for (i in 6 downTo 0) {
            val dayCal = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, -i)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val dStart = dayCal.timeInMillis
            val dEnd = dStart + 86400000L
            val dayStats = usageStatsManager?.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                dStart,
                dEnd,
            ) ?: emptyList()
            var dayTotalMs = 0L
            for (st in dayStats) {
                dayTotalMs += st.totalTimeInForeground
            }
            dailyBuckets.add(dayTotalMs / 1000L)
            val dayOfWeek = dayCal.get(Calendar.DAY_OF_WEEK)
            dayLabels.add(dayOfWeekChars[dayOfWeek - 1])
        }

        val networkStatsManager = getSystemService(Context.NETWORK_STATS_SERVICE) as? NetworkStatsManager
        val pm = packageManager

        var totalScreenTimeSec = 0L
        var totalWifiBytes = 0L
        var totalMobileBytes = 0L
        val appUsageList = mutableListOf<Map<String, Any>>()

        val packagesToInspect = screenTimeByPackage.keys.toMutableSet()

        for (pkg in packagesToInspect) {
            val timeMs = screenTimeByPackage[pkg] ?: 0L
            val timeSec = timeMs / 1000L
            var wifiBytes = 0L
            var mobileBytes = 0L

            var appName = pkg
            try {
                val appInfo = pm.getApplicationInfo(pkg, 0)
                appName = pm.getApplicationLabel(appInfo).toString()
                val uid = appInfo.uid

                if (networkStatsManager != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && uid > 0) {
                    try {
                        val wifiDetails = networkStatsManager.queryDetailsForUid(
                            ConnectivityManager.TYPE_WIFI,
                            null,
                            startTime,
                            now,
                            uid,
                        )
                        val bucket = NetworkStats.Bucket()
                        while (wifiDetails.hasNextBucket()) {
                            wifiDetails.getNextBucket(bucket)
                            wifiBytes += (bucket.rxBytes + bucket.txBytes)
                        }
                        wifiDetails.close()
                    } catch (_: Exception) {}

                    try {
                        val mobileDetails = networkStatsManager.queryDetailsForUid(
                            ConnectivityManager.TYPE_MOBILE,
                            null,
                            startTime,
                            now,
                            uid,
                        )
                        val bucket = NetworkStats.Bucket()
                        while (mobileDetails.hasNextBucket()) {
                            mobileDetails.getNextBucket(bucket)
                            mobileBytes += (bucket.rxBytes + bucket.txBytes)
                        }
                        mobileDetails.close()
                    } catch (_: Exception) {}
                }
            } catch (_: Exception) {}

            if (timeSec > 0 || (wifiBytes + mobileBytes) > 0) {
                totalScreenTimeSec += timeSec
                totalWifiBytes += wifiBytes
                totalMobileBytes += mobileBytes

                appUsageList.add(
                    mapOf(
                        "packageName" to pkg,
                        "appName" to appName,
                        "screenTimeSeconds" to timeSec,
                        "wifiDataBytes" to wifiBytes,
                        "mobileDataBytes" to mobileBytes,
                        "timestampRange" to timeRange,
                    ),
                )
            }
        }

        appUsageList.sortWith(
            compareByDescending<Map<String, Any>> { (it["screenTimeSeconds"] as? Long) ?: 0L }
                .thenByDescending {
                    ((it["wifiDataBytes"] as? Long) ?: 0L) + ((it["mobileDataBytes"] as? Long) ?: 0L)
                },
        )

        return mapOf(
            "appUsages" to appUsageList,
            "dailyScreenTimeSeconds" to dailyBuckets,
            "dailyLabels" to dayLabels,
            "totalScreenTimeSeconds" to totalScreenTimeSec,
            "totalDataBytes" to (totalWifiBytes + totalMobileBytes),
            "wifiDataBytes" to totalWifiBytes,
            "mobileDataBytes" to totalMobileBytes,
        )
    }

    private data class PendingVpnStart(
        val blockedPackages: Set<String>,
        val result: MethodChannel.Result,
    )

    companion object {
        private const val TRAFFIC_CHANNEL = "com.app.net_guard/traffic"
        private const val LEGACY_TRAFFIC_CHANNEL = "com.example.blocker/traffic"
        private const val DNS_FILTER_CHANNEL = "com.app.net_guard/dns_filter"
        private const val ANALYTICS_CHANNEL = "com.app.net_guard/analytics"
        private const val LEGACY_ANALYTICS_CHANNEL = "com.example.blocker/analytics"
        private const val VPN_PERMISSION_REQUEST_CODE = 4142
    }
}
