package com.app.net_guard

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

data class ScheduleTransitions(
    val startedSchedules: List<NativeBlockSchedule>,
    val endedSchedules: List<NativeBlockSchedule>,
    val currentActiveScheduleIds: Set<String>,
)

object ScheduleNotificationManager {
    private const val TAG = "ScheduleNotificationMgr"

    const val CHANNEL_ID_SCHEDULE = "net_guard_schedule_channel"
    const val CHANNEL_ID_FAILURE = "net_guard_firewall_failure_channel"

    private const val NOTIFICATION_ID_BASE_SCHEDULE = 2000
    private const val NOTIFICATION_ID_FAILURE = 3001

    private const val PREFS_NAME = "net_guard_notifications"
    private const val KEY_NOTIFIED_SESSIONS = "notified_sessions"
    private const val KEY_ACTIVE_SCHEDULE_IDS = "active_schedule_ids"
    private const val KEY_FAILURE_NOTIFIED = "failure_notified"

    fun createNotificationChannels(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val scheduleChannel = NotificationChannel(
                CHANNEL_ID_SCHEDULE,
                context.getString(R.string.schedule_notification_channel_name),
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = context.getString(R.string.schedule_notification_channel_description)
                setShowBadge(true)
            }

            val failureChannel = NotificationChannel(
                CHANNEL_ID_FAILURE,
                context.getString(R.string.failure_notification_channel_name),
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = context.getString(R.string.failure_notification_channel_description)
                setShowBadge(true)
            }

            notificationManager.createNotificationChannel(scheduleChannel)
            notificationManager.createNotificationChannel(failureChannel)
        }
    }

    private fun parseMinutes(timeStr: String): Int {
        val parts = timeStr.split(":")
        val hours = parts.getOrNull(0)?.toIntOrNull() ?: 0
        val mins = parts.getOrNull(1)?.toIntOrNull() ?: 0
        return (hours * 60 + mins).coerceIn(0, 1439)
    }

    fun getSessionStartKey(schedule: NativeBlockSchedule, now: Calendar): String {
        val startMinutes = parseMinutes(schedule.startTime)
        val endMinutes = parseMinutes(schedule.endTime)
        val isOvernight = startMinutes > endMinutes
        val currentMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)

        val dateStr = if (schedule.recurrenceType.equals("one_time", ignoreCase = true)) {
            schedule.targetDate ?: SimpleDateFormat("yyyy-MM-dd", Locale.US).format(now.time)
        } else if (isOvernight && currentMinutes < endMinutes) {
            val yesterday = (now.clone() as Calendar).apply { add(Calendar.DAY_OF_MONTH, -1) }
            SimpleDateFormat("yyyy-MM-dd", Locale.US).format(yesterday.time)
        } else {
            SimpleDateFormat("yyyy-MM-dd", Locale.US).format(now.time)
        }
        return "${schedule.id}_start_${dateStr}_${schedule.startTime}"
    }

    fun getSessionEndKey(schedule: NativeBlockSchedule, now: Calendar): String {
        val dateStr = if (schedule.recurrenceType.equals("one_time", ignoreCase = true)) {
            schedule.targetDate ?: SimpleDateFormat("yyyy-MM-dd", Locale.US).format(now.time)
        } else {
            SimpleDateFormat("yyyy-MM-dd", Locale.US).format(now.time)
        }
        return "${schedule.id}_end_${dateStr}_${schedule.endTime}"
    }

    @Synchronized
    fun getPreviouslyActiveScheduleIds(context: Context): Set<String> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getStringSet(KEY_ACTIVE_SCHEDULE_IDS, emptySet())?.toSet() ?: emptySet()
    }

    @Synchronized
    fun saveActiveScheduleIds(context: Context, ids: Set<String>) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putStringSet(KEY_ACTIVE_SCHEDULE_IDS, ids)
            .commit()
    }

    @Synchronized
    fun isSessionNotified(context: Context, sessionKey: String): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val notified = prefs.getStringSet(KEY_NOTIFIED_SESSIONS, emptySet()) ?: emptySet()
        return notified.contains(sessionKey)
    }

    @Synchronized
    fun markSessionNotified(context: Context, sessionKey: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val current = prefs.getStringSet(KEY_NOTIFIED_SESSIONS, emptySet())?.toMutableSet() ?: mutableSetOf()
        current.add(sessionKey)
        // Keep notified sessions bounded
        if (current.size > 100) {
            val trimmed = current.toList().takeLast(80).toSet()
            prefs.edit().putStringSet(KEY_NOTIFIED_SESSIONS, trimmed).commit()
        } else {
            prefs.edit().putStringSet(KEY_NOTIFIED_SESSIONS, current).commit()
        }
    }

    @Synchronized
    fun isFailureNotified(context: Context): Boolean {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getBoolean(KEY_FAILURE_NOTIFIED, false)
    }

    @Synchronized
    fun setFailureNotified(context: Context, notified: Boolean) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_FAILURE_NOTIFIED, notified)
            .commit()
    }

    /**
     * Synchronizes schedule state when schedules are modified, disabled, or deleted.
     * Prevents obsolete alarms or deleted schedules from triggering spurious end notifications.
     */
    @Synchronized
    fun syncSchedules(context: Context, schedules: List<NativeBlockSchedule>) {
        val validEnabledIds = schedules.filter { it.isEnabled }.map { it.id }.toSet()
        val prevActiveIds = getPreviouslyActiveScheduleIds(context)
        val pruned = prevActiveIds.intersect(validEnabledIds)
        if (pruned != prevActiveIds) {
            saveActiveScheduleIds(context, pruned)
        }
    }

    /**
     * Detects schedule transitions between inactive and active states.
     */
    fun detectTransitions(
        context: Context,
        schedules: List<NativeBlockSchedule>,
        now: Calendar,
    ): ScheduleTransitions {
        val prevActiveIds = getPreviouslyActiveScheduleIds(context)
        val startedSchedules = mutableListOf<NativeBlockSchedule>()
        val endedSchedules = mutableListOf<NativeBlockSchedule>()
        val currentActiveIds = mutableSetOf<String>()

        val enabledSchedules = schedules.filter { it.isEnabled }

        for (schedule in enabledSchedules) {
            val isActive = NativeScheduleEngine.isScheduleActive(schedule, now)
            val wasActive = prevActiveIds.contains(schedule.id)

            if (isActive) {
                currentActiveIds.add(schedule.id)
                val startKey = getSessionStartKey(schedule, now)
                if (!wasActive || !isSessionNotified(context, startKey)) {
                    startedSchedules.add(schedule)
                }
            } else if (wasActive) {
                val endKey = getSessionEndKey(schedule, now)
                if (!isSessionNotified(context, endKey)) {
                    endedSchedules.add(schedule)
                }
            }
        }

        return ScheduleTransitions(
            startedSchedules = startedSchedules,
            endedSchedules = endedSchedules,
            currentActiveScheduleIds = currentActiveIds,
        )
    }

    /**
     * Triggered only after firewall rules have been successfully applied or updated in the VPN service.
     */
    @Synchronized
    fun onFirewallRulesEnforced(
        context: Context,
        started: List<NativeBlockSchedule>,
        ended: List<NativeBlockSchedule>,
        effectiveBlockedPackages: Set<String>,
    ) {
        createNotificationChannels(context)
        val now = Calendar.getInstance()

        // 1. Notify started schedules
        for (schedule in started) {
            val sessionKey = getSessionStartKey(schedule, now)
            if (!isSessionNotified(context, sessionKey)) {
                notifyScheduleStarted(context, schedule)
                markSessionNotified(context, sessionKey)
            }
        }

        // 2. Notify ended schedules
        for (schedule in ended) {
            val sessionKey = getSessionEndKey(schedule, now)
            if (!isSessionNotified(context, sessionKey)) {
                val stillBlocked = schedule.selectedPackages.intersect(effectiveBlockedPackages)
                notifyScheduleEnded(context, schedule, stillBlocked.size)
                markSessionNotified(context, sessionKey)
            }
        }

        // 3. Update active IDs tracking
        val allSchedules = NativeScheduleStore.loadSchedules(context)
        val activeIds = mutableSetOf<String>()
        for (s in allSchedules) {
            if (s.isEnabled && NativeScheduleEngine.isScheduleActive(s, now)) {
                activeIds.add(s.id)
            }
        }
        saveActiveScheduleIds(context, activeIds)

        // 4. Clear any existing failure notification since rules are successfully active
        clearFirewallFailure(context)
    }

    private fun notifyScheduleStarted(context: Context, schedule: NativeBlockSchedule) {
        val title = "Schedule Started: ${schedule.name}"
        val message = "Internet access has been blocked for assigned applications in ${schedule.name}."
        val notificationId = NOTIFICATION_ID_BASE_SCHEDULE + (schedule.id.hashCode() and 0x7FFF) % 1000

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "schedule")
            putExtra("schedule_id", schedule.id)
            putExtra("schedule_name", schedule.name)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        val pendingIntent = PendingIntent.getActivity(context, notificationId, intent, flags)

        val notification = NotificationCompat.Builder(context, CHANNEL_ID_SCHEDULE)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setWhen(System.currentTimeMillis())
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        try {
            manager.notify(notificationId, notification)
            Log.i(TAG, "Notified schedule started: ${schedule.name}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to display schedule start notification: ${e.message}")
        }
    }

    private fun notifyScheduleEnded(context: Context, schedule: NativeBlockSchedule, stillBlockedCount: Int) {
        val title = "Schedule Ended: ${schedule.name}"
        val message = if (stillBlockedCount > 0) {
            "Scheduled blocking ended for ${schedule.name}, but $stillBlockedCount application(s) remain blocked by other rules."
        } else {
            "Scheduled blocking period for ${schedule.name} has ended. Internet access restored for assigned applications."
        }
        val notificationId = NOTIFICATION_ID_BASE_SCHEDULE + (schedule.id.hashCode() and 0x7FFF) % 1000

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "schedule")
            putExtra("schedule_id", schedule.id)
            putExtra("schedule_name", schedule.name)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        val pendingIntent = PendingIntent.getActivity(context, notificationId, intent, flags)

        val notification = NotificationCompat.Builder(context, CHANNEL_ID_SCHEDULE)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setWhen(System.currentTimeMillis())
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        try {
            manager.notify(notificationId, notification)
            Log.i(TAG, "Notified schedule ended: ${schedule.name}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to display schedule end notification: ${e.message}")
        }
    }

    @Synchronized
    fun notifyFirewallFailure(context: Context, reason: String) {
        if (isFailureNotified(context)) {
            Log.d(TAG, "Firewall failure already notified; skipping duplicate alert")
            return
        }

        createNotificationChannels(context)
        val title = "Firewall Protection Inactive"
        val message = "$reason Tap to restore protection."

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "dashboard")
            putExtra("action", "restore_protection")
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        val pendingIntent = PendingIntent.getActivity(context, NOTIFICATION_ID_FAILURE, intent, flags)

        val notification = NotificationCompat.Builder(context, CHANNEL_ID_FAILURE)
            .setSmallIcon(android.R.drawable.stat_notify_error)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setWhen(System.currentTimeMillis())
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        try {
            manager.notify(NOTIFICATION_ID_FAILURE, notification)
            setFailureNotified(context, true)
            Log.w(TAG, "Notified firewall failure: $reason")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to display firewall failure notification: ${e.message}")
        }
    }

    @Synchronized
    fun clearFirewallFailure(context: Context) {
        if (isFailureNotified(context)) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            try {
                manager.cancel(NOTIFICATION_ID_FAILURE)
            } catch (_: Exception) {}
            setFailureNotified(context, false)
            Log.i(TAG, "Cleared firewall failure notification")
        }
    }
}
