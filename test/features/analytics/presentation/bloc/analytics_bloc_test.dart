import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/error/failure.dart';
import 'package:net_guard/core/usecase/usecase.dart';
import 'package:net_guard/features/analytics/domain/entities/analytics_summary_entity.dart';
import 'package:net_guard/features/analytics/domain/entities/analytics_time_range.dart';
import 'package:net_guard/features/analytics/domain/entities/app_usage_entity.dart';
import 'package:net_guard/features/analytics/domain/usecases/check_usage_permission_usecase.dart';
import 'package:net_guard/features/analytics/domain/usecases/get_usage_analytics_usecase.dart';
import 'package:net_guard/features/analytics/domain/usecases/request_usage_permission_usecase.dart';
import 'package:net_guard/features/analytics/presentation/bloc/analytics_bloc.dart';
import 'package:net_guard/features/analytics/presentation/bloc/analytics_event.dart';
import 'package:net_guard/features/analytics/presentation/bloc/analytics_state.dart';

class MockCheckUsagePermissionUseCase extends Mock
    implements CheckUsagePermissionUseCase {}

class MockRequestUsagePermissionUseCase extends Mock
    implements RequestUsagePermissionUseCase {}

class MockGetUsageAnalyticsUseCase extends Mock
    implements GetUsageAnalyticsUseCase {}

void main() {
  late MockCheckUsagePermissionUseCase mockCheckPermission;
  late MockRequestUsagePermissionUseCase mockRequestPermission;
  late MockGetUsageAnalyticsUseCase mockGetUsageAnalytics;
  late AnalyticsBloc bloc;

  const testSummary = AnalyticsSummaryEntity(
    appUsages: [
      AppUsageEntity(
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        screenTimeSeconds: 3600,
        wifiDataBytes: 1048576,
        mobileDataBytes: 524288,
        timestampRange: 'week',
      ),
    ],
    dailyScreenTimeSeconds: [100, 200, 300, 400, 500, 600, 700],
    dailyLabels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
    totalScreenTimeSeconds: 3600,
    totalDataBytes: 1572864,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const GetUsageAnalyticsParams(AnalyticsTimeRange.week),
    );
  });

  setUp(() {
    mockCheckPermission = MockCheckUsagePermissionUseCase();
    mockRequestPermission = MockRequestUsagePermissionUseCase();
    mockGetUsageAnalytics = MockGetUsageAnalyticsUseCase();

    bloc = AnalyticsBloc(
      checkUsagePermission: mockCheckPermission,
      requestUsagePermission: mockRequestPermission,
      getUsageAnalytics: mockGetUsageAnalytics,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('AnalyticsBloc Tests', () {
    test('initial state is AnalyticsInitial', () {
      expect(bloc.state, const AnalyticsInitial());
    });

    blocTest<AnalyticsBloc, AnalyticsState>(
      'emits [AnalyticsPermissionRequired] when checkPermission returns false',
      build: () {
        when(() => mockCheckPermission(any()))
            .thenAnswer((_) async => const Right(false));
        return bloc;
      },
      act: (b) => b.add(const CheckAnalyticsPermissionEvent()),
      expect: () => [const AnalyticsPermissionRequired()],
    );

    blocTest<AnalyticsBloc, AnalyticsState>(
      'emits [AnalyticsLoading, AnalyticsLoaded] when LoadAnalyticsEvent succeeds',
      build: () {
        when(() => mockCheckPermission(any()))
            .thenAnswer((_) async => const Right(true));
        when(() => mockGetUsageAnalytics(any()))
            .thenAnswer((_) async => const Right(testSummary));
        return bloc;
      },
      act: (b) => b.add(const LoadAnalyticsEvent(timeRange: AnalyticsTimeRange.week)),
      expect: () => [
        const AnalyticsLoading(),
        const AnalyticsLoaded(
          summary: testSummary,
          selectedRange: AnalyticsTimeRange.week,
        ),
      ],
    );

    blocTest<AnalyticsBloc, AnalyticsState>(
      'emits [AnalyticsLoading, AnalyticsPermissionRequired] when permission missing on LoadAnalyticsEvent',
      build: () {
        when(() => mockCheckPermission(any()))
            .thenAnswer((_) async => const Right(false));
        return bloc;
      },
      act: (b) => b.add(const LoadAnalyticsEvent()),
      expect: () => [
        const AnalyticsLoading(),
        const AnalyticsPermissionRequired(),
      ],
    );

    blocTest<AnalyticsBloc, AnalyticsState>(
      'emits [AnalyticsLoading, AnalyticsError] when GetUsageAnalytics fails',
      build: () {
        when(() => mockCheckPermission(any()))
            .thenAnswer((_) async => const Right(true));
        when(() => mockGetUsageAnalytics(any()))
            .thenAnswer((_) async => const Left(PlatformFailure('Native error')));
        return bloc;
      },
      act: (b) => b.add(const LoadAnalyticsEvent()),
      expect: () => [
        const AnalyticsLoading(),
        const AnalyticsError('Native error'),
      ],
    );
  });
}
