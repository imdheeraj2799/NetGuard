import 'package:flutter_test/flutter_test.dart';
import 'package:net_guard/features/app_blocker/domain/entities/block_schedule_entity.dart';
import 'package:net_guard/features/app_blocker/domain/services/schedule_engine.dart';

void main() {
  const engine = ScheduleEngine();

  group('ScheduleEngine - Daytime Schedules', () {
    final daytimeSchedule = BlockScheduleEntity(
      id: 'day-1',
      name: 'Work Hours',
      packageNames: const ['com.social.app'],
      recurrence: ScheduleRecurrence.daily,
      startHour: 9,
      startMinute: 0,
      endHour: 17,
      endMinute: 0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    test('is active during work hours', () {
      final insideTime = DateTime(2026, 10, 21, 10, 30);
      expect(engine.isScheduleActiveAt(daytimeSchedule, insideTime), isTrue);
    });

    test('is inactive before start time', () {
      final beforeTime = DateTime(2026, 10, 21, 8, 59);
      expect(engine.isScheduleActiveAt(daytimeSchedule, beforeTime), isFalse);
    });

    test('is inactive at or after end time', () {
      final atEndTime = DateTime(2026, 10, 21, 17, 0);
      final afterEndTime = DateTime(2026, 10, 21, 17, 1);
      expect(engine.isScheduleActiveAt(daytimeSchedule, atEndTime), isFalse);
      expect(engine.isScheduleActiveAt(daytimeSchedule, afterEndTime), isFalse);
    });
  });

  group('ScheduleEngine - Overnight Schedules (11:00 PM – 6:00 AM)', () {
    final overnightSchedule = BlockScheduleEntity(
      id: 'night-1',
      name: 'Sleep Time',
      packageNames: const ['com.game.app'],
      recurrence: ScheduleRecurrence.daily,
      startHour: 23,
      startMinute: 0,
      endHour: 6,
      endMinute: 0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    test('identifies as overnight schedule', () {
      expect(overnightSchedule.isOvernight, isTrue);
    });

    test('is active on the start evening (11:00 PM - 11:59 PM)', () {
      expect(
        engine.isScheduleActiveAt(overnightSchedule, DateTime(2026, 10, 21, 23, 0)),
        isTrue,
      );
      expect(
        engine.isScheduleActiveAt(overnightSchedule, DateTime(2026, 10, 21, 23, 45)),
        isTrue,
      );
    });

    test('is active on the following morning (12:00 AM - 5:59 AM)', () {
      expect(
        engine.isScheduleActiveAt(overnightSchedule, DateTime(2026, 10, 22, 0, 0)),
        isTrue,
      );
      expect(
        engine.isScheduleActiveAt(overnightSchedule, DateTime(2026, 10, 22, 2, 30)),
        isTrue,
      );
      expect(
        engine.isScheduleActiveAt(overnightSchedule, DateTime(2026, 10, 22, 5, 59)),
        isTrue,
      );
    });

    test('is inactive at exactly end time and during daytime', () {
      expect(
        engine.isScheduleActiveAt(overnightSchedule, DateTime(2026, 10, 22, 6, 0)),
        isFalse,
      );
      expect(
        engine.isScheduleActiveAt(overnightSchedule, DateTime(2026, 10, 22, 12, 0)),
        isFalse,
      );
      expect(
        engine.isScheduleActiveAt(overnightSchedule, DateTime(2026, 10, 22, 22, 59)),
        isFalse,
      );
    });
  });

  group('ScheduleEngine - Weekday Overnight Schedules', () {
    // Weekday schedule: Mon–Fri, 23:00 to 06:00
    final weekdayOvernight = BlockScheduleEntity(
      id: 'weekday-night',
      name: 'Weekday Sleep',
      packageNames: const ['com.game.app'],
      recurrence: ScheduleRecurrence.weekdays,
      startHour: 23,
      startMinute: 0,
      endHour: 6,
      endMinute: 0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    test('is active Friday night (weekday evening)', () {
      // 2026-10-23 is Friday
      final fridayNight = DateTime(2026, 10, 23, 23, 30);
      expect(fridayNight.weekday, DateTime.friday);
      expect(engine.isScheduleActiveAt(weekdayOvernight, fridayNight), isTrue);
    });

    test('is active Saturday morning (spillover from Friday night start)', () {
      // 2026-10-24 is Saturday morning (spillover from Friday 23:00)
      final saturdayMorning = DateTime(2026, 10, 24, 3, 0);
      expect(saturdayMorning.weekday, DateTime.saturday);
      expect(engine.isScheduleActiveAt(weekdayOvernight, saturdayMorning), isTrue);
    });

    test('is inactive Saturday night (not a weekday start)', () {
      final saturdayNight = DateTime(2026, 10, 24, 23, 30);
      expect(engine.isScheduleActiveAt(weekdayOvernight, saturdayNight), isFalse);
    });

    test('is inactive Sunday morning (Saturday night was not a start)', () {
      final sundayMorning = DateTime(2026, 10, 25, 3, 0);
      expect(engine.isScheduleActiveAt(weekdayOvernight, sundayMorning), isFalse);
    });

    test('is inactive Sunday night (Sunday is not a weekday start)', () {
      final sundayNight = DateTime(2026, 10, 25, 23, 30);
      expect(engine.isScheduleActiveAt(weekdayOvernight, sundayNight), isFalse);
    });
  });

  group('ScheduleEngine - One-Time Schedules', () {
    final oneTimeSchedule = BlockScheduleEntity(
      id: 'one-time-1',
      name: 'Exam Focus',
      packageNames: const ['com.social.app'],
      recurrence: ScheduleRecurrence.oneTime,
      targetDate: DateTime(2026, 10, 21),
      startHour: 14,
      startMinute: 0,
      endHour: 18,
      endMinute: 0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    test('is active on the exact target date and hours', () {
      final validTime = DateTime(2026, 10, 21, 15, 0);
      expect(engine.isScheduleActiveAt(oneTimeSchedule, validTime), isTrue);
    });

    test('is inactive on a different date even at same time', () {
      final differentDay = DateTime(2026, 10, 22, 15, 0);
      expect(engine.isScheduleActiveAt(oneTimeSchedule, differentDay), isFalse);
    });
  });

  group('ScheduleEngine - Next Transition Calculation', () {
    final dailySchedule = BlockScheduleEntity(
      id: 'daily-1',
      name: 'Evening Block',
      packageNames: const ['com.app.test'],
      recurrence: ScheduleRecurrence.daily,
      startHour: 20,
      startMinute: 0,
      endHour: 22,
      endMinute: 0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    test('calculates next start time when currently inactive', () {
      final afternoon = DateTime(2026, 10, 21, 15, 0);
      final nextTransition = engine.getNextTransitionTime(dailySchedule, afternoon);

      expect(nextTransition, DateTime(2026, 10, 21, 20, 0));
    });

    test('calculates next end time when currently active', () {
      final evening = DateTime(2026, 10, 21, 20, 30);
      final nextTransition = engine.getNextTransitionTime(dailySchedule, evening);

      expect(nextTransition, DateTime(2026, 10, 21, 22, 0));
    });

    test('returns null when schedule is disabled', () {
      final disabled = dailySchedule.copyWith(isEnabled: false);
      expect(
        engine.getNextTransitionTime(disabled, DateTime(2026, 10, 21, 12, 0)),
        isNull,
      );
    });
  });
}
