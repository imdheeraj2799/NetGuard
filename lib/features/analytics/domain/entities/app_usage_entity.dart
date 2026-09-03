class AppUsageEntity {
  const AppUsageEntity({
    required this.packageName,
    required this.appName,
    required this.screenTimeSeconds,
    required this.wifiDataBytes,
    required this.mobileDataBytes,
    required this.timestampRange,
  });

  final String packageName;
  final String appName;
  final int screenTimeSeconds;
  final int wifiDataBytes;
  final int mobileDataBytes;
  final String timestampRange;

  int get totalDataBytes => wifiDataBytes + mobileDataBytes;

  String get formattedScreenTime {
    if (screenTimeSeconds < 60) {
      return '${screenTimeSeconds}s';
    }
    final hours = screenTimeSeconds ~/ 3600;
    final minutes = (screenTimeSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get formattedDataUsage {
    final bytes = totalDataBytes;
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kb = (bytes / 1024).toStringAsFixed(1);
      return '$kb KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
      return '$mb MB';
    } else {
      final gb = (bytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
      return '$gb GB';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUsageEntity &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName &&
          appName == other.appName &&
          screenTimeSeconds == other.screenTimeSeconds &&
          wifiDataBytes == other.wifiDataBytes &&
          mobileDataBytes == other.mobileDataBytes &&
          timestampRange == other.timestampRange;

  @override
  int get hashCode =>
      packageName.hashCode ^
      appName.hashCode ^
      screenTimeSeconds.hashCode ^
      wifiDataBytes.hashCode ^
      mobileDataBytes.hashCode ^
      timestampRange.hashCode;
}
