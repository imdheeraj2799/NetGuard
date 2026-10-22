package com.app.net_guard

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class ScheduleAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        Log.i(TAG, "Schedule alarm received: ${intent?.action}")
        try {
            val effectivePackages = ScheduleAlarmManager.reconcileAndApply(context)
            Log.i(TAG, "Schedule transition applied. Total effective blocked packages: ${effectivePackages.size}")
        } catch (e: Exception) {
            Log.e(TAG, "Error in ScheduleAlarmReceiver: ${e.message}", e)
        }
    }

    companion object {
        private const val TAG = "ScheduleAlarmReceiver"
        const val ACTION_SCHEDULE_TRANSITION = "com.app.net_guard.action.SCHEDULE_TRANSITION"
    }
}
