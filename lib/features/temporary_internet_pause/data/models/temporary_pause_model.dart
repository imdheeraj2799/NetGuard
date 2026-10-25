import 'dart:convert';

import '../../domain/entities/temporary_pause_entity.dart';

class TemporaryPauseModel {
  const TemporaryPauseModel({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.startTime,
    required this.pauseUntil,
    required this.durationMillis,
    this.isCustom = false,
  });

  final String id;
  final String packageName;
  final String appName;
  final DateTime startTime;
  final DateTime pauseUntil;
  final int durationMillis;
  final bool isCustom;

  Duration get duration => Duration(milliseconds: durationMillis);

  bool isExpired([DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();
    return now.isAfter(pauseUntil) || now.isAtSameMomentAs(pauseUntil);
  }

  TemporaryPauseEntity toEntity() {
    return TemporaryPauseEntity(
      id: id,
      packageName: packageName,
      appName: appName,
      startTime: startTime,
      pauseUntil: pauseUntil,
      duration: Duration(milliseconds: durationMillis),
      isCustom: isCustom,
    );
  }

  factory TemporaryPauseModel.fromEntity(TemporaryPauseEntity entity) {
    return TemporaryPauseModel(
      id: entity.id,
      packageName: entity.packageName,
      appName: entity.appName,
      startTime: entity.startTime,
      pauseUntil: entity.pauseUntil,
      durationMillis: entity.duration.inMilliseconds,
      isCustom: entity.isCustom,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageName': packageName,
      'appName': appName,
      'startTime': startTime.toIso8601String(),
      'pauseUntil': pauseUntil.toIso8601String(),
      'pauseUntilMillis': pauseUntil.millisecondsSinceEpoch,
      'durationMillis': durationMillis,
      'isCustom': isCustom,
    };
  }

  factory TemporaryPauseModel.fromMap(Map<dynamic, dynamic> map) {
    return TemporaryPauseModel(
      id: (map['id'] as String?) ?? '',
      packageName: (map['packageName'] as String?) ?? '',
      appName: (map['appName'] as String?) ?? '',
      startTime: map['startTime'] != null
          ? DateTime.tryParse(map['startTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      pauseUntil: map['pauseUntil'] != null
          ? DateTime.tryParse(map['pauseUntil'].toString()) ??
              DateTime.fromMillisecondsSinceEpoch(
                (map['pauseUntilMillis'] as num?)?.toInt() ?? 0,
              )
          : DateTime.fromMillisecondsSinceEpoch(
              (map['pauseUntilMillis'] as num?)?.toInt() ?? 0,
            ),
      durationMillis: (map['durationMillis'] as num?)?.toInt() ?? 0,
      isCustom: (map['isCustom'] as bool?) ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory TemporaryPauseModel.fromJson(String source) =>
      TemporaryPauseModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
