import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/features/app_blocker/domain/entities/app_info_entity.dart';
import 'package:net_guard/features/app_blocker/domain/entities/block_schedule_entity.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/app_blocker_bloc.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/app_blocker_event.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/app_blocker_state.dart';
import 'package:net_guard/features/app_blocker/presentation/pages/dashboard_page.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/schedule_bloc.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/schedule_event.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/schedule_state.dart';
import 'package:net_guard/features/app_blocker/presentation/widgets/app_card.dart';
import 'package:net_guard/features/temporary_internet_pause/domain/entities/temporary_pause_entity.dart';
import 'package:net_guard/features/temporary_internet_pause/presentation/bloc/temporary_pause_bloc.dart';
import 'package:net_guard/features/temporary_internet_pause/presentation/bloc/temporary_pause_event.dart';
import 'package:net_guard/features/temporary_internet_pause/presentation/bloc/temporary_pause_state.dart';

class MockAppBlockerBloc extends MockBloc<AppBlockerEvent, AppBlockerState>
    implements AppBlockerBloc {}

class MockScheduleBloc extends MockBloc<ScheduleEvent, ScheduleState>
    implements ScheduleBloc {}

class MockTemporaryPauseBloc
    extends MockBloc<TemporaryPauseEvent, TemporaryPauseState>
    implements TemporaryPauseBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(const LoadInstalledAppsEvent());
  });

  late MockAppBlockerBloc bloc;
  late MockScheduleBloc scheduleBloc;
  late MockTemporaryPauseBloc pauseBloc;

  const testApps = [
    AppInfoEntity(
      appName: 'Web Browser',
      packageName: 'com.browser.app',
      isBlocked: false,
    ),
    AppInfoEntity(
      appName: 'Social Chat',
      packageName: 'com.social.app',
      isBlocked: true,
    ),
  ];

  setUp(() {
    bloc = MockAppBlockerBloc();
    scheduleBloc = MockScheduleBloc();
    pauseBloc = MockTemporaryPauseBloc();
    when(() => scheduleBloc.state).thenReturn(const ScheduleInitial());
    when(() => pauseBloc.state)
        .thenReturn(const TemporaryPauseLoaded(pauses: []));
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AppBlockerBloc>.value(value: bloc),
          BlocProvider<ScheduleBloc>.value(value: scheduleBloc),
          BlocProvider<TemporaryPauseBloc>.value(value: pauseBloc),
        ],
        child: const DashboardPage(),
      ),
    );
  }

  testWidgets('renders loading indicator while loading installed apps', (tester) async {
    when(() => bloc.state).thenReturn(const AppBlockerLoading());

    await tester.pumpWidget(buildTestWidget());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading installed applications...'), findsOneWidget);
  });

  testWidgets('renders dashboard header, search bar, status cards, and app list', (tester) async {
    when(() => bloc.state).thenReturn(
      const AppBlockerLoaded(
        originalApps: testApps,
        filteredApps: testApps,
      ),
    );

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('NETGUARD'), findsOneWidget);
    expect(find.text('Firewall Dashboard'), findsOneWidget);
    expect(find.text('1 Blocked'), findsOneWidget);

    expect(find.text('INSTALLED'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('ALLOWED'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2)); // ALLOWED count 1 and BLOCKED count 1

    expect(find.byType(AppCard), findsNWidgets(2));
    expect(find.text('Web Browser'), findsOneWidget);
    expect(find.text('Social Chat'), findsOneWidget);
  });

  testWidgets('toggling switch dispatches ToggleAppBlockEvent', (tester) async {
    when(() => bloc.state).thenReturn(
      const AppBlockerLoaded(
        originalApps: testApps,
        filteredApps: testApps,
      ),
    );

    await tester.pumpWidget(buildTestWidget());

    // Toggle the first switch (Web Browser is allowed -> block it)
    final switches = find.byType(Switch);
    await tester.tap(switches.first);
    await tester.pump();

    verify(
      () => bloc.add(
        const ToggleAppBlockEvent(
          packageName: 'com.browser.app',
          isBlocked: true,
        ),
      ),
    ).called(1);
  });

  testWidgets('entering text in search bar dispatches SearchAppEvent', (tester) async {
    when(() => bloc.state).thenReturn(
      const AppBlockerLoaded(
        originalApps: testApps,
        filteredApps: testApps,
      ),
    );

    await tester.pumpWidget(buildTestWidget());

    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'browser');
    await tester.pump();

    verify(() => bloc.add(const SearchAppEvent('browser'))).called(1);
  });

  testWidgets('renders error message and retry button when state is AppBlockerError', (tester) async {
    when(() => bloc.state).thenReturn(
      const AppBlockerError('Failed to fetch installed apps'),
    );

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Failed to fetch installed apps'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    verify(() => bloc.add(const LoadInstalledAppsEvent())).called(1);
  });

  testWidgets('renders empty state when no apps match query', (tester) async {
    when(() => bloc.state).thenReturn(
      const AppBlockerLoaded(
        originalApps: testApps,
        filteredApps: [],
        searchQuery: 'nonexistent',
      ),
    );

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('No applications matching "nonexistent"'), findsOneWidget);
  });

  testWidgets('scrolling to bottom dispatches LoadMoreAppsEvent when hasReachedMax is false', (tester) async {
    final manyApps = List.generate(
      20,
      (i) => AppInfoEntity(
        appName: 'App $i',
        packageName: 'com.app.$i',
        isBlocked: false,
      ),
    );

    when(() => bloc.state).thenReturn(
      AppBlockerLoaded(
        originalApps: manyApps,
        filteredApps: manyApps,
        displayedApps: manyApps.take(15).toList(),
        page: 1,
        pageSize: 15,
        hasReachedMax: false,
      ),
    );

    await tester.pumpWidget(buildTestWidget());

    // Scroll down to the bottom
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pump();

    verify(() => bloc.add(const LoadMoreAppsEvent())).called(1);
  });

  testWidgets('renders active VPN status on dashboard', (tester) async {
    when(() => bloc.state).thenReturn(
      const AppBlockerLoaded(
        originalApps: testApps,
        filteredApps: testApps,
        vpnStatus: VpnStatus.active,
      ),
    );

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('VPN Status: '), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Enforcing firewall'), findsOneWidget);
    expect(find.text('1 Blocked'), findsOneWidget);
  });

  testWidgets('renders restarting VPN status and message', (tester) async {
    when(() => bloc.state).thenReturn(
      const AppBlockerLoaded(
        originalApps: testApps,
        filteredApps: testApps,
        vpnStatus: VpnStatus.restarting,
        vpnStatusReason: 'Attempting restart (1/3)...',
      ),
    );

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Firewall Protection: Restarting'), findsOneWidget);
    expect(find.text('Attempting restart (1/3)...'), findsOneWidget);
    expect(find.text('Restarting'), findsOneWidget);
  });

  testWidgets('renders inactive alert banner with Restore Protection button when apps are blocked', (tester) async {
    when(() => bloc.state).thenReturn(
      const AppBlockerLoaded(
        originalApps: testApps,
        filteredApps: testApps,
        vpnStatus: VpnStatus.inactive,
        vpnStatusReason: 'VPN permission revoked',
      ),
    );

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Firewall Protection: Inactive'), findsOneWidget);
    expect(find.text('VPN permission revoked'), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget); // Header badge shows Inactive, not Blocked!
    expect(find.text('Restore Protection'), findsOneWidget);

    await tester.tap(find.text('Restore Protection'));
    await tester.pump();

    verify(() => bloc.add(const RestartVpnEvent())).called(1);
  });

  testWidgets('does not show upper status loader or restarting card when all apps are unrestricted', (tester) async {
    const unblockedApps = [
      AppInfoEntity(
        appName: 'Web Browser',
        packageName: 'com.browser.app',
        isBlocked: false,
      ),
      AppInfoEntity(
        appName: 'Social Chat',
        packageName: 'com.social.app',
        isBlocked: false,
      ),
    ];

    when(() => bloc.state).thenReturn(
      const AppBlockerLoaded(
        originalApps: unblockedApps,
        filteredApps: unblockedApps,
        vpnStatus: VpnStatus.restarting,
        hasReachedMax: true,
      ),
    );

    await tester.pumpWidget(buildTestWidget());

    // Should not show restarting firewall banner or loader
    expect(find.text('Firewall Protection: Restarting'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('VPN Status: '), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);
    expect(find.text('Idle'), findsOneWidget);
    expect(find.text('Active'), findsNothing);
  });

  testWidgets('renders VPN Status: Inactive when all apps are unblocked even if vpnStatus is active', (tester) async {
    const unblockedApps = [
      AppInfoEntity(
        appName: 'Web Browser',
        packageName: 'com.browser.app',
        isBlocked: false,
      ),
    ];

    when(() => bloc.state).thenReturn(
      const AppBlockerLoaded(
        originalApps: unblockedApps,
        filteredApps: unblockedApps,
        vpnStatus: VpnStatus.active,
        hasReachedMax: true,
      ),
    );

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('VPN Status: '), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);
    expect(find.text('Idle'), findsOneWidget);
    expect(find.text('Active'), findsNothing);
    expect(find.text('All Allowed'), findsOneWidget);
  });

  testWidgets('shows schedule-armed subtitle when VPN inactive but enabled schedules exist', (tester) async {
    final testSchedule = BlockScheduleEntity(
      id: 's-1',
      name: 'Work',
      packageNames: const ['com.social.app'],
      recurrence: ScheduleRecurrence.weekdays,
      startHour: 9,
      startMinute: 0,
      endHour: 17,
      endMinute: 0,
      isEnabled: true,
      createdAt: DateTime(2026, 10, 21),
      updatedAt: DateTime(2026, 10, 21),
    );

    const unblockedApps = [
      AppInfoEntity(
        appName: 'Web Browser',
        packageName: 'com.browser.app',
        isBlocked: false,
      ),
      AppInfoEntity(
        appName: 'Social Chat',
        packageName: 'com.social.app',
        isBlocked: false,
      ),
    ];

    when(() => scheduleBloc.state).thenReturn(
      ScheduleLoaded(schedules: [testSchedule]),
    );
    when(() => bloc.state).thenReturn(
      const AppBlockerLoaded(
        originalApps: unblockedApps,
        filteredApps: unblockedApps,
        vpnStatus: VpnStatus.inactive,
        hasReachedMax: true,
      ),
    );

    await tester.pumpWidget(buildTestWidget());

    // VPN should still show as Inactive (not Active)
    expect(find.text('VPN Status: '), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);

    // Subtitle must reflect that 1 schedule is armed
    expect(find.text('1 Schedule Armed'), findsOneWidget);

    // Must NOT say 'Idle' or 'Enforcing firewall'
    expect(find.text('Idle'), findsNothing);
    expect(find.text('Enforcing firewall'), findsNothing);
    expect(find.text('Active'), findsNothing);
  });

  testWidgets('renders Add Schedule (+) button on dashboard', (tester) async {
    when(() => bloc.state).thenReturn(
      const AppBlockerLoaded(
        originalApps: testApps,
        filteredApps: testApps,
      ),
    );

    await tester.pumpWidget(buildTestWidget());

    expect(find.byKey(const Key('add_schedule_button')), findsOneWidget);
    expect(find.text('Add Schedule (+)'), findsOneWidget);
    expect(find.byKey(const Key('header_schedules_button')), findsOneWidget);
  });

  testWidgets('displays compact dialogue when tapping scheduled app card or toggle and does not toggle block status', (tester) async {
    const scheduledApp = AppInfoEntity(
      appName: 'Scheduled Streamer',
      packageName: 'com.scheduled.streamer',
      isBlocked: true,
      isSchedulePart: true,
      whichSchedule: 'Night Restrict',
    );

    when(() => bloc.state).thenReturn(
      const AppBlockerLoaded(
        originalApps: [scheduledApp],
        filteredApps: [scheduledApp],
        hasReachedMax: true,
      ),
    );

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Scheduled Streamer'), findsOneWidget);
    expect(find.text('Night Restrict'), findsOneWidget);

    // Tap the switch
    final switchFinder = find.byKey(const Key('app_card_toggle_com.scheduled.streamer'));
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Verify dialog appears with exact required text
    expect(
      find.text("This application is part of a schedule, so you can't enable or disable it manually."),
      findsOneWidget,
    );
    expect(find.text('Schedule Restricted'), findsOneWidget);
    expect(find.text('Assigned to: Night Restrict'), findsOneWidget);

    // Verify dialog has only OK button and no Cancel button
    expect(find.text('OK'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);

    // Tap OK to close dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Dialog is dismissed
    expect(
      find.text("This application is part of a schedule, so you can't enable or disable it manually."),
      findsNothing,
    );

    // Now tap the card itself
    await tester.tap(find.text('Scheduled Streamer'));
    await tester.pumpAndSettle();

    expect(
      find.text("This application is part of a schedule, so you can't enable or disable it manually."),
      findsOneWidget,
    );

    // Ensure ToggleAppBlockEvent was never called
    verifyNever(() => bloc.add(any(that: isA<ToggleAppBlockEvent>())));
  });

  testWidgets(
      'displays temporary pause dialogue when tapping temporarily paused app card or toggle and does not toggle block status',
      (tester) async {
    const pausedApp = AppInfoEntity(
      appName: 'Paused Video Player',
      packageName: 'com.paused.videoplayer',
      isBlocked: false,
    );

    final pause = TemporaryPauseEntity(
      id: 'pause-test-1',
      packageName: 'com.paused.videoplayer',
      appName: 'Paused Video Player',
      startTime: DateTime.now(),
      pauseUntil: DateTime.now().add(const Duration(minutes: 15)),
      duration: const Duration(minutes: 15),
      isCustom: false,
    );

    when(() => bloc.state).thenReturn(
      const AppBlockerLoaded(
        originalApps: [pausedApp],
        filteredApps: [pausedApp],
        hasReachedMax: true,
      ),
    );
    when(() => pauseBloc.state).thenReturn(
      TemporaryPauseLoaded(pauses: [pause]),
    );

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Paused Video Player'), findsOneWidget);
    expect(find.text('Temporarily Paused'), findsOneWidget);

    // Tap the switch
    final switchFinder =
        find.byKey(const Key('app_card_toggle_com.paused.videoplayer'));
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Verify dialog appears with exact required text
    expect(
      find.text(
          "Internet access for this application is temporarily paused, so you can't enable or disable it manually."),
      findsOneWidget,
    );
    expect(find.text('Temporary Pause Active'), findsOneWidget);

    // Verify dialog has OK button
    expect(find.text('OK'), findsOneWidget);

    // Tap OK to close dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Dialog is dismissed
    expect(
      find.text(
          "Internet access for this application is temporarily paused, so you can't enable or disable it manually."),
      findsNothing,
    );

    // Now tap the card itself
    await tester.tap(find.text('Paused Video Player'));
    await tester.pumpAndSettle();

    expect(
      find.text(
          "Internet access for this application is temporarily paused, so you can't enable or disable it manually."),
      findsOneWidget,
    );

    // Ensure ToggleAppBlockEvent was never called
    verifyNever(() => bloc.add(any(that: isA<ToggleAppBlockEvent>())));
  });
}
