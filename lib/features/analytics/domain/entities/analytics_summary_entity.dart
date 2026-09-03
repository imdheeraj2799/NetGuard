import 'package:flutter/foundation.dart';
import 'app_usage_entity.dart';

class AnalyticsSummaryEntity {
  const AnalyticsSummaryEntity({
    required this.appUsages,
    required this.dailyScreenTimeSeconds,
    required this.dailyLabels,
    required this.totalScreenTimeSeconds,
    required this.totalDataBytes,
    this.wifiDataBytes = 0,
    this.mobileDataBytes = 0,
  });

  final List<AppUsageEntity> appUsages;
  final List<int> dailyScreenTimeSeconds;
  final List<String> dailyLabels;
  final int totalScreenTimeSeconds;
  final int totalDataBytes;
  final int wifiDataBytes;
  final int mobileDataBytes;

  String get formattedTotalScreenTime {
    if (totalScreenTimeSeconds < 60) {
      return '${totalScreenTimeSeconds}s';
    }
    final hours = totalScreenTimeSeconds ~/ 3600;
    final minutes = (totalScreenTimeSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get formattedTotalData {
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

  String get formattedAverageDailyScreenTime {
    if (dailyScreenTimeSeconds.isEmpty) return 'AVG 0H/DAY';
    final sum = dailyScreenTimeSeconds.fold<int>(0, (a, b) => a + b);
    final avgSeconds = sum / dailyScreenTimeSeconds.length;
    final avgHours = (avgSeconds / 3600).toStringAsFixed(1);
    return 'AVG ${avgHours}H/DAY';
  }

  List<double> get dailyActivityRatios {
    if (dailyScreenTimeSeconds.isEmpty) return const [];
    final maxSec = dailyScreenTimeSeconds.fold<int>(
      0,
      (max, sec) => sec > max ? sec : max,
    );
    if (maxSec == 0) {
      return List<double>.filled(dailyScreenTimeSeconds.length, 0.05);
    }
    return dailyScreenTimeSeconds
        .map((sec) => (sec / maxSec).clamp(0.05, 1.0))
        .toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsSummaryEntity &&
          runtimeType == other.runtimeType &&
          listEquals(appUsages, other.appUsages) &&
          listEquals(dailyScreenTimeSeconds, other.dailyScreenTimeSeconds) &&
          listEquals(dailyLabels, other.dailyLabels) &&
          totalScreenTimeSeconds == other.totalScreenTimeSeconds &&
          totalDataBytes == other.totalDataBytes &&
          wifiDataBytes == other.wifiDataBytes &&
          mobileDataBytes == other.mobileDataBytes;

  @override
  int get hashCode =>
      Object.hash(
        Object.hashAll(appUsages),
        Object.hashAll(dailyScreenTimeSeconds),
        Object.hashAll(dailyLabels),
        totalScreenTimeSeconds,
        totalDataBytes,
        wifiDataBytes,
        mobileDataBytes,
      );
}
