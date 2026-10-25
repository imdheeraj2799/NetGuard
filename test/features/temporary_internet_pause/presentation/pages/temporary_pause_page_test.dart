import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/features/app_blocker/domain/entities/app_info_entity.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/app_blocker_bloc.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/app_blocker_event.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/app_blocker_state.dart';
import 'package:net_guard/features/temporary_internet_pause/domain/entities/temporary_pause_entity.dart';
import 'package:net_guard/features/temporary_internet_pause/presentation/bloc/temporary_pause_bloc.dart';
import 'package:net_guard/features/temporary_internet_pause/presentation/bloc/temporary_pause_event.dart';
import 'package:net_guard/features/temporary_internet_pause/presentation/bloc/temporary_pause_state.dart';
import 'package:net_guard/features/temporary_internet_pause/presentation/pages/temporary_pause_page.dart';
import 'package:net_guard/features/temporary_internet_pause/presentation/widgets/active_pause_card.dart';
import 'package:net_guard/features/temporary_internet_pause/presentation/widgets/create_pause_dialog.dart';

class MockTemporaryPauseBloc
    extends MockBloc<TemporaryPauseEvent, TemporaryPauseState>
    implements TemporaryPauseBloc {}

class MockAppBlockerBloc extends MockBloc<AppBlockerEvent, AppBlockerState>
    implements AppBlockerBloc {}

void main() {
  late MockTemporaryPauseBloc mockPauseBloc;
  late MockAppBlockerBloc mockAppBlockerBloc;

  final now = DateTime(2026, 10, 23, 12, 0);
  final samplePause = TemporaryPauseEntity(
    id: 'pause-1',
    packageName: 'com.social.app',
    appName: 'Social Network',
    startTime: now,
    pauseUntil: now.add(const Duration(minutes: 30)),
    duration: const Duration(minutes: 30),
    isCustom: false,
  );

  setUp(() {
    mockPauseBloc = MockTemporaryPauseBloc();
    mockAppBlockerBloc = MockAppBlockerBloc();

    when(() => mockAppBlockerBloc.state).thenReturn(
      const AppBlockerLoaded(
        filteredApps: [
          AppInfoEntity(
            appName: 'Social Network',
            packageName: 'com.social.app',
            isBlocked: false,
          ),
        ],
        originalApps: [
          AppInfoEntity(
            appName: 'Social Network',
            packageName: 'com.social.app',
            isBlocked: false,
          ),
        ],
        searchQuery: '',
      ),
    );
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<TemporaryPauseBloc>.value(value: mockPauseBloc),
          BlocProvider<AppBlockerBloc>.value(value: mockAppBlockerBloc),
        ],
        child: const TemporaryPausePage(),
      ),
    );
  }

  testWidgets('renders loading indicator when state is TemporaryPauseLoading',
      (tester) async {
    when(() => mockPauseBloc.state)
        .thenReturn(const TemporaryPauseLoading());

    await tester.pumpWidget(buildTestWidget());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders empty state when active pauses list is empty',
      (tester) async {
    when(() => mockPauseBloc.state).thenReturn(
      const TemporaryPauseLoaded(pauses: []),
    );

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('No Active Pauses'), findsOneWidget);
    expect(find.text('Pause an App'), findsOneWidget);
    expect(find.byKey(const Key('add_temporary_pause_fab')), findsOneWidget);
  });

  testWidgets('renders active pause card when pauses exist', (tester) async {
    when(() => mockPauseBloc.state).thenReturn(
      TemporaryPauseLoaded(pauses: [samplePause]),
    );

    await tester.pumpWidget(buildTestWidget());

    expect(find.byType(ActivePauseCard), findsOneWidget);
    expect(find.text('Social Network'), findsOneWidget);
    expect(find.text('Cancel Pause'), findsOneWidget);
  });

  testWidgets('tapping refresh button dispatches LoadTemporaryPausesEvent',
      (tester) async {
    when(() => mockPauseBloc.state).thenReturn(
      const TemporaryPauseLoaded(pauses: []),
    );

    await tester.pumpWidget(buildTestWidget());

    final refreshButton = find.byTooltip('Refresh Active Pauses');
    expect(refreshButton, findsOneWidget);

    await tester.tap(refreshButton);
    await tester.pump();

    verify(() => mockPauseBloc.add(const LoadTemporaryPausesEvent())).called(1);
  });

  testWidgets(
      'shows success snackbar and dispatches ClearTemporaryPauseActionMessageEvent when actionMessage is received',
      (tester) async {
    whenListen(
      mockPauseBloc,
      Stream.fromIterable([
        TemporaryPauseLoaded(
          pauses: [samplePause],
          actionMessage: 'Paused internet access for Social Network',
        ),
      ]),
      initialState: const TemporaryPauseLoaded(pauses: []),
    );

    await tester.pumpWidget(buildTestWidget());
    await tester.pump(); // Process stream event and trigger listener

    expect(
      find.text('Paused internet access for Social Network'),
      findsOneWidget,
    );
    verify(() => mockPauseBloc.add(const ClearTemporaryPauseActionMessageEvent()))
        .called(1);
  });

  testWidgets(
      'tapping FAB opens CreatePauseDialog without any ListTile assertion exceptions',
      (tester) async {
    when(() => mockPauseBloc.state).thenReturn(
      const TemporaryPauseLoaded(pauses: []),
    );

    await tester.pumpWidget(buildTestWidget());

    final fab = find.byKey(const Key('add_temporary_pause_fab'));
    expect(fab, findsOneWidget);

    await tester.tap(fab);
    await tester.pumpAndSettle();

    expect(find.byType(CreatePauseDialog), findsOneWidget);
    expect(find.text('PAUSE DURATION'), findsOneWidget);
    expect(find.text('SELECT APPLICATION'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
