package com.app.net_guard

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.util.Log
import java.util.Calendar

object ScheduleAlarmManager {
    private const val TAG = "ScheduleAlarmManager"
    private const val ALARM_REQUEST_CODE = 4001

    fun canScheduleExactAlarms(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            alarmManager?.canScheduleExactAlarms() ?: true
        } else {
            true
        }
    }

    fun armNextAlarm(context: Context, schedules: List<NativeBlockSchedule>) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val now = Calendar.getInstance()
        val nextTransitionMillis = NativeScheduleEngine.getEarliestNextTransitionMillis(schedules, now)

        val intent = Intent(context, ScheduleAlarmReceiver::class.java).apply {
            action = ScheduleAlarmReceiver.ACTION_SCHEDULE_TRANSITION
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        val pendingIntent = PendingIntent.getBroadcast(context, ALARM_REQUEST_CODE, intent, flags)

        if (nextTransitionMillis != null) {
            Log.i(TAG, "Arming next schedule alarm at millis: $nextTransitionMillis (in ${(nextTransitionMillis - now.timeInMillis) / 1000}s)")
            try {
                if (canScheduleExactAlarms(context)) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        nextTransitionMillis,
                        pendingIntent,
                    )
                } else {
                    // Fallback using setAlarmClock which does not require SCHEDULE_EXACT_ALARM on some API versions
                    val showIntent = Intent(context, MainActivity::class.java)
                    val showPendingIntent = PendingIntent.getActivity(context, 0, showIntent, flags)
                    val clockInfo = AlarmManager.AlarmClockInfo(nextTransitionMillis, showPendingIntent)
                    alarmManager.setAlarmClock(clockInfo, pendingIntent)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to schedule exact alarm: ${e.message}")
            }
        } else {
            Log.d(TAG, "No upcoming schedule transitions; cancelling alarm")
            alarmManager.cancel(pendingIntent)
        }
    }

    fun cancelAlarm(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val intent = Intent(context, ScheduleAlarmReceiver::class.java).apply {
            action = ScheduleAlarmReceiver.ACTION_SCHEDULE_TRANSITION
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        val pendingIntent = PendingIntent.getBroadcast(context, ALARM_REQUEST_CODE, intent, flags)
        alarmManager.cancel(pendingIntent)
    }

    @Synchronized
    fun reconcileAndApply(context: Context): Set<String> {
        val now = Calendar.getInstance()
        val schedules = NativeScheduleStore.loadSchedules(context)
        val manualPackages = NativeScheduleStore.loadManualBlockedPackages(context)
        val activeSchedulePackages = NativeScheduleEngine.computeActiveSchedulePackages(schedules, now)

        val effectivePackages = (manualPackages + activeSchedulePackages).toSet()
        Log.i(TAG, "Reconciling firewall: manual=${manualPackages.size}, scheduled=${activeSchedulePackages.size}, effective=${effectivePackages.size}")

        // Prune deleted or disabled schedules from notification active tracking
        ScheduleNotificationManager.syncSchedules(context, schedules)

        // Detect transitions for enabled schedules
        val transitions = ScheduleNotificationManager.detectTransitions(context, schedules, now)

        AppBlockerVpnService.saveBlockedPackages(context, effectivePackages)

        if (effectivePackages.isEmpty()) {
            if (AppBlockerVpnService.isServiceRunning) {
                val intent = Intent(context, AppBlockerVpnService::class.java).apply {
                    action = AppBlockerVpnService.ACTION_STOP
                    putStringArrayListExtra(
                        AppBlockerVpnService.EXTRA_PENDING_ENDED_SCHEDULES,
                        ArrayList(transitions.endedSchedules.map { it.id }),
                    )
                }
                try {
                    context.startService(intent)
                } catch (_: Exception) {}
            } else {
                // VPN is not running, so rules are already effectively cleared
                ScheduleNotificationManager.onFirewallRulesEnforced(
                    context,
                    started = emptyList(),
                    ended = transitions.endedSchedules,
                    effectiveBlockedPackages = emptySet(),
                )
            }
        } else {
            val permissionRevoked = VpnService.prepare(context) != null
            if (!permissionRevoked) {
                val action = if (AppBlockerVpnService.isServiceRunning) {
                    AppBlockerVpnService.ACTION_UPDATE
                } else {
                    AppBlockerVpnService.ACTION_START
                }
                val intent = Intent(context, AppBlockerVpnService::class.java).apply {
                    this.action = action
                    putStringArrayListExtra(
                        AppBlockerVpnService.EXTRA_BLOCKED_PACKAGES,
                        ArrayList(effectivePackages),
                    )
                    putStringArrayListExtra(
                        AppBlockerVpnService.EXTRA_PENDING_STARTED_SCHEDULES,
                        ArrayList(transitions.startedSchedules.map { it.id }),
                    )
                    putStringArrayListExtra(
                        AppBlockerVpnService.EXTRA_PENDING_ENDED_SCHEDULES,
                        ArrayList(transitions.endedSchedules.map { it.id }),
                    )
                }
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(intent)
                    } else {
                        context.startService(intent)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start/update VPN service from schedule engine: ${e.message}")
                    ScheduleNotificationManager.notifyFirewallFailure(
                        context,
                        "Failed to start firewall service. Internet-blocking protection may be inactive.",
                    )
                }
            } else {
                Log.w(TAG, "VPN permission not granted; cannot apply effective schedule packages")
                VpnStatusMonitor.update(
                    VpnState.INACTIVE,
                    effectivePackages.size,
                    "VPN permission required to enforce scheduled firewall rules.",
                )
                ScheduleNotificationManager.notifyFirewallFailure(
                    context,
                    "VPN permission required to enforce scheduled firewall rules. Protection is inactive.",
                )
            }
        }

        // Arm the next alarm for upcoming transitions
        armNextAlarm(context, schedules)
        return effectivePackages
    }
}
