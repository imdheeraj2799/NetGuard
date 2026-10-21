package com.app.net_guard

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            Log.d(TAG, "Boot or package update broadcast received: $action")
            val blockedPackages = AppBlockerVpnService.loadBlockedPackages(context)
            if (blockedPackages.isNotEmpty()) {
                val permissionRevoked = VpnService.prepare(context) != null
                if (!permissionRevoked) {
                    Log.i(TAG, "Restoring VPN service on boot for ${blockedPackages.size} blocked package(s)")
                    val vpnIntent = Intent(context, AppBlockerVpnService::class.java).apply {
                        this.action = AppBlockerVpnService.ACTION_START
                        putStringArrayListExtra(
                            AppBlockerVpnService.EXTRA_BLOCKED_PACKAGES,
                            ArrayList(blockedPackages),
                        )
                    }
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            context.startForegroundService(vpnIntent)
                        } else {
                            context.startService(vpnIntent)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to restore VPN on boot: ${e.message}")
                    }
                } else {
                    Log.w(TAG, "VPN permission revoked; cannot auto-start on boot")
                    VpnStatusMonitor.update(
                        VpnState.INACTIVE,
                        blockedPackages.size,
                        "VPN permission required to restore protection after reboot.",
                    )
                }
            }
        }
    }

    companion object {
        private const val TAG = "BootReceiver"
    }
}
