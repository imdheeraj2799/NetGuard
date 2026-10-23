import 'package:flutter/foundation.dart';

import '../../domain/entities/block_schedule_entity.dart';

sealed class ScheduleState {
  const ScheduleState();
}

class ScheduleInitial extends ScheduleState {
  const ScheduleInitial();
}

class ScheduleLoading extends ScheduleState {
  const ScheduleLoading();
}

class ScheduleLoaded extends ScheduleState {
  const ScheduleLoaded({
    required this.schedules,
    this.assignedPackages = const {},
    this.canScheduleExactAlarms = true,
    this.areNotificationsEnabled = true,
    this.actionMessage,
  });

  final List<BlockScheduleEntity> schedules;
  final Map<String, String> assignedPackages;
  final bool canScheduleExactAlarms;
  final bool areNotificationsEnabled;
  final String? actionMessage;

  ScheduleLoaded copyWith({
    List<BlockScheduleEntity>? schedules,
    Map<String, String>? assignedPackages,
    bool? canScheduleExactAlarms,
    bool? areNotificationsEnabled,
    String? actionMessage,
  }) {
    return ScheduleLoaded(
      schedules: schedules ?? this.schedules,
      assignedPackages: assignedPackages ?? this.assignedPackages,
      canScheduleExactAlarms:
          canScheduleExactAlarms ?? this.canScheduleExactAlarms,
      areNotificationsEnabled:
          areNotificationsEnabled ?? this.areNotificationsEnabled,
      actionMessage: actionMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleLoaded &&
          listEquals(schedules, other.schedules) &&
          mapEquals(assignedPackages, other.assignedPackages) &&
          canScheduleExactAlarms == other.canScheduleExactAlarms &&
          areNotificationsEnabled == other.areNotificationsEnabled &&
          actionMessage == other.actionMessage;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(schedules),
        Object.hashAll(assignedPackages.entries),
        canScheduleExactAlarms,
        areNotificationsEnabled,
        actionMessage,
      );
}

class ScheduleError extends ScheduleState {
  const ScheduleError({
    required this.message,
    this.schedules = const [],
    this.assignedPackages = const {},
    this.canScheduleExactAlarms = true,
    this.areNotificationsEnabled = true,
  });

  final String message;
  final List<BlockScheduleEntity> schedules;
  final Map<String, String> assignedPackages;
  final bool canScheduleExactAlarms;
  final bool areNotificationsEnabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleError &&
          message == other.message &&
          listEquals(schedules, other.schedules) &&
          mapEquals(assignedPackages, other.assignedPackages) &&
          canScheduleExactAlarms == other.canScheduleExactAlarms &&
          areNotificationsEnabled == other.areNotificationsEnabled;

  @override
  int get hashCode => Object.hash(
        message,
        Object.hashAll(schedules),
        Object.hashAll(assignedPackages.entries),
        canScheduleExactAlarms,
        areNotificationsEnabled,
      );
}
