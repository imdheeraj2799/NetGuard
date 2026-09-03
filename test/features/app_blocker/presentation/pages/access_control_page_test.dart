import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/theme/app_theme.dart';
import 'package:net_guard/features/app_blocker/domain/entities/app_info_entity.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/app_blocker_bloc.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/app_blocker_state.dart';
import 'package:net_guard/features/app_blocker/presentation/pages/access_control_page.dart';
import 'package:net_guard/features/domain_filter/domain/entities/blocked_domain_entity.dart';
import 'package:net_guard/features/domain_filter/presentation/bloc/domain_filter_bloc.dart';
import 'package:net_guard/features/domain_filter/presentation/bloc/domain_filter_state.dart';
import 'package:net_guard/features/schedule/domain/entities/schedule_entity.dart';
import 'package:net_guard/features/schedule/presentation/bloc/schedule_bloc.dart';
import 'package:net_guard/features/schedule/presentation/bloc/schedule_state.dart';

class MockAppBlockerBloc extends Mock implements AppBlockerBloc {}

class MockDomainFilterBloc extends Mock implements DomainFilterBloc {}

class MockScheduleBloc extends Mock implements ScheduleBloc {}

void main() {
  late MockAppBlockerBloc appBloc;
  late MockDomainFilterBloc domainBloc;
  late MockScheduleBloc scheduleBloc;

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

  final testDomains = [
    BlockedDomainEntity(
      id: 'd_1',
      domain: 'youtube.com',
      isBlocked: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    BlockedDomainEntity(
      id: 'd_2',
      domain: 'netflix.com',
      isBlocked: false,
      createdAt: DateTime(2026, 1, 2),
    ),
  ];

  const testSchedules = [
    ScheduleEntity(
      id: 's_night',
      name: 'Night Restrictions',
      startTimeMinutes: 1320,
      endTimeMinutes: 420,
      activeDays: [1, 2, 3, 4, 5, 6, 7],
      targetPackages: ['com.instagram.android'],
      isEnabled: true,
    ),
  ];

  setUp(() {
    appBloc = MockAppBlockerBloc();
    domainBloc = MockDomainFilterBloc();
    scheduleBloc = MockScheduleBloc();

    when(() => appBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => appBloc.state).thenReturn(
      const AppBlockerLoaded(originalApps: testApps, filteredApps: testApps),
    );

    when(() => domainBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => domainBloc.state).thenReturn(
      DomainFilterLoaded(allDomains: testDomains, filteredDomains: testDomains),
    );

    when(() => scheduleBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => scheduleBloc.state).thenReturn(
      const ScheduleLoaded(
        allSchedules: testSchedules,
        activeSchedules: testSchedules,
        activeBlockedPackages: {'com.instagram.android'},
      ),
    );
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AppBlockerBloc>.value(value: appBloc),
          BlocProvider<DomainFilterBloc>.value(value: domainBloc),
          BlocProvider<ScheduleBloc>.value(value: scheduleBloc),
        ],
        child: const AccessControlPage(),
      ),
    );
  }

  testWidgets('AccessControlPage renders header, rules, domains, and actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget());

    expect(find.text('NETGATE // SHIELD'), findsOneWidget);
    expect(find.text('Access Control'), findsOneWidget);
    expect(find.text('ACTIVE FILTERS'), findsOneWidget);
    expect(find.text('DORMANT'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('Discord'), findsOneWidget);
    expect(find.text('youtube.com'), findsOneWidget);
    expect(find.text('netflix.com'), findsOneWidget);
    expect(find.text('Night Restrictions'), findsOneWidget);
    expect(find.text('More Options'), findsOneWidget);
  });

  testWidgets('Tapping Block Installed Applications in bottomsheet navigates without bloc error', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget());

    // Tap More Options to open bottomsheet
    await tester.tap(find.text('More Options'));
    await tester.pumpAndSettle();

    expect(find.text('Create Time-Based Schedule'), findsOneWidget);
    expect(find.text('Block Installed Applications'), findsOneWidget);

    // Tap Block Installed Applications
    await tester.tap(find.text('Block Installed Applications'));
    await tester.pumpAndSettle();

    // Verify AppDiscoveryPage is rendered without errors
    expect(find.text('NETGATE // DISCOVERY'), findsOneWidget);
    expect(find.text('App & Site Discovery'), findsOneWidget);
  });

  testWidgets('Tapping Create Time-Based Schedule opens schedule dialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget());

    await tester.tap(find.text('More Options'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Time-Based Schedule'));
    await tester.pumpAndSettle();

    expect(find.text('WEAVE TIME SCHEDULE'), findsOneWidget);
    expect(find.text('START TIME'), findsOneWidget);
    expect(find.text('END TIME'), findsOneWidget);
    expect(find.text('ACTIVE DAYS'), findsOneWidget);
  });
}
