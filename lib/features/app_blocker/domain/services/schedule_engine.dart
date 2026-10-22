import '../entities/block_schedule_entity.dart';

class ScheduleEngine {
  const ScheduleEngine();

  /// Determines whether [schedule] is actively enforcing blocking at [timestamp].
  bool isScheduleActiveAt(BlockScheduleEntity schedule, DateTime timestamp) {
    if (!schedule.isEnabled || schedule.packageNames.isEmpty) {
      return false;
    }

    final startMins = schedule.startHour * 60 + schedule.startMinute;
    final endMins = schedule.endHour * 60 + schedule.endMinute;
    if (startMins == endMins) {
      return false; // Zero-duration schedule
    }

    final currentMins = timestamp.hour * 60 + timestamp.minute;
    final isOvernight = schedule.isOvernight;

    if (!isOvernight) {
      // Normal same-day schedule (e.g. 09:00 to 17:00)
      final inTimeRange = currentMins >= startMins && currentMins < endMins;
      if (!inTimeRange) return false;
      return _dayMatchesRecurrence(schedule, timestamp);
    } else {
      // Overnight schedule (e.g. 23:00 to 06:00 next morning)
      if (currentMins >= startMins) {
        // Evening phase: active if today was a scheduled start day
        return _dayMatchesRecurrence(schedule, timestamp);
      } else if (currentMins < endMins) {
        // Morning phase: active if yesterday was a scheduled start day
        final yesterday = timestamp.subtract(const Duration(days: 1));
        return _dayMatchesRecurrence(schedule, yesterday);
      } else {
        // In the daytime gap between end and start
        return false;
      }
    }
  }

  /// Calculates the next instant when [schedule] will toggle its active state
  /// (from active to inactive, or inactive to active).
  DateTime? getNextTransitionTime(
    BlockScheduleEntity schedule,
    DateTime fromTimestamp,
  ) {
    if (!schedule.isEnabled || schedule.packageNames.isEmpty) {
      return null;
    }

    final currentlyActive = isScheduleActiveAt(schedule, fromTimestamp);

    // Scan up to 8 days ahead (in candidate transition points)
    final baseDate = DateTime(
      fromTimestamp.year,
      fromTimestamp.month,
      fromTimestamp.day,
    );

    final candidates = <DateTime>[];

    for (var dayOffset = 0; dayOffset <= 8; dayOffset++) {
      final day = baseDate.add(Duration(days: dayOffset));
      final startTime = DateTime(
        day.year,
        day.month,
        day.day,
        schedule.startHour,
        schedule.startMinute,
      );
      final endTime = DateTime(
        day.year,
        day.month,
        day.day,
        schedule.endHour,
        schedule.endMinute,
      );

      if (startTime.isAfter(fromTimestamp)) {
        candidates.add(startTime);
      }
      if (endTime.isAfter(fromTimestamp)) {
        candidates.add(endTime);
      }
    }

    candidates.sort();

    for (final candidate in candidates) {
      // Check state just after the candidate time point
      final stateAfter = isScheduleActiveAt(
        schedule,
        candidate.add(const Duration(seconds: 1)),
      );
      if (stateAfter != currentlyActive) {
        return candidate;
      }
    }

    return null;
  }

  bool _dayMatchesRecurrence(BlockScheduleEntity schedule, DateTime date) {
    return switch (schedule.recurrence) {
      ScheduleRecurrence.oneTime => schedule.targetDate != null &&
          date.year == schedule.targetDate!.year &&
          date.month == schedule.targetDate!.month &&
          date.day == schedule.targetDate!.day,
      ScheduleRecurrence.daily => true,
      ScheduleRecurrence.weekdays =>
        date.weekday >= DateTime.monday && date.weekday <= DateTime.friday,
      ScheduleRecurrence.customDays =>
        schedule.customDaysOfWeek.contains(date.weekday),
    };
  }
}
