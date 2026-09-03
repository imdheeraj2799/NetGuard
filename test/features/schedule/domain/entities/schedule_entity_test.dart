import 'package:flutter_test/flutter_test.dart';
import 'package:net_guard/features/schedule/domain/entities/schedule_entity.dart';

void main() {
  group('ScheduleEntity Midnight Crossover & Active Evaluation', () {
    test('same-day schedule is active within time window on active day', () {
      const schedule = ScheduleEntity(
        id: 'work_hours',
        name: 'Work Hours',
        startTimeMinutes: 9 * 60, // 09:00 (540)
        endTimeMinutes: 17 * 60, // 17:00 (1020)
        activeDays: [DateTime.monday, DateTime.tuesday, DateTime.wednesday],
        targetPackages: ['com.social.app'],
        isEnabled: true,
      );

      // Monday at 11:30 AM -> Active
      final mondayActive = DateTime(2026, 3, 2, 11, 30); // 2026-03-02 is Monday
      expect(schedule.isCurrentlyActive(mondayActive), isTrue);

      // Monday at 08:59 AM -> Inactive
      final mondayEarly = DateTime(2026, 3, 2, 8, 59);
      expect(schedule.isCurrentlyActive(mondayEarly), isFalse);

      // Monday at 17:00 PM -> Inactive (exclusive upper bound)
      final mondayAfter = DateTime(2026, 3, 2, 17, 0);
      expect(schedule.isCurrentlyActive(mondayAfter), isFalse);

      // Thursday at 11:30 AM -> Inactive (not an active day)
      final thursdayTime = DateTime(2026, 3, 5, 11, 30); // 2026-03-05 is Thursday
      expect(schedule.isCurrentlyActive(thursdayTime), isFalse);
    });

    test('overnight schedule (midnight crossover 22:00 -> 07:00) is active in evening and next morning', () {
      const schedule = ScheduleEntity(
        id: 'night_filter',
        name: 'Night Filter',
        startTimeMinutes: 22 * 60, // 22:00 = 1320
        endTimeMinutes: 7 * 60, // 07:00 = 420
        activeDays: [DateTime.monday], // Only active starting Monday night!
        targetPackages: ['com.gaming.app'],
        isEnabled: true,
      );

      // Monday evening at 23:30 -> Active
      final mondayNight = DateTime(2026, 3, 2, 23, 30); // Monday
      expect(schedule.isCurrentlyActive(mondayNight), isTrue);

      // Tuesday morning at 05:45 AM -> Active (part of Monday night's schedule)
      final tuesdayMorning = DateTime(2026, 3, 3, 5, 45); // Tuesday
      expect(schedule.isCurrentlyActive(tuesdayMorning), isTrue);

      // Tuesday morning at 07:01 AM -> Inactive (ended at 07:00)
      final tuesdayDay = DateTime(2026, 3, 3, 7, 1);
      expect(schedule.isCurrentlyActive(tuesdayDay), isFalse);

      // Tuesday evening at 23:00 -> Inactive (Tuesday is not in activeDays)
      final tuesdayNight = DateTime(2026, 3, 3, 23, 0);
      expect(schedule.isCurrentlyActive(tuesdayNight), isFalse);
    });

    test('Sunday night rollover into Monday morning works correctly', () {
      const schedule = ScheduleEntity(
        id: 'sunday_night',
        name: 'Sunday Night',
        startTimeMinutes: 23 * 60, // 23:00 = 1380
        endTimeMinutes: 6 * 60, // 06:00 = 360
        activeDays: [DateTime.sunday],
        targetPackages: ['com.app'],
        isEnabled: true,
      );

      // Sunday 23:15 -> Active
      final sundayNight = DateTime(2026, 3, 1, 23, 15); // 2026-03-01 is Sunday
      expect(schedule.isCurrentlyActive(sundayNight), isTrue);

      // Monday 04:30 AM -> Active (rollover from Sunday)
      final mondayMorning = DateTime(2026, 3, 2, 4, 30); // Monday
      expect(schedule.isCurrentlyActive(mondayMorning), isTrue);

      // Monday 06:15 AM -> Inactive
      final mondayDay = DateTime(2026, 3, 2, 6, 15);
      expect(schedule.isCurrentlyActive(mondayDay), isFalse);
    });

    test('disabled schedule is never active', () {
      const schedule = ScheduleEntity(
        id: 'disabled',
        name: 'Disabled Schedule',
        startTimeMinutes: 0,
        endTimeMinutes: 1439,
        activeDays: [1, 2, 3, 4, 5, 6, 7],
        targetPackages: ['com.app'],
        isEnabled: false,
      );

      expect(schedule.isCurrentlyActive(DateTime.now()), isFalse);
    });

    test('formats time range and active days cleanly', () {
      const schedule1 = ScheduleEntity(
        id: 's1',
        name: 'Night',
        startTimeMinutes: 22 * 60, // 22:00 -> 10:00 PM
        endTimeMinutes: 7 * 60, // 07:00 -> 07:00 AM
        activeDays: [1, 2, 3, 4, 5],
        targetPackages: [],
      );

      expect(schedule1.formattedTimeRange(), '10:00 PM - 07:00 AM');
      expect(schedule1.formattedActiveDays(), 'Mon - Fri');

      const schedule2 = ScheduleEntity(
        id: 's2',
        name: 'All Week',
        startTimeMinutes: 0, // 12:00 AM
        endTimeMinutes: 12 * 60, // 12:00 PM
        activeDays: [1, 2, 3, 4, 5, 6, 7],
        targetPackages: [],
      );

      expect(schedule2.formattedTimeRange(), '12:00 AM - 12:00 PM');
      expect(schedule2.formattedActiveDays(), 'Everyday');
    });
  });
}
