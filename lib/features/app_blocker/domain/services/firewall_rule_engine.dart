// ignore_for_file: prefer_initializing_formals

import '../entities/block_schedule_entity.dart';
import 'schedule_engine.dart';

enum BlockReasonType {
  none,
  manual,
  scheduled,
  both,
}

class BlockReason {
  const BlockReason({
    required this.type,
    this.scheduleName,
  });

  final BlockReasonType type;
  final String? scheduleName;

  bool get isBlocked => type != BlockReasonType.none;
}

class FirewallRuleEngine {
  const FirewallRuleEngine({
    ScheduleEngine scheduleEngine = const ScheduleEngine(),
  }) : _scheduleEngine = scheduleEngine;

  final ScheduleEngine _scheduleEngine;

  /// Returns the set of all packages currently blocked by active schedules.
  Set<String> calculateScheduledBlockedPackages({
    required List<BlockScheduleEntity> schedules,
    required DateTime currentTime,
  }) {
    final scheduled = <String>{};
    for (final schedule in schedules) {
      if (_scheduleEngine.isScheduleActiveAt(schedule, currentTime)) {
        scheduled.addAll(schedule.packageNames);
      }
    }
    return Set.unmodifiable(scheduled);
  }

  /// Calculates the effective firewall block list:
  /// EffectiveBlocked = ManualBlocked ∪ ActiveScheduled ∪ ActiveTemporaryPaused
  Set<String> calculateEffectiveBlockedPackages({
    required Set<String> manualBlockedPackages,
    required List<BlockScheduleEntity> schedules,
    required DateTime currentTime,
    Set<String> temporaryPausedPackages = const {},
  }) {
    final scheduled = calculateScheduledBlockedPackages(
      schedules: schedules,
      currentTime: currentTime,
    );
    return Set.unmodifiable(
      manualBlockedPackages.union(scheduled).union(temporaryPausedPackages),
    );
  }

  /// Determines why a specific package is blocked (manual, schedule, both, or none).
  BlockReason getBlockReason({
    required String packageName,
    required Set<String> manualBlockedPackages,
    required List<BlockScheduleEntity> schedules,
    required DateTime currentTime,
  }) {
    final isManual = manualBlockedPackages.contains(packageName);
    String? activeScheduleName;

    for (final schedule in schedules) {
      if (schedule.packageNames.contains(packageName) &&
          _scheduleEngine.isScheduleActiveAt(schedule, currentTime)) {
        activeScheduleName = schedule.name;
        break;
      }
    }

    final isScheduled = activeScheduleName != null;

    if (isManual && isScheduled) {
      return BlockReason(
        type: BlockReasonType.both,
        scheduleName: activeScheduleName,
      );
    } else if (isManual) {
      return const BlockReason(type: BlockReasonType.manual);
    } else if (isScheduled) {
      return BlockReason(
        type: BlockReasonType.scheduled,
        scheduleName: activeScheduleName,
      );
    } else {
      return const BlockReason(type: BlockReasonType.none);
    }
  }
}
