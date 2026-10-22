import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/features/app_blocker/domain/entities/block_schedule_entity.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/schedule_bloc.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/schedule_event.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/schedule_state.dart';
import 'package:net_guard/features/app_blocker/presentation/pages/schedule_list_page.dart';
import 'package:net_guard/features/app_blocker/presentation/widgets/schedule_card.dart';

class MockScheduleBloc extends MockBloc<ScheduleEvent, ScheduleState>
    implements ScheduleBloc {}

void main() {
  late MockScheduleBloc bloc;

  final fixedDate = DateTime(2026, 10, 21, 10, 0);
  final sampleSchedule = BlockScheduleEntity(
    id: 's-1',
    name: 'Work Focus',
    packageNames: const ['com.work.app'],
    recurrence: ScheduleRecurrence.weekdays,
    startHour: 9,
    startMinute: 0,
    endHour: 17,
    endMinute: 0,
    isEnabled: true,
    createdAt: fixedDate,
    updatedAt: fixedDate,
  );

  setUp(() {
    bloc = MockScheduleBloc();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: BlocProvider<ScheduleBloc>.value(
        value: bloc,
        child: const ScheduleListPage(),
      ),
    );
  }

  testWidgets('renders loading indicator when state is ScheduleLoading', (tester) async {
    when(() => bloc.state).thenReturn(const ScheduleLoading());

    await tester.pumpWidget(buildTestWidget());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders empty state when schedules list is empty', (tester) async {
    when(() => bloc.state).thenReturn(
      const ScheduleLoaded(schedules: []),
    );

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('No Block Schedules Configured'), findsOneWidget);
    expect(find.text('Add Schedule'), findsNWidgets(2)); // FAB + Empty state button
  });

  testWidgets('renders schedule list and cards when schedules exist', (tester) async {
    when(() => bloc.state).thenReturn(
      ScheduleLoaded(schedules: [sampleSchedule]),
    );

    await tester.pumpWidget(buildTestWidget());

    expect(find.byType(ScheduleCard), findsOneWidget);
    expect(find.text('Work Focus'), findsOneWidget);
    expect(find.text('Weekdays (Mon–Fri)'), findsOneWidget);
  });

  testWidgets('renders exact alarm restriction banner when capability is false', (tester) async {
    when(() => bloc.state).thenReturn(
      ScheduleLoaded(
        schedules: [sampleSchedule],
        canScheduleExactAlarms: false,
      ),
    );

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Exact Alarms Restricted'), findsOneWidget);
    expect(find.text('Enable'), findsOneWidget);

    await tester.tap(find.text('Enable'));
    await tester.pump();

    verify(() => bloc.add(const RequestExactAlarmPermissionEvent())).called(1);
  });

  testWidgets('deleting a schedule shows confirmation dialog and dispatches event on confirm', (tester) async {
    when(() => bloc.state).thenReturn(
      ScheduleLoaded(schedules: [sampleSchedule]),
    );

    await tester.pumpWidget(buildTestWidget());

    final deleteIcon = find.byIcon(Icons.delete_outline_rounded);
    await tester.tap(deleteIcon);
    await tester.pumpAndSettle();

    expect(find.text('Delete Schedule?'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    verify(() => bloc.add(const DeleteScheduleEvent('s-1'))).called(1);
  });

  testWidgets('renders actionMessage via AppSnackBar on ScheduleLoaded', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable([
        ScheduleLoaded(
          schedules: [sampleSchedule],
          actionMessage: 'Schedule deleted',
        ),
      ]),
      initialState: ScheduleLoaded(schedules: [sampleSchedule]),
    );

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    expect(find.text('Schedule deleted'), findsOneWidget);
  });
}
