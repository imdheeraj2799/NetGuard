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
            try {
                // Reconcile manual and scheduled firewall rules, and arm upcoming transition alarms
                ScheduleAlarmManager.reconcileAndApply(context)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to reconcile schedules on boot: ${e.message}")
            }
        }
    }

    companion object {
        private const val TAG = "BootReceiver"
    }
}
