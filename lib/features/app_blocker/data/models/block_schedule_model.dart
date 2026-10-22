import '../../domain/entities/block_schedule_entity.dart';

class BlockScheduleModel extends BlockScheduleEntity {
  const BlockScheduleModel({
    required super.id,
    required super.name,
    required super.packageNames,
    required super.recurrence,
    super.customDaysOfWeek,
    super.targetDate,
    required super.startHour,
    required super.startMinute,
    required super.endHour,
    required super.endMinute,
    super.isEnabled,
    required super.createdAt,
    required super.updatedAt,
  });

  factory BlockScheduleModel.fromEntity(BlockScheduleEntity entity) {
    return BlockScheduleModel(
      id: entity.id,
      name: entity.name,
      packageNames: entity.packageNames,
      recurrence: entity.recurrence,
      customDaysOfWeek: entity.customDaysOfWeek,
      targetDate: entity.targetDate,
      startHour: entity.startHour,
      startMinute: entity.startMinute,
      endHour: entity.endHour,
      endMinute: entity.endMinute,
      isEnabled: entity.isEnabled,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory BlockScheduleModel.fromMap(Map<dynamic, dynamic> map) {
    final recurrenceStr = map['recurrence'] as String?;
    final targetDateStr = map['targetDate'] as String?;
    final customDaysList = map['customDaysOfWeek'] as List<dynamic>?;
    final packageNamesList = map['packageNames'] as List<dynamic>?;

    return BlockScheduleModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      packageNames: packageNamesList != null
          ? List<String>.unmodifiable(packageNamesList.map((e) => e.toString()))
          : const <String>[],
      recurrence: ScheduleRecurrence.fromString(recurrenceStr),
      customDaysOfWeek: customDaysList != null
          ? List<int>.unmodifiable(customDaysList.map((e) => (e as num).toInt()))
          : const <int>[],
      targetDate: targetDateStr != null ? DateTime.tryParse(targetDateStr) : null,
      startHour: (map['startHour'] as num?)?.toInt() ?? 0,
      startMinute: (map['startMinute'] as num?)?.toInt() ?? 0,
      endHour: (map['endHour'] as num?)?.toInt() ?? 0,
      endMinute: (map['endMinute'] as num?)?.toInt() ?? 0,
      isEnabled: map['isEnabled'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  BlockScheduleModel copyWith({
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
    return BlockScheduleModel(
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

  Map<String, dynamic> toMap() {
    final startTimeStr = '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
    final endTimeStr = '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

    return {
      'id': id,
      'name': name,
      'packageNames': packageNames,
      'selectedPackages': packageNames,
      'recurrence': recurrence.name,
      'recurrenceType': recurrence.name,
      'customDaysOfWeek': customDaysOfWeek,
      'customDays': customDaysOfWeek,
      'targetDate': targetDate?.toIso8601String(),
      'startTime': startTimeStr,
      'endTime': endTimeStr,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BlockScheduleEntity toEntity() => BlockScheduleEntity(
        id: id,
        name: name,
        packageNames: packageNames,
        recurrence: recurrence,
        customDaysOfWeek: customDaysOfWeek,
        targetDate: targetDate,
        startHour: startHour,
        startMinute: startMinute,
        endHour: endHour,
        endMinute: endMinute,
        isEnabled: isEnabled,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
