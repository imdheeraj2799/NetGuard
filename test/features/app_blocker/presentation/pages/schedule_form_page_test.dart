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
import 'package:net_guard/features/app_blocker/presentation/bloc/schedule_bloc.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/schedule_event.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/schedule_state.dart';
import 'package:net_guard/features/app_blocker/presentation/pages/schedule_form_page.dart';

class MockScheduleBloc extends MockBloc<ScheduleEvent, ScheduleState>
    implements ScheduleBloc {}

class MockAppBlockerBloc extends MockBloc<AppBlockerEvent, AppBlockerState>
    implements AppBlockerBloc {}



void main() {
  late MockScheduleBloc scheduleBloc;
  late MockAppBlockerBloc appBloc;

  const testApps = [
    AppInfoEntity(
      appName: 'Social Chat',
      packageName: 'com.social.chat',
      isBlocked: false,
    ),
    AppInfoEntity(
      appName: 'News App',
      packageName: 'com.news.app',
      isBlocked: false,
    ),
  ];

  final fixedDate = DateTime(2026, 10, 21, 10, 0);
  final existingSchedule = BlockScheduleEntity(
    id: 's-edit',
    name: 'Study Time',
    packageNames: const ['com.social.chat'],
    recurrence: ScheduleRecurrence.weekdays,
    startHour: 18,
    startMinute: 0,
    endHour: 21,
    endMinute: 0,
    isEnabled: true,
    createdAt: fixedDate,
    updatedAt: fixedDate,
  );

  setUpAll(() {
    registerFallbackValue(const LoadSchedulesEvent());
  });

  setUp(() {
    scheduleBloc = MockScheduleBloc();
    appBloc = MockAppBlockerBloc();

    when(() => scheduleBloc.state).thenReturn(
      const ScheduleLoaded(schedules: []),
    );
    when(() => appBloc.state).thenReturn(
      const AppBlockerLoaded(
        originalApps: testApps,
        filteredApps: testApps,
      ),
    );
  });

  Widget buildTestWidget({BlockScheduleEntity? schedule}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ScheduleBloc>.value(value: scheduleBloc),
        BlocProvider<AppBlockerBloc>.value(value: appBloc),
      ],
      child: MaterialApp(
        home: ScheduleFormPage(existingSchedule: schedule),
      ),
    );
  }

  testWidgets('renders create schedule form with recurrence options and time tiles', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('New Block Schedule'), findsOneWidget);
    expect(find.text('SCHEDULE NAME'), findsOneWidget);
    expect(find.text('RECURRENCE'), findsOneWidget);
    expect(find.text('Every Day'), findsOneWidget);
    expect(find.text('Weekdays'), findsOneWidget);
    expect(find.text('Custom Days'), findsOneWidget);
    expect(find.text('One-Time'), findsOneWidget);
    expect(find.text('TIME RANGE'), findsOneWidget);
    expect(find.text('APPLICATIONS TO BLOCK'), findsOneWidget);
    expect(find.text('Create Schedule'), findsOneWidget);
  });

  testWidgets('validates that at least one application must be selected', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    // Tap save without selecting any apps
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Please select at least one application to block.'), findsOneWidget);
    verifyNever(() => scheduleBloc.add(any()));
  });

  testWidgets('pre-populates existing schedule and dispatches SaveScheduleEvent on save', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget(schedule: existingSchedule));

    expect(find.text('Edit Schedule'), findsOneWidget);
    expect(find.text('Study Time'), findsOneWidget);
    expect(find.text('Social Chat'), findsOneWidget); // Pre-selected app chip
    expect(find.text('Update Schedule'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pump();

    verify(() => scheduleBloc.add(any(that: isA<SaveScheduleEvent>()))).called(1);
  });

  testWidgets('switching recurrence to Custom Days shows weekday chips', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.text('Custom Days'));
    await tester.pump();

    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);
  });

  testWidgets('switching recurrence to One-Time shows date selection tile', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.text('One-Time'));
    await tester.pump();

    expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
  });

  testWidgets('displays error message via AppSnackBar on ScheduleError', (tester) async {
    whenListen(
      scheduleBloc,
      Stream.fromIterable([
        const ScheduleError(message: 'Conflicting schedule exists'),
      ]),
      initialState: const ScheduleInitial(),
    );

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    expect(find.text('Conflicting schedule exists'), findsOneWidget);
  });
}
