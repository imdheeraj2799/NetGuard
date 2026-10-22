import 'package:flutter_test/flutter_test.dart';
import 'package:net_guard/features/app_blocker/domain/entities/block_schedule_entity.dart';
import 'package:net_guard/features/app_blocker/domain/services/schedule_conflict_validator.dart';

void main() {
  late ScheduleConflictValidator validator;

  setUp(() {
    validator = const ScheduleConflictValidator();
  });

  final existingSchedule1 = BlockScheduleEntity(
    id: 'sched-1',
    name: 'Work Hours',
    packageNames: const ['com.instagram.android', 'com.twitter.android'],
    recurrence: ScheduleRecurrence.weekdays,
    startHour: 9,
    startMinute: 0,
    endHour: 17,
    endMinute: 0,
    isEnabled: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final existingDisabledSchedule = BlockScheduleEntity(
    id: 'sched-2',
    name: 'Night Owl (Disabled)',
    packageNames: const ['com.reddit.frontpage'],
    recurrence: ScheduleRecurrence.daily,
    startHour: 23,
    startMinute: 0,
    endHour: 6,
    endMinute: 0,
    isEnabled: false,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  group('ScheduleConflictValidator - Basic Validations', () {
    test('returns invalid when packageNames list is empty', () {
      final schedule = BlockScheduleEntity(
        id: 'new-1',
        name: 'Empty Apps',
        packageNames: const [],
        recurrence: ScheduleRecurrence.daily,
        startHour: 10,
        startMinute: 0,
        endHour: 12,
        endMinute: 0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final result = validator.validateSchedule(
        schedule: schedule,
        existingSchedules: [existingSchedule1],
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('At least one application'));
    });

    test('returns invalid when recurrence is oneTime but targetDate is null', () {
      final schedule = BlockScheduleEntity(
        id: 'new-2',
        name: 'One-Time No Date',
        packageNames: const ['com.youtube.android'],
        recurrence: ScheduleRecurrence.oneTime,
        targetDate: null,
        startHour: 10,
        startMinute: 0,
        endHour: 12,
        endMinute: 0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final result = validator.validateSchedule(
        schedule: schedule,
        existingSchedules: [],
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('target date is required'));
    });

    test('returns invalid when recurrence is customDays but customDaysOfWeek is empty', () {
      final schedule = BlockScheduleEntity(
        id: 'new-3',
        name: 'Custom Days Empty',
        packageNames: const ['com.youtube.android'],
        recurrence: ScheduleRecurrence.customDays,
        customDaysOfWeek: const [],
        startHour: 10,
        startMinute: 0,
        endHour: 12,
        endMinute: 0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final result = validator.validateSchedule(
        schedule: schedule,
        existingSchedules: [],
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Select at least one day'));
    });
  });

  group('ScheduleConflictValidator - Conflict Detection', () {
    test('returns valid when new schedule has no overlapping apps with enabled schedules', () {
      final newSchedule = BlockScheduleEntity(
        id: 'new-4',
        name: 'Study Time',
        packageNames: const ['com.youtube.android', 'com.netflix.mediaclient'],
        recurrence: ScheduleRecurrence.weekdays,
        startHour: 18,
        startMinute: 0,
        endHour: 20,
        endMinute: 0,
        isEnabled: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final result = validator.validateSchedule(
        schedule: newSchedule,
        existingSchedules: [existingSchedule1, existingDisabledSchedule],
      );

      expect(result.isValid, isTrue);
      expect(result.conflictingPackages, isEmpty);
      expect(result.errorMessage, isNull);
    });

    test('allows overlap if the new schedule itself is disabled', () {
      final disabledNewSchedule = BlockScheduleEntity(
        id: 'new-5',
        name: 'Inactive Overlap',
        packageNames: const ['com.instagram.android'], // overlaps with existingSchedule1
        recurrence: ScheduleRecurrence.daily,
        startHour: 12,
        startMinute: 0,
        endHour: 14,
        endMinute: 0,
        isEnabled: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final result = validator.validateSchedule(
        schedule: disabledNewSchedule,
        existingSchedules: [existingSchedule1],
      );

      expect(result.isValid, isTrue);
    });

    test('allows overlap if existing conflicting schedule is disabled', () {
      final newSchedule = BlockScheduleEntity(
        id: 'new-6',
        name: 'Reddit Block',
        packageNames: const ['com.reddit.frontpage'], // in existingDisabledSchedule
        recurrence: ScheduleRecurrence.daily,
        startHour: 12,
        startMinute: 0,
        endHour: 14,
        endMinute: 0,
        isEnabled: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final result = validator.validateSchedule(
        schedule: newSchedule,
        existingSchedules: [existingSchedule1, existingDisabledSchedule],
      );

      expect(result.isValid, isTrue);
    });

    test('detects conflict with single conflicting package and formats error message', () {
      final conflictingSchedule = BlockScheduleEntity(
        id: 'new-7',
        name: 'Social Media Block',
        packageNames: const ['com.instagram.android', 'com.snapchat.android'],
        recurrence: ScheduleRecurrence.daily,
        startHour: 12,
        startMinute: 0,
        endHour: 14,
        endMinute: 0,
        isEnabled: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final result = validator.validateSchedule(
        schedule: conflictingSchedule,
        existingSchedules: [existingSchedule1],
      );

      expect(result.isValid, isFalse);
      expect(result.conflictingPackages, containsPair('com.instagram.android', 'Work Hours'));
      expect(result.errorMessage, contains('com.instagram.android is already assigned to "Work Hours"'));
    });

    test('detects conflict with multiple conflicting packages and formats message with count', () {
      final conflictingSchedule = BlockScheduleEntity(
        id: 'new-8',
        name: 'Heavy Social Media Block',
        packageNames: const ['com.instagram.android', 'com.twitter.android'],
        recurrence: ScheduleRecurrence.daily,
        startHour: 12,
        startMinute: 0,
        endHour: 14,
        endMinute: 0,
        isEnabled: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final result = validator.validateSchedule(
        schedule: conflictingSchedule,
        existingSchedules: [existingSchedule1],
      );

      expect(result.isValid, isFalse);
      expect(result.conflictingPackages.length, 2);
      expect(result.errorMessage, contains('2 applications are already assigned'));
    });

    test('allows updating existing schedule without conflicting with itself', () {
      // Modify existingSchedule1: change name or timing, keep same packages
      final updatedSchedule1 = existingSchedule1.copyWith(
        name: 'Work Hours (Updated)',
        startHour: 8,
      );

      final result = validator.validateSchedule(
        schedule: updatedSchedule1,
        existingSchedules: [existingSchedule1, existingDisabledSchedule],
      );

      expect(result.isValid, isTrue);
      expect(result.conflictingPackages, isEmpty);
    });
  });

  group('ScheduleConflictValidator - getAssignedPackagesMap', () {
    test('returns unmodifiable map containing only packages from enabled schedules', () {
      final map = validator.getAssignedPackagesMap([
        existingSchedule1,
        existingDisabledSchedule,
      ]);

      expect(map.containsKey('com.instagram.android'), isTrue);
      expect(map['com.instagram.android'], 'Work Hours');
      expect(map.containsKey('com.twitter.android'), isTrue);
      expect(map.containsKey('com.reddit.frontpage'), isFalse); // disabled
    });

    test('respects excludeScheduleId parameter', () {
      final map = validator.getAssignedPackagesMap(
        [existingSchedule1, existingDisabledSchedule],
        excludeScheduleId: 'sched-1',
      );

      expect(map.isEmpty, isTrue);
    });
  });
}
