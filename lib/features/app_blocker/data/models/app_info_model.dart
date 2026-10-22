import 'dart:typed_data';

import '../../domain/entities/app_info_entity.dart';

class AppInfoModel extends AppInfoEntity {
  const AppInfoModel({
    required super.appName,
    required super.packageName,
    required super.isBlocked,
    super.iconBytes,
    super.iconPath,
    super.isSchedulePart = false,
    super.whichSchedule,
  });

  factory AppInfoModel.fromMap(Map<dynamic, dynamic> map) {
    final rawIcon = map['iconBytes'];
    return AppInfoModel(
      appName: map['appName'] as String? ?? '',
      packageName: map['packageName'] as String? ?? '',
      isBlocked: map['isBlocked'] as bool? ?? false,
      iconBytes: rawIcon is Uint8List
          ? rawIcon
          : rawIcon is List
          ? Uint8List.fromList(rawIcon.cast<int>())
          : null,
      iconPath: map['iconPath'] as String?,
      isSchedulePart: map['isSchedulePart'] as bool? ?? false,
      whichSchedule: map['whichSchedule'] as String?,
    );
  }

  factory AppInfoModel.fromEntity(AppInfoEntity entity) => AppInfoModel(
    appName: entity.appName,
    packageName: entity.packageName,
    isBlocked: entity.isBlocked,
    iconBytes: entity.iconBytes,
    iconPath: entity.iconPath,
    isSchedulePart: entity.isSchedulePart,
    whichSchedule: entity.whichSchedule,
  );

  @override
  AppInfoModel copyWith({
    String? appName,
    String? packageName,
    bool? isBlocked,
    Uint8List? iconBytes,
    String? iconPath,
    bool? isSchedulePart,
    String? whichSchedule,
    bool clearWhichSchedule = false,
  }) => AppInfoModel(
    appName: appName ?? this.appName,
    packageName: packageName ?? this.packageName,
    isBlocked: isBlocked ?? this.isBlocked,
    iconBytes: iconBytes ?? this.iconBytes,
    iconPath: iconPath ?? this.iconPath,
    isSchedulePart: isSchedulePart ?? this.isSchedulePart,
    whichSchedule: clearWhichSchedule
        ? null
        : (whichSchedule ?? this.whichSchedule),
  );

  Map<String, dynamic> toMap() => {
    'appName': appName,
    'packageName': packageName,
    'isBlocked': isBlocked,
    if (iconBytes != null) 'iconBytes': iconBytes!.toList(),
    if (iconPath != null) 'iconPath': iconPath,
    'isSchedulePart': isSchedulePart,
    if (whichSchedule != null) 'whichSchedule': whichSchedule,
  };

  AppInfoEntity toEntity() => AppInfoEntity(
    appName: appName,
    packageName: packageName,
    isBlocked: isBlocked,
    iconBytes: iconBytes,
    iconPath: iconPath,
    isSchedulePart: isSchedulePart,
    whichSchedule: whichSchedule,
  );
}
