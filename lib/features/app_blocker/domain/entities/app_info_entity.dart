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

  AppInfoEntity copyWith({bool? isBlocked}) => AppInfoEntity(
    appName: appName,
    packageName: packageName,
    isBlocked: isBlocked ?? this.isBlocked,
    iconBytes: iconBytes,
    iconPath: iconPath,
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
