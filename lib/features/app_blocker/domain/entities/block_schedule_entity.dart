import 'package:flutter/foundation.dart';

enum ScheduleRecurrence {
  oneTime,
  daily,
  weekdays,
  customDays;

  static ScheduleRecurrence fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'onetime' => ScheduleRecurrence.oneTime,
      'weekdays' => ScheduleRecurrence.weekdays,
      'customdays' => ScheduleRecurrence.customDays,
      _ => ScheduleRecurrence.daily,
    };
  }

  String get displayName => switch (this) {
        ScheduleRecurrence.oneTime => 'One-time',
        ScheduleRecurrence.daily => 'Every day',
        ScheduleRecurrence.weekdays => 'Weekdays (Mon–Fri)',
        ScheduleRecurrence.customDays => 'Custom days',
      };
}

class BlockScheduleEntity {
  const BlockScheduleEntity({
    required this.id,
    required this.name,
    required this.packageNames,
    required this.recurrence,
    this.customDaysOfWeek = const <int>[],
    this.targetDate,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.isEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final List<String> packageNames;
  final ScheduleRecurrence recurrence;
  final List<int> customDaysOfWeek; // 1 = Mon, ..., 7 = Sun (DateTime.monday ... DateTime.sunday)
  final DateTime? targetDate;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOvernight {
    final startTotal = startHour * 60 + startMinute;
    final endTotal = endHour * 60 + endMinute;
    return startTotal > endTotal;
  }

  String get formattedTimeRange {
    final startPeriod = startHour >= 12 ? 'PM' : 'AM';
    final endPeriod = endHour >= 12 ? 'PM' : 'AM';
    final startH = startHour == 0 ? 12 : (startHour > 12 ? startHour - 12 : startHour);
    final endH = endHour == 0 ? 12 : (endHour > 12 ? endHour - 12 : endHour);
    final startM = startMinute.toString().padLeft(2, '0');
    final endM = endMinute.toString().padLeft(2, '0');
    final overnightSuffix = isOvernight ? ' (+1 day)' : '';
    return '$startH:$startM $startPeriod – $endH:$endM $endPeriod$overnightSuffix';
  }

  BlockScheduleEntity copyWith({
    String? id,
    String? name,
    List<String>? packageNames,
    ScheduleRecurrence? recurrence,
    List<int>? customDaysOfWeek,
    DateTime? targetDate,
    bool clearTargetDate = false,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BlockScheduleEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      packageNames: packageNames ?? this.packageNames,
      recurrence: recurrence ?? this.recurrence,
      customDaysOfWeek: customDaysOfWeek ?? this.customDaysOfWeek,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockScheduleEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          listEquals(packageNames, other.packageNames) &&
          recurrence == other.recurrence &&
          listEquals(customDaysOfWeek, other.customDaysOfWeek) &&
          targetDate?.year == other.targetDate?.year &&
          targetDate?.month == other.targetDate?.month &&
          targetDate?.day == other.targetDate?.day &&
          startHour == other.startHour &&
          startMinute == other.startMinute &&
          endHour == other.endHour &&
          endMinute == other.endMinute &&
          isEnabled == other.isEnabled;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        Object.hashAll(packageNames),
        recurrence,
        Object.hashAll(customDaysOfWeek),
        targetDate?.year,
        startHour,
        startMinute,
        endHour,
        endMinute,
        isEnabled,
      );
}
