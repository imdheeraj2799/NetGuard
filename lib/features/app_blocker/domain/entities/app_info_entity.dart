import 'dart:typed_data';

class AppInfoEntity {
  const AppInfoEntity({
    required this.appName,
    required this.packageName,
    required this.isBlocked,
    this.iconBytes,
    this.iconPath,
  });

  final String appName;
  final String packageName;
  final bool isBlocked;
  final Uint8List? iconBytes;
  final String? iconPath;

  bool get isInternetAllowed => !isBlocked;

  AppInfoEntity copyWith({
    String? appName,
    String? packageName,
    bool? isBlocked,
    Uint8List? iconBytes,
    String? iconPath,
  }) => AppInfoEntity(
    appName: appName ?? this.appName,
    packageName: packageName ?? this.packageName,
    isBlocked: isBlocked ?? this.isBlocked,
    iconBytes: iconBytes ?? this.iconBytes,
    iconPath: iconPath ?? this.iconPath,
  );

  @override
  bool operator ==(Object other) =>
      other is AppInfoEntity &&
      appName == other.appName &&
      packageName == other.packageName &&
      isBlocked == other.isBlocked &&
      iconPath == other.iconPath;

  @override
  int get hashCode => Object.hash(appName, packageName, isBlocked, iconPath);
}
