import 'package:flutter_test/flutter_test.dart';
import 'package:net_guard/features/app_blocker/domain/entities/block_schedule_entity.dart';
import 'package:net_guard/features/app_blocker/domain/services/firewall_rule_engine.dart';
import 'package:net_guard/features/app_blocker/domain/services/schedule_engine.dart';

void main() {
  late FirewallRuleEngine ruleEngine;

  setUp(() {
    ruleEngine = const FirewallRuleEngine(scheduleEngine: ScheduleEngine());
  });

  final workSchedule = BlockScheduleEntity(
    id: 'work-1',
    name: 'Work Focus',
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

  final nightSchedule = BlockScheduleEntity(
    id: 'night-1',
    name: 'Night Sleep',
    packageNames: const ['com.youtube.android'],
    recurrence: ScheduleRecurrence.daily,
    startHour: 23,
    startMinute: 0,
    endHour: 6,
    endMinute: 0,
    isEnabled: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final disabledSchedule = BlockScheduleEntity(
    id: 'dis-1',
    name: 'Disabled Games',
    packageNames: const ['com.pubg.imobile'],
    recurrence: ScheduleRecurrence.daily,
    startHour: 0,
    startMinute: 0,
    endHour: 23,
    endMinute: 59,
    isEnabled: false,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  group('FirewallRuleEngine - calculateScheduledBlockedPackages', () {
    test('returns empty set when no schedules are active', () {
      // Monday 18:00 (outside work schedule and night schedule)
      final mondayEvening = DateTime(2026, 10, 19, 18, 0);

      final blocked = ruleEngine.calculateScheduledBlockedPackages(
        schedules: [workSchedule, nightSchedule, disabledSchedule],
        currentTime: mondayEvening,
      );

      expect(blocked, isEmpty);
    });

    test('returns packages for active schedule and ignores disabled schedules', () {
      // Monday 10:00 (during work schedule)
      final mondayMorning = DateTime(2026, 10, 19, 10, 0);

      final blocked = ruleEngine.calculateScheduledBlockedPackages(
        schedules: [workSchedule, nightSchedule, disabledSchedule],
        currentTime: mondayMorning,
      );

      expect(blocked, containsAll(['com.instagram.android', 'com.twitter.android']));
      expect(blocked.contains('com.pubg.imobile'), isFalse);
    });

    test('combines packages if multiple schedules are active simultaneously', () {
      final overlappingSchedule = BlockScheduleEntity(
        id: 'news-1',
        name: 'News Block',
        packageNames: const ['com.reddit.frontpage'],
        recurrence: ScheduleRecurrence.daily,
        startHour: 9,
        startMinute: 0,
        endHour: 12,
        endMinute: 0,
        isEnabled: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final monday10am = DateTime(2026, 10, 19, 10, 0);
      final blocked = ruleEngine.calculateScheduledBlockedPackages(
        schedules: [workSchedule, overlappingSchedule],
        currentTime: monday10am,
      );

      expect(blocked.length, 3);
      expect(
        blocked,
        containsAll([
          'com.instagram.android',
          'com.twitter.android',
          'com.reddit.frontpage',
        ]),
      );
    });
  });

  group('FirewallRuleEngine - calculateEffectiveBlockedPackages & Precedence', () {
    test('returns union of manual blocked packages and scheduled blocked packages', () {
      final manualBlocked = {'com.whatsapp', 'com.instagram.android'};
      final monday10am = DateTime(2026, 10, 19, 10, 0); // work schedule active

      final effective = ruleEngine.calculateEffectiveBlockedPackages(
        manualBlockedPackages: manualBlocked,
        schedules: [workSchedule],
        currentTime: monday10am,
      );

      expect(
        effective,
        containsAll([
          'com.whatsapp', // purely manual
          'com.instagram.android', // both manual and scheduled
          'com.twitter.android', // purely scheduled
        ]),
      );
    });

    test('when schedule ends, scheduled app becomes unblocked if not manually blocked', () {
      final manualBlocked = <String>{};
      final duringWork = DateTime(2026, 10, 19, 14, 0);
      final afterWork = DateTime(2026, 10, 19, 18, 0);

      final effectiveDuring = ruleEngine.calculateEffectiveBlockedPackages(
        manualBlockedPackages: manualBlocked,
        schedules: [workSchedule],
        currentTime: duringWork,
      );
      expect(effectiveDuring.contains('com.instagram.android'), isTrue);

      final effectiveAfter = ruleEngine.calculateEffectiveBlockedPackages(
        manualBlockedPackages: manualBlocked,
        schedules: [workSchedule],
        currentTime: afterWork,
      );
      expect(effectiveAfter.contains('com.instagram.android'), isFalse);
    });

    test('when schedule ends, app remains blocked if it was also manually blocked', () {
      final manualBlocked = {'com.instagram.android'};
      final afterWork = DateTime(2026, 10, 19, 18, 0);

      final effectiveAfter = ruleEngine.calculateEffectiveBlockedPackages(
        manualBlockedPackages: manualBlocked,
        schedules: [workSchedule],
        currentTime: afterWork,
      );

      expect(effectiveAfter.contains('com.instagram.android'), isTrue);
    });

    test('manually blocked app stays blocked even if all schedules are disabled', () {
      final manualBlocked = {'com.facebook.katana'};
      final time = DateTime(2026, 10, 19, 12, 0);

      final effective = ruleEngine.calculateEffectiveBlockedPackages(
        manualBlockedPackages: manualBlocked,
        schedules: [disabledSchedule],
        currentTime: time,
      );

      expect(effective, {'com.facebook.katana'});
    });
  });

  group('FirewallRuleEngine - getBlockReason', () {
    final monday10am = DateTime(2026, 10, 19, 10, 0); // workSchedule active

    test('returns BlockReasonType.none when app is neither manual nor scheduled', () {
      final reason = ruleEngine.getBlockReason(
        packageName: 'com.spotify.music',
        manualBlockedPackages: {'com.whatsapp'},
        schedules: [workSchedule],
        currentTime: monday10am,
      );

      expect(reason.type, BlockReasonType.none);
      expect(reason.isBlocked, isFalse);
      expect(reason.scheduleName, isNull);
    });

    test('returns BlockReasonType.manual when app is only manually blocked', () {
      final reason = ruleEngine.getBlockReason(
        packageName: 'com.whatsapp',
        manualBlockedPackages: {'com.whatsapp'},
        schedules: [workSchedule],
        currentTime: monday10am,
      );

      expect(reason.type, BlockReasonType.manual);
      expect(reason.isBlocked, isTrue);
      expect(reason.scheduleName, isNull);
    });

    test('returns BlockReasonType.scheduled when app is only in an active schedule', () {
      final reason = ruleEngine.getBlockReason(
        packageName: 'com.instagram.android',
        manualBlockedPackages: {'com.whatsapp'},
        schedules: [workSchedule],
        currentTime: monday10am,
      );

      expect(reason.type, BlockReasonType.scheduled);
      expect(reason.isBlocked, isTrue);
      expect(reason.scheduleName, 'Work Focus');
    });

    test('returns BlockReasonType.both when app is both manually blocked and in active schedule', () {
      final reason = ruleEngine.getBlockReason(
        packageName: 'com.instagram.android',
        manualBlockedPackages: {'com.instagram.android'},
        schedules: [workSchedule],
        currentTime: monday10am,
      );

      expect(reason.type, BlockReasonType.both);
      expect(reason.isBlocked, isTrue);
      expect(reason.scheduleName, 'Work Focus');
    });

    test('returns BlockReasonType.manual when app is manual blocked and in an INACTIVE schedule', () {
      final mondayEvening = DateTime(2026, 10, 19, 20, 0); // workSchedule inactive

      final reason = ruleEngine.getBlockReason(
        packageName: 'com.instagram.android',
        manualBlockedPackages: {'com.instagram.android'},
        schedules: [workSchedule],
        currentTime: mondayEvening,
      );

      expect(reason.type, BlockReasonType.manual);
      expect(reason.isBlocked, isTrue);
      expect(reason.scheduleName, isNull);
    });
  });
}
