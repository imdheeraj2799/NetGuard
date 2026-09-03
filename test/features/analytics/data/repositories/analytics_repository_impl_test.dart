import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/error/failure.dart';
import 'package:net_guard/features/analytics/data/datasources/analytics_native_data_source.dart';
import 'package:net_guard/features/analytics/data/models/app_usage_model.dart';
import 'package:net_guard/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:net_guard/features/analytics/domain/entities/analytics_time_range.dart';

class MockAnalyticsNativeDataSource extends Mock
    implements AnalyticsNativeDataSource {}

void main() {
  late MockAnalyticsNativeDataSource mockDataSource;
  late AnalyticsRepositoryImpl repository;

  const testSummary = AnalyticsSummaryModel(
    appUsages: [],
    dailyScreenTimeSeconds: [],
    dailyLabels: [],
    totalScreenTimeSeconds: 0,
    totalDataBytes: 0,
  );

  setUp(() {
    mockDataSource = MockAnalyticsNativeDataSource();
    repository = AnalyticsRepositoryImpl(mockDataSource);
  });

  group('AnalyticsRepositoryImpl', () {
    test('checkUsagePermission returns Right(bool) on success', () async {
      when(() => mockDataSource.checkUsagePermission())
          .thenAnswer((_) async => true);

      final result = await repository.checkUsagePermission();

      expect(result, const Right(true));
      verify(() => mockDataSource.checkUsagePermission()).called(1);
    });

    test('checkUsagePermission returns Left(PlatformFailure) on exception', () async {
      when(() => mockDataSource.checkUsagePermission()).thenThrow(
        const AnalyticsNativeDataSourceException('Permission check failed'),
      );

      final result = await repository.checkUsagePermission();

      expect(result, const Left(PlatformFailure('Permission check failed')));
    });

    test('requestUsagePermission returns Right(null) on success', () async {
      when(() => mockDataSource.requestUsagePermission())
          .thenAnswer((_) async => {});

      final result = await repository.requestUsagePermission();

      expect(result, const Right(null));
      verify(() => mockDataSource.requestUsagePermission()).called(1);
    });

    test('getUsageAnalytics returns Right(summary) on success', () async {
      when(() => mockDataSource.getAppUsageAnalytics('week'))
          .thenAnswer((_) async => testSummary);

      final result = await repository.getUsageAnalytics(AnalyticsTimeRange.week);

      expect(result, const Right(testSummary));
      verify(() => mockDataSource.getAppUsageAnalytics('week')).called(1);
    });

    test('getUsageAnalytics returns Left(PlatformFailure) on exception', () async {
      when(() => mockDataSource.getAppUsageAnalytics('week')).thenThrow(
        const AnalyticsNativeDataSourceException('Query failed'),
      );

      final result = await repository.getUsageAnalytics(AnalyticsTimeRange.week);

      expect(result, const Left(PlatformFailure('Query failed')));
    });
  });
}
