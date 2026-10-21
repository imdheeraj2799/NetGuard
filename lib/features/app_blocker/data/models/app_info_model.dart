import 'dart:typed_data';

import '../../domain/entities/app_info_entity.dart';

class AppInfoModel extends AppInfoEntity {
  const AppInfoModel({
    required super.appName,
    required super.packageName,
    required super.isBlocked,
    super.iconBytes,
    super.iconPath,
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
    );
  }

  factory AppInfoModel.fromEntity(AppInfoEntity entity) => AppInfoModel(
    appName: entity.appName,
    packageName: entity.packageName,
    isBlocked: entity.isBlocked,
    iconBytes: entity.iconBytes,
    iconPath: entity.iconPath,
  );

  @override
  AppInfoModel copyWith({
    String? appName,
    String? packageName,
    bool? isBlocked,
    Uint8List? iconBytes,
    String? iconPath,
  }) => AppInfoModel(
    appName: appName ?? this.appName,
    packageName: packageName ?? this.packageName,
    isBlocked: isBlocked ?? this.isBlocked,
    iconBytes: iconBytes ?? this.iconBytes,
    iconPath: iconPath ?? this.iconPath,
  );

  Map<String, dynamic> toMap() => {
    'appName': appName,
    'packageName': packageName,
    'isBlocked': isBlocked,
    if (iconBytes != null) 'iconBytes': iconBytes!.toList(),
    if (iconPath != null) 'iconPath': iconPath,
  };

  AppInfoEntity toEntity() => AppInfoEntity(
    appName: appName,
    packageName: packageName,
    isBlocked: isBlocked,
    iconBytes: iconBytes,
    iconPath: iconPath,
  );
}
