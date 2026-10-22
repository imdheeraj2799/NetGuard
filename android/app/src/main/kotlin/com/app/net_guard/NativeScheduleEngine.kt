package com.app.net_guard

import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

object NativeScheduleEngine {

    fun calendarDayToIso(calendarDay: Int): Int = when (calendarDay) {
        Calendar.MONDAY -> 1
        Calendar.TUESDAY -> 2
        Calendar.WEDNESDAY -> 3
        Calendar.THURSDAY -> 4
        Calendar.FRIDAY -> 5
        Calendar.SATURDAY -> 6
        Calendar.SUNDAY -> 7
        else -> 1
    }

    fun previousIsoDay(isoDay: Int): Int = if (isoDay == 1) 7 else isoDay - 1

    private fun parseMinutes(timeStr: String): Int {
        val parts = timeStr.split(":")
        val hours = parts.getOrNull(0)?.toIntOrNull() ?: 0
        val mins = parts.getOrNull(1)?.toIntOrNull() ?: 0
        return (hours * 60 + mins).coerceIn(0, 1439)
    }

    fun isScheduleActive(schedule: NativeBlockSchedule, now: Calendar): Boolean {
        if (!schedule.isEnabled) return false

        val startMinutes = parseMinutes(schedule.startTime)
        val endMinutes = parseMinutes(schedule.endTime)
        if (startMinutes == endMinutes) return false

        val currentMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        val currentIsoDay = calendarDayToIso(now.get(Calendar.DAY_OF_WEEK))
        val isOvernight = startMinutes > endMinutes

        return when (schedule.recurrenceType.lowercase(Locale.US)) {
            "daily" -> {
                if (isOvernight) {
                    currentMinutes >= startMinutes || currentMinutes < endMinutes
                } else {
                    currentMinutes in startMinutes until endMinutes
                }
            }
            "weekdays" -> {
                if (isOvernight) {
                    // Evening portion: Mon-Fri night
                    val isEvening = currentIsoDay in 1..5 && currentMinutes >= startMinutes
                    // Spillover morning: Tue-Sat morning (spillover from Mon-Fri night)
                    val isMorning = currentIsoDay in 2..6 && currentMinutes < endMinutes
                    isEvening || isMorning
                } else {
                    currentIsoDay in 1..5 && currentMinutes in startMinutes until endMinutes
                }
            }
            "custom" -> {
                val activeDays = schedule.customDays
                if (activeDays.isEmpty()) return false
                if (isOvernight) {
                    // Evening on an assigned day
                    val isEvening = currentIsoDay in activeDays && currentMinutes >= startMinutes
                    // Morning spillover from previous day
                    val prevDay = previousIsoDay(currentIsoDay)
                    val isMorning = prevDay in activeDays && currentMinutes < endMinutes
                    isEvening || isMorning
                } else {
                    currentIsoDay in activeDays && currentMinutes in startMinutes until endMinutes
                }
            }
            "one_time" -> {
                val targetDateStr = schedule.targetDate ?: return false
                val todayStr = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(now.time)
                if (isOvernight) {
                    val isEvening = todayStr == targetDateStr && currentMinutes >= startMinutes
                    val yesterday = (now.clone() as Calendar).apply { add(Calendar.DAY_OF_MONTH, -1) }
                    val yesterdayStr = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(yesterday.time)
                    val isMorning = yesterdayStr == targetDateStr && currentMinutes < endMinutes
                    isEvening || isMorning
                } else {
                    todayStr == targetDateStr && currentMinutes in startMinutes until endMinutes
                }
            }
            else -> false
        }
    }

    fun getNextTransitionMillis(schedule: NativeBlockSchedule, now: Calendar): Long? {
        if (!schedule.isEnabled) return null

        val startMinutes = parseMinutes(schedule.startTime)
        val endMinutes = parseMinutes(schedule.endTime)
        if (startMinutes == endMinutes) return null

        val isCurrentlyActive = isScheduleActive(schedule, now)
        val targetMinutes = if (isCurrentlyActive) endMinutes else startMinutes
        val targetHours = targetMinutes / 60
        val targetMins = targetMinutes % 60

        // Search the next 8 days for the next valid occurrence of the transition time
        for (dayOffset in 0..8) {
            val candidate = (now.clone() as Calendar).apply {
                add(Calendar.DAY_OF_YEAR, dayOffset)
                set(Calendar.HOUR_OF_DAY, targetHours)
                set(Calendar.MINUTE, targetMins)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }

            if (candidate.timeInMillis <= now.timeInMillis) continue

            if (isCurrentlyActive) {
                // We are looking for the end transition: candidate must be the moment schedule ceases to be active
                val justBefore = (candidate.clone() as Calendar).apply { add(Calendar.SECOND, -1) }
                if (isScheduleActive(schedule, justBefore)) {
                    return candidate.timeInMillis
                }
            } else {
                // We are looking for the start transition: candidate must become active right at candidate
                if (isScheduleActive(schedule, candidate)) {
                    return candidate.timeInMillis
                }
            }
        }
        return null
    }

    fun getEarliestNextTransitionMillis(schedules: List<NativeBlockSchedule>, now: Calendar): Long? {
        val enabled = schedules.filter { it.isEnabled }
        if (enabled.isEmpty()) return null

        var earliest: Long? = null
        for (schedule in enabled) {
            val next = getNextTransitionMillis(schedule, now) ?: continue
            if (earliest == null || next < earliest) {
                earliest = next
            }
        }
        return earliest
    }

    fun computeActiveSchedulePackages(schedules: List<NativeBlockSchedule>, now: Calendar): Set<String> {
        val activePackages = mutableSetOf<String>()
        for (schedule in schedules) {
            if (isScheduleActive(schedule, now)) {
                activePackages.addAll(schedule.selectedPackages)
            }
        }
        return activePackages
    }
}
