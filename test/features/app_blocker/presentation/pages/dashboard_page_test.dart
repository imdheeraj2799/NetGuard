import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/features/app_blocker/domain/entities/app_info_entity.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/app_blocker_bloc.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/app_blocker_event.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/app_blocker_state.dart';
import 'package:net_guard/features/app_blocker/presentation/pages/dashboard_page.dart';
import 'package:net_guard/features/app_blocker/presentation/widgets/app_card.dart';

class MockAppBlockerBloc extends MockBloc<AppBlockerEvent, AppBlockerState>
    implements AppBlockerBloc {}

void main() {
  late MockAppBlockerBloc bloc;

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
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: BlocProvider<AppBlockerBloc>.value(
        value: bloc,
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
}
