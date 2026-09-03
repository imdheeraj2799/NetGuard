import '../../domain/entities/analytics_summary_entity.dart';
import '../../domain/entities/app_usage_entity.dart';

class AppUsageModel extends AppUsageEntity {
  const AppUsageModel({
    required super.packageName,
    required super.appName,
    required super.screenTimeSeconds,
    required super.wifiDataBytes,
    required super.mobileDataBytes,
    required super.timestampRange,
  });

  factory AppUsageModel.fromMap(Map<dynamic, dynamic> map) {
    return AppUsageModel(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? (map['packageName'] as String? ?? ''),
      screenTimeSeconds: (map['screenTimeSeconds'] as num?)?.toInt() ?? 0,
      wifiDataBytes: (map['wifiDataBytes'] as num?)?.toInt() ?? 0,
      mobileDataBytes: (map['mobileDataBytes'] as num?)?.toInt() ?? 0,
      timestampRange: map['timestampRange'] as String? ?? 'week',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'screenTimeSeconds': screenTimeSeconds,
      'wifiDataBytes': wifiDataBytes,
      'mobileDataBytes': mobileDataBytes,
      'timestampRange': timestampRange,
    };
  }
}

class AnalyticsSummaryModel extends AnalyticsSummaryEntity {
  const AnalyticsSummaryModel({
    required super.appUsages,
    required super.dailyScreenTimeSeconds,
    required super.dailyLabels,
    required super.totalScreenTimeSeconds,
    required super.totalDataBytes,
    super.wifiDataBytes,
    super.mobileDataBytes,
  });

  factory AnalyticsSummaryModel.fromMap(Map<dynamic, dynamic> map) {
    final rawApps = map['appUsages'] as List<dynamic>? ?? [];
    final appUsages = rawApps
        .map((item) => AppUsageModel.fromMap(item as Map<dynamic, dynamic>))
        .toList();

    final rawDaily = map['dailyScreenTimeSeconds'] as List<dynamic>? ?? [];
    final dailyScreenTimeSeconds = rawDaily
        .map((val) => (val as num).toInt())
        .toList();

    final rawLabels = map['dailyLabels'] as List<dynamic>? ?? [];
    final dailyLabels = rawLabels.map((l) => l.toString()).toList();

    final totalScreenTimeSeconds = (map['totalScreenTimeSeconds'] as num?)?.toInt() ??
        appUsages.fold<int>(0, (sum, a) => sum + a.screenTimeSeconds);

    final totalDataBytes = (map['totalDataBytes'] as num?)?.toInt() ??
        appUsages.fold<int>(0, (sum, a) => sum + a.totalDataBytes);

    final wifiDataBytes = (map['wifiDataBytes'] as num?)?.toInt() ??
        appUsages.fold<int>(0, (sum, a) => sum + a.wifiDataBytes);

    final mobileDataBytes = (map['mobileDataBytes'] as num?)?.toInt() ??
        appUsages.fold<int>(0, (sum, a) => sum + a.mobileDataBytes);

    return AnalyticsSummaryModel(
      appUsages: appUsages,
      dailyScreenTimeSeconds: dailyScreenTimeSeconds,
      dailyLabels: dailyLabels,
      totalScreenTimeSeconds: totalScreenTimeSeconds,
      totalDataBytes: totalDataBytes,
      wifiDataBytes: wifiDataBytes,
      mobileDataBytes: mobileDataBytes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appUsages': appUsages.map((a) {
        if (a is AppUsageModel) return a.toMap();
        return AppUsageModel(
          packageName: a.packageName,
          appName: a.appName,
          screenTimeSeconds: a.screenTimeSeconds,
          wifiDataBytes: a.wifiDataBytes,
          mobileDataBytes: a.mobileDataBytes,
          timestampRange: a.timestampRange,
        ).toMap();
      }).toList(),
      'dailyScreenTimeSeconds': dailyScreenTimeSeconds,
      'dailyLabels': dailyLabels,
      'totalScreenTimeSeconds': totalScreenTimeSeconds,
      'totalDataBytes': totalDataBytes,
      'wifiDataBytes': wifiDataBytes,
      'mobileDataBytes': mobileDataBytes,
    };
  }
}
