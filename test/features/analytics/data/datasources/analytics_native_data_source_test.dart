import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:net_guard/features/analytics/data/datasources/analytics_native_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AnalyticsNativeDataSourceImpl dataSource;
  const channelName = 'com.app.net_guard/analytics';
  final List<MethodCall> log = [];

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName), (
          MethodCall methodCall,
        ) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case 'checkUsagePermission':
              return true;
            case 'requestUsagePermission':
              return null;
            case 'getAppUsageAnalytics':
              return {
                'appUsages': [
                  {
                    'packageName': 'com.instagram.android',
                    'appName': 'Instagram',
                    'screenTimeSeconds': 3600,
                    'wifiDataBytes': 1000,
                    'mobileDataBytes': 500,
                    'timestampRange': methodCall.arguments['timeRange'],
                  }
                ],
                'dailyScreenTimeSeconds': [10, 20, 30, 40, 50, 60, 70],
                'dailyLabels': ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
                'totalScreenTimeSeconds': 3600,
                'totalDataBytes': 1500,
              };
            default:
              return null;
          }
        });

    dataSource = AnalyticsNativeDataSourceImpl(
      channel: const MethodChannel(channelName),
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName), null);
  });

  group('AnalyticsNativeDataSource', () {
    test('checkUsagePermission invokes channel and returns true', () async {
      final result = await dataSource.checkUsagePermission();

      expect(result, isTrue);
      expect(log, hasLength(1));
      expect(log.first.method, 'checkUsagePermission');
    });

    test('requestUsagePermission invokes channel', () async {
      await dataSource.requestUsagePermission();

      expect(log, hasLength(1));
      expect(log.first.method, 'requestUsagePermission');
    });

    test('getAppUsageAnalytics returns AnalyticsSummaryModel', () async {
      final summary = await dataSource.getAppUsageAnalytics('week');

      expect(summary.appUsages.length, 1);
      expect(summary.appUsages.first.packageName, 'com.instagram.android');
      expect(summary.totalScreenTimeSeconds, 3600);
      expect(summary.dailyScreenTimeSeconds.length, 7);
      expect(log.first.arguments, {'timeRange': 'week'});
    });

    test('throws AnalyticsNativeDataSourceException on PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(channelName), (
            MethodCall methodCall,
          ) async {
            throw PlatformException(code: 'ERR', message: 'Channel failed');
          });

      expect(
        () => dataSource.checkUsagePermission(),
        throwsA(isA<AnalyticsNativeDataSourceException>()),
      );
    });
  });
}
