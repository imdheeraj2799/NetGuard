package com.app.net_guard

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class TimeChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action == Intent.ACTION_TIME_CHANGED ||
            action == Intent.ACTION_TIMEZONE_CHANGED ||
            action == Intent.ACTION_DATE_CHANGED
        ) {
            Log.i(TAG, "Time or timezone altered ($action), re-evaluating schedules and alarms")
            try {
                ScheduleAlarmManager.reconcileAndApply(context)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to reconcile schedules on time change: ${e.message}")
            }
        }
    }

    companion object {
        private const val TAG = "TimeChangeReceiver"
    }
}
