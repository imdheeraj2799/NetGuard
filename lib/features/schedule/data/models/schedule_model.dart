import '../../domain/entities/schedule_entity.dart';

class ScheduleModel extends ScheduleEntity {
  const ScheduleModel({
    required super.id,
    required super.name,
    required super.startTimeMinutes,
    required super.endTimeMinutes,
    required super.activeDays,
    required super.targetPackages,
    super.isEnabled,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] as String,
      name: json['name'] as String,
      startTimeMinutes: json['startTimeMinutes'] as int,
      endTimeMinutes: json['endTimeMinutes'] as int,
      activeDays: (json['activeDays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      targetPackages: (json['targetPackages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startTimeMinutes': startTimeMinutes,
      'endTimeMinutes': endTimeMinutes,
      'activeDays': activeDays,
      'targetPackages': targetPackages,
      'isEnabled': isEnabled,
    };
  }

  factory ScheduleModel.fromEntity(ScheduleEntity entity) {
    return ScheduleModel(
      id: entity.id,
      name: entity.name,
      startTimeMinutes: entity.startTimeMinutes,
      endTimeMinutes: entity.endTimeMinutes,
      activeDays: entity.activeDays,
      targetPackages: entity.targetPackages,
      isEnabled: entity.isEnabled,
    );
  }

  ScheduleEntity toEntity() {
    return ScheduleEntity(
      id: id,
      name: name,
      startTimeMinutes: startTimeMinutes,
      endTimeMinutes: endTimeMinutes,
      activeDays: activeDays,
      targetPackages: targetPackages,
      isEnabled: isEnabled,
    );
  }
}
