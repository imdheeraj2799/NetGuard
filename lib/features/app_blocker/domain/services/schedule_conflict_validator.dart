import '../entities/block_schedule_entity.dart';
import '../entities/schedule_conflict_result.dart';

class ScheduleConflictValidator {
  const ScheduleConflictValidator();

  /// Returns a map of `packageName -> owningScheduleName` for all applications
  /// currently claimed by active/enabled schedules, excluding [excludeScheduleId].
  Map<String, String> getAssignedPackagesMap(
    List<BlockScheduleEntity> schedules, {
    String? excludeScheduleId,
  }) {
    final assigned = <String, String>{};
    for (final schedule in schedules) {
      if (!schedule.isEnabled) continue;
      if (excludeScheduleId != null && schedule.id == excludeScheduleId) continue;
      for (final pkg in schedule.packageNames) {
        assigned[pkg] = schedule.name;
      }
    }
    return Map.unmodifiable(assigned);
  }

  /// Validates [schedule] against [existingSchedules].
  /// Ensures no duplicate package assignment exists across enabled schedules.
  ScheduleConflictResult validateSchedule({
    required BlockScheduleEntity schedule,
    required List<BlockScheduleEntity> existingSchedules,
  }) {
    if (schedule.packageNames.isEmpty) {
      return const ScheduleConflictResult(
        isValid: false,
        errorMessage: 'At least one application must be selected.',
      );
    }

    if (schedule.recurrence == ScheduleRecurrence.oneTime && schedule.targetDate == null) {
      return const ScheduleConflictResult(
        isValid: false,
        errorMessage: 'A target date is required for one-time schedules.',
      );
    }

    if (schedule.recurrence == ScheduleRecurrence.customDays && schedule.customDaysOfWeek.isEmpty) {
      return const ScheduleConflictResult(
        isValid: false,
        errorMessage: 'Select at least one day of the week.',
      );
    }

    // Disabled schedules do not claim packages and cannot cause active conflicts
    if (!schedule.isEnabled) {
      return const ScheduleConflictResult(isValid: true);
    }

    final otherAssigned = getAssignedPackagesMap(
      existingSchedules,
      excludeScheduleId: schedule.id,
    );

    final conflicts = <String, String>{};
    for (final pkg in schedule.packageNames) {
      final owningSchedule = otherAssigned[pkg];
      if (owningSchedule != null) {
        conflicts[pkg] = owningSchedule;
      }
    }

    if (conflicts.isNotEmpty) {
      final sample = conflicts.entries.first;
      return ScheduleConflictResult(
        isValid: false,
        conflictingPackages: conflicts,
        errorMessage: conflicts.length == 1
            ? '${sample.key} is already assigned to "${sample.value}".'
            : '${conflicts.length} applications are already assigned to other active schedules.',
      );
    }

    return const ScheduleConflictResult(isValid: true);
  }
}
