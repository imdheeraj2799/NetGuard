import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/error/failure.dart';
import 'package:net_guard/core/usecase/usecase.dart';
import 'package:net_guard/features/schedule/domain/entities/schedule_entity.dart';
import 'package:net_guard/features/schedule/domain/usecases/create_schedule_usecase.dart';
import 'package:net_guard/features/schedule/domain/usecases/delete_schedule_usecase.dart';
import 'package:net_guard/features/schedule/domain/usecases/get_schedules_usecase.dart';
import 'package:net_guard/features/schedule/domain/usecases/toggle_schedule_active_usecase.dart';
import 'package:net_guard/features/schedule/domain/usecases/update_schedule_usecase.dart';
import 'package:net_guard/features/schedule/presentation/bloc/schedule_bloc.dart';
import 'package:net_guard/features/schedule/presentation/bloc/schedule_event.dart';
import 'package:net_guard/features/schedule/presentation/bloc/schedule_state.dart';

class MockGetSchedulesUseCase extends Mock implements GetSchedulesUseCase {}
class MockCreateScheduleUseCase extends Mock implements CreateScheduleUseCase {}
class MockUpdateScheduleUseCase extends Mock implements UpdateScheduleUseCase {}
class MockDeleteScheduleUseCase extends Mock implements DeleteScheduleUseCase {}
class MockToggleScheduleActiveUseCase extends Mock
    implements ToggleScheduleActiveUseCase {}

void main() {
  late MockGetSchedulesUseCase mockGetSchedules;
  late MockCreateScheduleUseCase mockCreateSchedule;
  late MockUpdateScheduleUseCase mockUpdateSchedule;
  late MockDeleteScheduleUseCase mockDeleteSchedule;
  late MockToggleScheduleActiveUseCase mockToggleScheduleActive;

  const testNightSchedule = ScheduleEntity(
    id: 'night_sched',
    name: 'Night Restrictions',
    startTimeMinutes: 22 * 60, // 22:00
    endTimeMinutes: 7 * 60, // 07:00
    activeDays: [DateTime.monday, DateTime.tuesday],
    targetPackages: ['com.instagram.android'],
    isEnabled: true,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const CreateScheduleParams(testNightSchedule));
    registerFallbackValue(const UpdateScheduleParams(testNightSchedule));
    registerFallbackValue(const DeleteScheduleParams('id'));
    registerFallbackValue(
      const ToggleScheduleActiveParams(id: 'id', isEnabled: true),
    );
  });

  setUp(() {
    mockGetSchedules = MockGetSchedulesUseCase();
    mockCreateSchedule = MockCreateScheduleUseCase();
    mockUpdateSchedule = MockUpdateScheduleUseCase();
    mockDeleteSchedule = MockDeleteScheduleUseCase();
    mockToggleScheduleActive = MockToggleScheduleActiveUseCase();
  });

  ScheduleBloc buildBloc() {
    return ScheduleBloc(
      getSchedules: mockGetSchedules,
      createSchedule: mockCreateSchedule,
      updateSchedule: mockUpdateSchedule,
      deleteSchedule: mockDeleteSchedule,
      toggleScheduleActive: mockToggleScheduleActive,
      enableTimer: false,
    );
  }

  group('ScheduleBloc Tests', () {
    test('initial state is ScheduleInitial', () {
      expect(buildBloc().state, const ScheduleInitial());
    });

    blocTest<ScheduleBloc, ScheduleState>(
      'emits [ScheduleLoading, ScheduleLoaded] on successful LoadSchedulesEvent',
      build: () {
        when(() => mockGetSchedules(any()))
            .thenAnswer((_) async => const Right([testNightSchedule]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadSchedulesEvent()),
      expect: () => [
        const ScheduleLoading(),
        isA<ScheduleLoaded>()
            .having((s) => s.allSchedules.length, 'allSchedules.length', 1)
            .having((s) => s.allSchedules.first.id, 'first.id', 'night_sched'),
      ],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'emits [ScheduleLoading, ScheduleError] on failed LoadSchedulesEvent',
      build: () {
        when(() => mockGetSchedules(any()))
            .thenAnswer((_) async => const Left(CacheFailure('Failed to load')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadSchedulesEvent()),
      expect: () => [
        const ScheduleLoading(),
        const ScheduleError('Failed to load'),
      ],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'appends created schedule on CreateScheduleEvent',
      build: () {
        when(() => mockCreateSchedule(any()))
            .thenAnswer((_) async => const Right(testNightSchedule));
        return buildBloc();
      },
      seed: () => const ScheduleLoaded(
        allSchedules: [],
        activeSchedules: [],
        activeBlockedPackages: {},
      ),
      act: (bloc) => bloc.add(const CreateScheduleEvent(testNightSchedule)),
      expect: () => [
        isA<ScheduleLoaded>()
            .having((s) => s.allSchedules.length, 'allSchedules.length', 1),
      ],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'optimistically toggles schedule on ToggleScheduleEvent',
      build: () {
        when(() => mockToggleScheduleActive(any()))
            .thenAnswer((_) async => Right(testNightSchedule.copyWith(isEnabled: false)));
        return buildBloc();
      },
      seed: () => const ScheduleLoaded(
        allSchedules: [testNightSchedule],
        activeSchedules: [],
        activeBlockedPackages: {},
      ),
      act: (bloc) => bloc.add(
        const ToggleScheduleEvent(id: 'night_sched', isEnabled: false),
      ),
      expect: () => [
        isA<ScheduleLoaded>().having(
          (s) => s.allSchedules.first.isEnabled,
          'isEnabled',
          false,
        ),
      ],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'evaluates midnight crossover active window correctly on EvaluateSchedulesEvent',
      build: () => buildBloc(),
      seed: () => const ScheduleLoaded(
        allSchedules: [testNightSchedule],
        activeSchedules: [],
        activeBlockedPackages: {},
      ),
      act: (bloc) {
        // Monday night at 23:00 -> within 22:00 to 07:00 crossover
        final mondayNight = DateTime(2026, 3, 2, 23, 0);
        bloc.add(EvaluateSchedulesEvent(mondayNight));
      },
      expect: () => [
        isA<ScheduleLoaded>()
            .having((s) => s.activeSchedules.length, 'activeSchedules.length', 1)
            .having(
              (s) => s.isPackageBlocked('com.instagram.android'),
              'isPackageBlocked',
              true,
            ),
      ],
    );
  });
}
