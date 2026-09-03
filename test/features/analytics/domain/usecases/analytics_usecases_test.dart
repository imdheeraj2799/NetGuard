import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/error/failure.dart';
import 'package:net_guard/core/usecase/usecase.dart';
import 'package:net_guard/features/analytics/domain/entities/analytics_summary_entity.dart';
import 'package:net_guard/features/analytics/domain/entities/analytics_time_range.dart';
import 'package:net_guard/features/analytics/domain/entities/app_usage_entity.dart';
import 'package:net_guard/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:net_guard/features/analytics/domain/usecases/check_usage_permission_usecase.dart';
import 'package:net_guard/features/analytics/domain/usecases/get_usage_analytics_usecase.dart';
import 'package:net_guard/features/analytics/domain/usecases/request_usage_permission_usecase.dart';

class MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

void main() {
  late MockAnalyticsRepository mockRepository;
  late GetUsageAnalyticsUseCase getUsageAnalyticsUseCase;
  late CheckUsagePermissionUseCase checkUsagePermissionUseCase;
  late RequestUsagePermissionUseCase requestUsagePermissionUseCase;

  const testAppUsage = AppUsageEntity(
    packageName: 'com.instagram.android',
    appName: 'Instagram',
    screenTimeSeconds: 3660,
    wifiDataBytes: 1048576,
    mobileDataBytes: 524288,
    timestampRange: 'week',
  );

  const testSummary = AnalyticsSummaryEntity(
    appUsages: [testAppUsage],
    dailyScreenTimeSeconds: [1800, 3600, 2400, 7200, 5400, 3600, 1800],
    dailyLabels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
    totalScreenTimeSeconds: 3660,
    totalDataBytes: 1572864,
  );

  setUp(() {
    mockRepository = MockAnalyticsRepository();
    getUsageAnalyticsUseCase = GetUsageAnalyticsUseCase(mockRepository);
    checkUsagePermissionUseCase = CheckUsagePermissionUseCase(mockRepository);
    requestUsagePermissionUseCase = RequestUsagePermissionUseCase(mockRepository);
  });

  group('Analytics Domain Tests', () {
    test('AppUsageEntity formatted getters produce correct strings', () {
      expect(testAppUsage.totalDataBytes, 1572864);
      expect(testAppUsage.formattedScreenTime, '1h 1m');
      expect(testAppUsage.formattedDataUsage, '1.5 MB');

      const shortUsage = AppUsageEntity(
        packageName: 'pkg',
        appName: 'app',
        screenTimeSeconds: 45,
        wifiDataBytes: 500,
        mobileDataBytes: 0,
        timestampRange: 'day',
      );
      expect(shortUsage.formattedScreenTime, '45s');
      expect(shortUsage.formattedDataUsage, '500 B');
    });

    test('AnalyticsSummaryEntity formatted getters produce correct strings', () {
      expect(testSummary.formattedTotalScreenTime, '1h 1m');
      expect(testSummary.formattedTotalData, '1.5 MB');
      expect(testSummary.formattedAverageDailyScreenTime, 'AVG 1.0H/DAY');
      expect(testSummary.dailyActivityRatios.length, 7);
      expect(testSummary.dailyActivityRatios[3], 1.0); // 7200 is max
    });

    test('GetUsageAnalyticsUseCase returns summary from repository on success', () async {
      when(
        () => mockRepository.getUsageAnalytics(AnalyticsTimeRange.week),
      ).thenAnswer((_) async => const Right(testSummary));

      final result = await getUsageAnalyticsUseCase(
        const GetUsageAnalyticsParams(AnalyticsTimeRange.week),
      );

      expect(result, const Right(testSummary));
      verify(
        () => mockRepository.getUsageAnalytics(AnalyticsTimeRange.week),
      ).called(1);
    });

    test('GetUsageAnalyticsUseCase returns failure on repository error', () async {
      when(
        () => mockRepository.getUsageAnalytics(AnalyticsTimeRange.week),
      ).thenAnswer(
        (_) async => const Left(PlatformFailure('Permission denied')),
      );

      final result = await getUsageAnalyticsUseCase(
        const GetUsageAnalyticsParams(AnalyticsTimeRange.week),
      );

      expect(result, const Left(PlatformFailure('Permission denied')));
    });

    test('CheckUsagePermissionUseCase returns boolean from repository', () async {
      when(() => mockRepository.checkUsagePermission())
          .thenAnswer((_) async => const Right(true));

      final result = await checkUsagePermissionUseCase(const NoParams());

      expect(result, const Right(true));
      verify(() => mockRepository.checkUsagePermission()).called(1);
    });

    test('RequestUsagePermissionUseCase calls repository and returns Right(null)', () async {
      when(() => mockRepository.requestUsagePermission())
          .thenAnswer((_) async => const Right(null));

      final result = await requestUsagePermissionUseCase(const NoParams());

      expect(result, const Right(null));
      verify(() => mockRepository.requestUsagePermission()).called(1);
    });
  });
}
