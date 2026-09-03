import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/theme/app_theme.dart';
import 'package:net_guard/features/analytics/domain/entities/analytics_summary_entity.dart';
import 'package:net_guard/features/analytics/domain/entities/analytics_time_range.dart';
import 'package:net_guard/features/analytics/domain/entities/app_usage_entity.dart';
import 'package:net_guard/features/analytics/presentation/bloc/analytics_bloc.dart';
import 'package:net_guard/features/analytics/presentation/bloc/analytics_state.dart';
import 'package:net_guard/features/app_blocker/domain/entities/app_info_entity.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/app_blocker_bloc.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/app_blocker_state.dart';
import 'package:net_guard/features/app_blocker/presentation/pages/app_discovery_page.dart';
import 'package:net_guard/features/app_blocker/presentation/pages/shield_settings_page.dart';
import 'package:net_guard/features/app_blocker/presentation/pages/usage_statistics_page.dart';
import 'package:net_guard/features/security/domain/entities/security_settings_entity.dart';
import 'package:net_guard/features/security/presentation/bloc/auth_bloc.dart';
import 'package:net_guard/features/security/presentation/bloc/auth_state.dart';
import 'package:net_guard/features/system_controls/domain/entities/dns_resolver_entity.dart';
import 'package:net_guard/features/system_controls/presentation/bloc/system_controls_bloc.dart';
import 'package:net_guard/features/system_controls/presentation/bloc/system_controls_state.dart';

class MockAppBlockerBloc extends Mock implements AppBlockerBloc {}

class MockAnalyticsBloc extends Mock implements AnalyticsBloc {}

class MockAuthBloc extends Mock implements AuthBloc {}

class MockSystemControlsBloc extends Mock implements SystemControlsBloc {}

void main() {
  late MockAppBlockerBloc bloc;
  late MockAnalyticsBloc analyticsBloc;
  late MockAuthBloc authBloc;
  late MockSystemControlsBloc systemControlsBloc;

  const testApps = [
    AppInfoEntity(
      appName: 'Instagram',
      packageName: 'com.instagram.android',
      isBlocked: true,
    ),
    AppInfoEntity(
      appName: 'Discord',
      packageName: 'com.discord',
      isBlocked: false,
    ),
  ];

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

  setUp(() {
    bloc = MockAppBlockerBloc();
    analyticsBloc = MockAnalyticsBloc();
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => bloc.state).thenReturn(
      const AppBlockerLoaded(originalApps: testApps, filteredApps: testApps),
    );
    when(() => analyticsBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => analyticsBloc.state).thenReturn(
      const AnalyticsLoaded(
        summary: testSummary,
        selectedRange: AnalyticsTimeRange.week,
      ),
    );

    authBloc = MockAuthBloc();
    when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => authBloc.state).thenReturn(
      const AuthSuccess(
        settings: SecuritySettingsEntity(
          isBiometricsEnabled: false,
          hasMasterPasscode: false,
        ),
      ),
    );

    systemControlsBloc = MockSystemControlsBloc();
    when(() => systemControlsBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => systemControlsBloc.state).thenReturn(
      const SystemControlsLoaded(
        currentResolver: DnsResolverEntity.cloudflare,
        availableResolvers: DnsResolverEntity.predefined,
      ),
    );
  });

  testWidgets('AppDiscoveryPage renders search, installed apps, and apply button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: BlocProvider<AppBlockerBloc>.value(
          value: bloc,
          child: const AppDiscoveryPage(),
        ),
      ),
    );

    expect(find.text('NETGATE // DISCOVERY'), findsOneWidget);
    expect(find.text('App & Site Discovery'), findsOneWidget);
    expect(find.text('INSTALLED APPLICATIONS'), findsOneWidget);
    expect(find.text('FREQUENTLY VISITED'), findsOneWidget);
    expect(find.text('APPLY SELECTION'), findsOneWidget);
  });

  testWidgets('UsageStatisticsPage renders metrics, chart, and top apps', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AnalyticsBloc>.value(
          value: analyticsBloc,
          child: const UsageStatisticsPage(),
        ),
      ),
    );

    expect(find.text('NETGATE // ANALYTICS'), findsOneWidget);
    expect(find.text('Usage Statistics'), findsOneWidget);
    expect(find.text('TOTAL TIME'), findsOneWidget);
    expect(find.text('DATA USED'), findsOneWidget);
    expect(find.text('WEEKLY ACTIVITY'), findsOneWidget);
    expect(find.text('TOP APPLICATIONS'), findsOneWidget);
  });

  testWidgets('ShieldSettingsPage renders sections and protocol footer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<SystemControlsBloc>.value(value: systemControlsBloc),
          ],
          child: const ShieldSettingsPage(),
        ),
      ),
    );

    expect(find.text('NETGATE // SECURITY'), findsOneWidget);
    expect(find.text('Shield Settings'), findsOneWidget);
    expect(find.text('ACCESS CONTROL'), findsOneWidget);
    expect(find.text('NETWORK & PRIVACY'), findsOneWidget);
    expect(find.text('SYSTEM'), findsOneWidget);
    expect(find.text('ENCRYPTED END-TO-END'), findsOneWidget);
  });
}
