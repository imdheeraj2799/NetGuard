import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/error/failure.dart';
import 'package:net_guard/core/usecase/usecase.dart';
import 'package:net_guard/features/schedule/domain/entities/schedule_entity.dart';
import 'package:net_guard/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:net_guard/features/schedule/domain/usecases/create_schedule_usecase.dart';
import 'package:net_guard/features/schedule/domain/usecases/delete_schedule_usecase.dart';
import 'package:net_guard/features/schedule/domain/usecases/get_schedules_usecase.dart';
import 'package:net_guard/features/schedule/domain/usecases/toggle_schedule_active_usecase.dart';
import 'package:net_guard/features/schedule/domain/usecases/update_schedule_usecase.dart';

class MockScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  late MockScheduleRepository repository;
  late GetSchedulesUseCase getSchedulesUseCase;
  late CreateScheduleUseCase createScheduleUseCase;
  late UpdateScheduleUseCase updateScheduleUseCase;
  late DeleteScheduleUseCase deleteScheduleUseCase;
  late ToggleScheduleActiveUseCase toggleScheduleActiveUseCase;

  const testSchedule = ScheduleEntity(
    id: 's_1',
    name: 'Night Restrictions',
    startTimeMinutes: 1320,
    endTimeMinutes: 420,
    activeDays: [1, 2, 3, 4, 5],
    targetPackages: ['com.instagram.android'],
    isEnabled: true,
  );

  setUp(() {
    repository = MockScheduleRepository();
    getSchedulesUseCase = GetSchedulesUseCase(repository);
    createScheduleUseCase = CreateScheduleUseCase(repository);
    updateScheduleUseCase = UpdateScheduleUseCase(repository);
    deleteScheduleUseCase = DeleteScheduleUseCase(repository);
    toggleScheduleActiveUseCase = ToggleScheduleActiveUseCase(repository);
  });

  group('GetSchedulesUseCase', () {
    test('returns list of schedules from repository', () async {
      when(() => repository.getSchedules())
          .thenAnswer((_) async => const Right([testSchedule]));

      final result = await getSchedulesUseCase(const NoParams());

      expect(result, const Right([testSchedule]));
      verify(() => repository.getSchedules()).called(1);
    });

    test('returns failure from repository on error', () async {
      when(() => repository.getSchedules())
          .thenAnswer((_) async => const Left(CacheFailure('Cache error')));

      final result = await getSchedulesUseCase(const NoParams());

      expect(result, const Left(CacheFailure('Cache error')));
    });
  });

  group('CreateScheduleUseCase', () {
    test('delegates schedule creation to repository', () async {
      when(() => repository.createSchedule(testSchedule))
          .thenAnswer((_) async => const Right(testSchedule));

      final result =
          await createScheduleUseCase(const CreateScheduleParams(testSchedule));

      expect(result, const Right(testSchedule));
      verify(() => repository.createSchedule(testSchedule)).called(1);
    });
  });

  group('UpdateScheduleUseCase', () {
    test('delegates schedule update to repository', () async {
      when(() => repository.updateSchedule(testSchedule))
          .thenAnswer((_) async => const Right(testSchedule));

      final result =
          await updateScheduleUseCase(const UpdateScheduleParams(testSchedule));

      expect(result, const Right(testSchedule));
      verify(() => repository.updateSchedule(testSchedule)).called(1);
    });
  });

  group('DeleteScheduleUseCase', () {
    test('delegates schedule deletion to repository', () async {
      when(() => repository.deleteSchedule('s_1'))
          .thenAnswer((_) async => const Right(null));

      final result =
          await deleteScheduleUseCase(const DeleteScheduleParams('s_1'));

      expect(result, const Right(null));
      verify(() => repository.deleteSchedule('s_1')).called(1);
    });
  });

  group('ToggleScheduleActiveUseCase', () {
    test('delegates toggle to repository', () async {
      final updated = testSchedule.copyWith(isEnabled: false);
      when(() => repository.toggleScheduleActive('s_1', false))
          .thenAnswer((_) async => Right(updated));

      final result = await toggleScheduleActiveUseCase(
        const ToggleScheduleActiveParams(id: 's_1', isEnabled: false),
      );

      expect(result, Right(updated));
      verify(() => repository.toggleScheduleActive('s_1', false)).called(1);
    });
  });
}
