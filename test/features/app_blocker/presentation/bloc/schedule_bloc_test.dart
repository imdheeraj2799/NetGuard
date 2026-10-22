import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/error/failure.dart';
import 'package:net_guard/core/usecase/usecase.dart';
import 'package:net_guard/features/app_blocker/domain/entities/block_schedule_entity.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/can_schedule_exact_alarms_usecase.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/delete_schedule_usecase.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/get_assigned_packages_usecase.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/get_schedules_usecase.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/request_exact_alarm_permission_usecase.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/save_schedule_usecase.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/toggle_schedule_usecase.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/schedule_bloc.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/schedule_event.dart';
import 'package:net_guard/features/app_blocker/presentation/bloc/schedule_state.dart';

class MockGetSchedulesUseCase extends Mock implements GetSchedulesUseCase {}
class MockSaveScheduleUseCase extends Mock implements SaveScheduleUseCase {}
class MockDeleteScheduleUseCase extends Mock implements DeleteScheduleUseCase {}
class MockToggleScheduleUseCase extends Mock implements ToggleScheduleUseCase {}
class MockGetAssignedPackagesUseCase extends Mock implements GetAssignedPackagesUseCase {}
class MockCanScheduleExactAlarmsUseCase extends Mock implements CanScheduleExactAlarmsUseCase {}
class MockRequestExactAlarmPermissionUseCase extends Mock implements RequestExactAlarmPermissionUseCase {}

class FakeSaveScheduleParams extends Fake implements SaveScheduleParams {}
class FakeDeleteScheduleParams extends Fake implements DeleteScheduleParams {}
class FakeToggleScheduleParams extends Fake implements ToggleScheduleParams {}
class FakeGetAssignedPackagesParams extends Fake implements GetAssignedPackagesParams {}

void main() {
  late MockGetSchedulesUseCase mockGetSchedules;
  late MockSaveScheduleUseCase mockSaveSchedule;
  late MockDeleteScheduleUseCase mockDeleteSchedule;
  late MockToggleScheduleUseCase mockToggleSchedule;
  late MockGetAssignedPackagesUseCase mockGetAssignedPackages;
  late MockCanScheduleExactAlarmsUseCase mockCanScheduleExactAlarms;
  late MockRequestExactAlarmPermissionUseCase mockRequestExactAlarmPermission;
  late ScheduleBloc bloc;

  final fixedDate = DateTime(2026, 10, 21, 10, 0);
  final sampleSchedule = BlockScheduleEntity(
    id: 's-1',
    name: 'Work',
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

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(FakeSaveScheduleParams());
    registerFallbackValue(FakeDeleteScheduleParams());
    registerFallbackValue(FakeToggleScheduleParams());
    registerFallbackValue(FakeGetAssignedPackagesParams());
  });

  setUp(() {
    mockGetSchedules = MockGetSchedulesUseCase();
    mockSaveSchedule = MockSaveScheduleUseCase();
    mockDeleteSchedule = MockDeleteScheduleUseCase();
    mockToggleSchedule = MockToggleScheduleUseCase();
    mockGetAssignedPackages = MockGetAssignedPackagesUseCase();
    mockCanScheduleExactAlarms = MockCanScheduleExactAlarmsUseCase();
    mockRequestExactAlarmPermission = MockRequestExactAlarmPermissionUseCase();

    when(() => mockCanScheduleExactAlarms(any()))
        .thenAnswer((_) async => const Right(true));
    when(() => mockGetAssignedPackages(any()))
        .thenAnswer((_) async => const Right({'com.work.app': 'Work'}));

    bloc = ScheduleBloc(
      getSchedules: mockGetSchedules,
      saveSchedule: mockSaveSchedule,
      deleteSchedule: mockDeleteSchedule,
      toggleSchedule: mockToggleSchedule,
      getAssignedPackages: mockGetAssignedPackages,
      canScheduleExactAlarms: mockCanScheduleExactAlarms,
      requestExactAlarmPermission: mockRequestExactAlarmPermission,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('ScheduleBloc - LoadSchedulesEvent', () {
    blocTest<ScheduleBloc, ScheduleState>(
      'emits ScheduleLoading then ScheduleLoaded when load succeeds',
      build: () {
        when(() => mockGetSchedules(any()))
            .thenAnswer((_) async => Right([sampleSchedule]));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadSchedulesEvent()),
      expect: () => [
        const ScheduleLoading(),
        ScheduleLoaded(
          schedules: [sampleSchedule],
          assignedPackages: const {'com.work.app': 'Work'},
          canScheduleExactAlarms: true,
        ),
      ],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'emits ScheduleLoading then ScheduleError when load fails',
      build: () {
        when(() => mockGetSchedules(any()))
            .thenAnswer((_) async => const Left(CacheFailure('Failed to load')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadSchedulesEvent()),
      expect: () => [
        const ScheduleLoading(),
        const ScheduleError(
          message: 'Failed to load',
          canScheduleExactAlarms: true,
        ),
      ],
    );
  });

  group('ScheduleBloc - SaveScheduleEvent', () {
    blocTest<ScheduleBloc, ScheduleState>(
      'emits ScheduleLoaded with actionMessage when save succeeds',
      build: () {
        when(() => mockSaveSchedule(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockGetSchedules(any()))
            .thenAnswer((_) async => Right([sampleSchedule]));
        return bloc;
      },
      act: (bloc) => bloc.add(SaveScheduleEvent(sampleSchedule)),
      expect: () => [
        ScheduleLoaded(
          schedules: [sampleSchedule],
          assignedPackages: const {'com.work.app': 'Work'},
          canScheduleExactAlarms: true,
          actionMessage: 'Schedule "Work" saved successfully',
        ),
      ],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'emits ScheduleError when save returns ValidationFailure',
      build: () {
        when(() => mockSaveSchedule(any()))
            .thenAnswer((_) async => const Left(ValidationFailure('Conflict with existing schedule')));
        return bloc;
      },
      act: (bloc) => bloc.add(SaveScheduleEvent(sampleSchedule)),
      expect: () => [
        const ScheduleError(
          message: 'Conflict with existing schedule',
          schedules: [],
          assignedPackages: {},
          canScheduleExactAlarms: true,
        ),
      ],
    );
  });

  group('ScheduleBloc - DeleteScheduleEvent', () {
    blocTest<ScheduleBloc, ScheduleState>(
      'emits ScheduleLoaded with actionMessage when delete succeeds',
      build: () {
        when(() => mockDeleteSchedule(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockGetSchedules(any()))
            .thenAnswer((_) async => const Right([]));
        when(() => mockGetAssignedPackages(any()))
            .thenAnswer((_) async => const Right({}));
        return bloc;
      },
      act: (bloc) => bloc.add(const DeleteScheduleEvent('s-1')),
      expect: () => [
        const ScheduleLoaded(
          schedules: [],
          assignedPackages: {},
          canScheduleExactAlarms: true,
          actionMessage: 'Schedule deleted',
        ),
      ],
    );
  });

  group('ScheduleBloc - ToggleScheduleEvent', () {
    blocTest<ScheduleBloc, ScheduleState>(
      'emits ScheduleLoaded without actionMessage on toggle success',
      build: () {
        when(() => mockToggleSchedule(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockGetSchedules(any()))
            .thenAnswer((_) async => Right([sampleSchedule]));
        return bloc;
      },
      act: (bloc) => bloc.add(const ToggleScheduleEvent(id: 's-1', isEnabled: false)),
      expect: () => [
        ScheduleLoaded(
          schedules: [sampleSchedule],
          assignedPackages: const {'com.work.app': 'Work'},
          canScheduleExactAlarms: true,
        ),
      ],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'emits ScheduleError on toggle conflict validation failure',
      build: () {
        when(() => mockToggleSchedule(any()))
            .thenAnswer((_) async => const Left(ValidationFailure('Cannot enable: conflicts with other schedule')));
        return bloc;
      },
      act: (bloc) => bloc.add(const ToggleScheduleEvent(id: 's-1', isEnabled: true)),
      expect: () => [
        const ScheduleError(
          message: 'Cannot enable: conflicts with other schedule',
          schedules: [],
          assignedPackages: {},
          canScheduleExactAlarms: true,
        ),
      ],
    );
  });

  group('ScheduleBloc - RequestExactAlarmPermissionEvent', () {
    blocTest<ScheduleBloc, ScheduleState>(
      'requests permission and updates capability in state',
      seed: () => ScheduleLoaded(
        schedules: [sampleSchedule],
        canScheduleExactAlarms: false,
      ),
      build: () {
        when(() => mockRequestExactAlarmPermission(any()))
            .thenAnswer((_) async => const Right(true));
        when(() => mockCanScheduleExactAlarms(any()))
            .thenAnswer((_) async => const Right(true));
        return bloc;
      },
      act: (bloc) => bloc.add(const RequestExactAlarmPermissionEvent()),
      expect: () => [
        ScheduleLoaded(
          schedules: [sampleSchedule],
          canScheduleExactAlarms: true,
        ),
      ],
    );
  });
}
