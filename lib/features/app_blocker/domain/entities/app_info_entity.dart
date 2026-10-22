import 'dart:typed_data';

class AppInfoEntity {
  const AppInfoEntity({
    required this.appName,
    required this.packageName,
    required this.isBlocked,
    this.iconBytes,
    this.iconPath,
    this.isSchedulePart = false,
    this.whichSchedule,
  });

  final String appName;
  final String packageName;
  final bool isBlocked;
  final Uint8List? iconBytes;
  final String? iconPath;
  final bool isSchedulePart;
  final String? whichSchedule;

  bool get isInternetAllowed => !isBlocked;

  AppInfoEntity copyWith({
    String? appName,
    String? packageName,
    bool? isBlocked,
    Uint8List? iconBytes,
    String? iconPath,
    bool? isSchedulePart,
    String? whichSchedule,
    bool clearWhichSchedule = false,
  }) => AppInfoEntity(
    appName: appName ?? this.appName,
    packageName: packageName ?? this.packageName,
    isBlocked: isBlocked ?? this.isBlocked,
    iconBytes: iconBytes ?? this.iconBytes,
    iconPath: iconPath ?? this.iconPath,
    isSchedulePart: isSchedulePart ?? this.isSchedulePart,
    whichSchedule: clearWhichSchedule ? null : (whichSchedule ?? this.whichSchedule),
  );

  @override
  bool operator ==(Object other) =>
      other is AppInfoEntity &&
      appName == other.appName &&
      packageName == other.packageName &&
      isBlocked == other.isBlocked &&
      iconPath == other.iconPath &&
      isSchedulePart == other.isSchedulePart &&
      whichSchedule == other.whichSchedule;

  @override
  int get hashCode => Object.hash(
        appName,
        packageName,
        isBlocked,
        iconPath,
        isSchedulePart,
        whichSchedule,
      );
}
