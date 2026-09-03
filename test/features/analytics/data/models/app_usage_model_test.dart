import 'package:flutter_test/flutter_test.dart';
import 'package:net_guard/features/analytics/data/models/app_usage_model.dart';
import 'package:net_guard/features/analytics/domain/entities/analytics_summary_entity.dart';
import 'package:net_guard/features/analytics/domain/entities/app_usage_entity.dart';

void main() {
  const testMap = {
    'packageName': 'com.discord',
    'appName': 'Discord',
    'screenTimeSeconds': 1800,
    'wifiDataBytes': 50000,
    'mobileDataBytes': 25000,
    'timestampRange': 'day',
  };

  group('AppUsageModel & AnalyticsSummaryModel', () {
    test('AppUsageModel deserializes from map correctly', () {
      final model = AppUsageModel.fromMap(testMap);

      expect(model.packageName, 'com.discord');
      expect(model.appName, 'Discord');
      expect(model.screenTimeSeconds, 1800);
      expect(model.wifiDataBytes, 50000);
      expect(model.mobileDataBytes, 25000);
      expect(model.timestampRange, 'day');
      expect(model, isA<AppUsageEntity>());
    });

    test('AppUsageModel serializes to map correctly', () {
      final model = AppUsageModel.fromMap(testMap);
      final map = model.toMap();

      expect(map['packageName'], 'com.discord');
      expect(map['screenTimeSeconds'], 1800);
      expect(map['wifiDataBytes'], 50000);
    });

    test('AnalyticsSummaryModel deserializes from map correctly', () {
      final summaryMap = {
        'appUsages': [testMap],
        'dailyScreenTimeSeconds': [100, 200, 300, 400, 500, 600, 700],
        'dailyLabels': ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
        'totalScreenTimeSeconds': 1800,
        'totalDataBytes': 75000,
        'wifiDataBytes': 50000,
        'mobileDataBytes': 25000,
      };

      final model = AnalyticsSummaryModel.fromMap(summaryMap);

      expect(model.appUsages.length, 1);
      expect(model.dailyScreenTimeSeconds.length, 7);
      expect(model.totalScreenTimeSeconds, 1800);
      expect(model.totalDataBytes, 75000);
      expect(model, isA<AnalyticsSummaryEntity>());
    });
  });
}
