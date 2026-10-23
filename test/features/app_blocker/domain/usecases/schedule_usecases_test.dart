import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/error/failure.dart';
import 'package:net_guard/core/usecase/usecase.dart';
import 'package:net_guard/features/app_blocker/domain/entities/block_schedule_entity.dart';
import 'package:net_guard/features/app_blocker/domain/repositories/schedule_repository.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/are_notifications_enabled_usecase.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/can_schedule_exact_alarms_usecase.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/delete_schedule_usecase.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/get_assigned_packages_usecase.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/get_effective_blocked_packages_usecase.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/get_schedules_usecase.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/request_exact_alarm_permission_usecase.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/request_notification_permission_usecase.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/save_schedule_usecase.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/sync_schedules_usecase.dart';
import 'package:net_guard/features/app_blocker/domain/usecases/toggle_schedule_usecase.dart';

class MockScheduleRepository extends Mock implements ScheduleRepository {}

class FakeBlockScheduleEntity extends Fake implements BlockScheduleEntity {}

void main() {
  late MockScheduleRepository repository;

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
    registerFallbackValue(FakeBlockScheduleEntity());
  });

  setUp(() {
    repository = MockScheduleRepository();
  });

  group('GetSchedulesUseCase', () {
    test('returns list of schedules from repository', () async {
      final list = [sampleSchedule];
      when(() => repository.getSchedules())
          .thenAnswer((_) async => Right(list));

      final result = await GetSchedulesUseCase(repository)(const NoParams());

      expect(result, Right(list));
      verify(() => repository.getSchedules()).called(1);
    });
  });

  group('SaveScheduleUseCase', () {
    test('calls repository saveSchedule', () async {
      when(() => repository.saveSchedule(any()))
          .thenAnswer((_) async => const Right(null));

      final result = await SaveScheduleUseCase(repository)(
        SaveScheduleParams(sampleSchedule),
      );

      expect(result, const Right(null));
      verify(() => repository.saveSchedule(sampleSchedule)).called(1);
    });
  });

  group('DeleteScheduleUseCase', () {
    test('calls repository deleteSchedule', () async {
      when(() => repository.deleteSchedule('s-1'))
          .thenAnswer((_) async => const Right(null));

      final result = await DeleteScheduleUseCase(repository)(
        const DeleteScheduleParams('s-1'),
      );

      expect(result, const Right(null));
      verify(() => repository.deleteSchedule('s-1')).called(1);
    });
  });

  group('ToggleScheduleUseCase', () {
    test('calls repository toggleSchedule', () async {
      when(() => repository.toggleSchedule(id: 's-1', isEnabled: false))
          .thenAnswer((_) async => const Right(null));

      final result = await ToggleScheduleUseCase(repository)(
        const ToggleScheduleParams(id: 's-1', isEnabled: false),
      );

      expect(result, const Right(null));
      verify(() => repository.toggleSchedule(id: 's-1', isEnabled: false)).called(1);
    });
  });

  group('GetEffectiveBlockedPackagesUseCase', () {
    test('calls repository getEffectiveBlockedPackages', () async {
      when(() => repository.getEffectiveBlockedPackages(currentTime: fixedDate))
          .thenAnswer((_) async => const Right({'com.work.app'}));

      final result = await GetEffectiveBlockedPackagesUseCase(repository)(
        GetEffectiveBlockedPackagesParams(currentTime: fixedDate),
      );

      expect(result, const Right({'com.work.app'}));
      verify(() => repository.getEffectiveBlockedPackages(currentTime: fixedDate)).called(1);
    });
  });

  group('GetAssignedPackagesUseCase', () {
    test('calls repository getAssignedPackages', () async {
      when(() => repository.getAssignedPackages(excludeScheduleId: 's-1'))
          .thenAnswer((_) async => const Right({'com.work.app': 'Work'}));

      final result = await GetAssignedPackagesUseCase(repository)(
        const GetAssignedPackagesParams(excludeScheduleId: 's-1'),
      );

      expect(result, const Right({'com.work.app': 'Work'}));
      verify(() => repository.getAssignedPackages(excludeScheduleId: 's-1')).called(1);
    });
  });

  group('CanScheduleExactAlarmsUseCase', () {
    test('calls repository canScheduleExactAlarms', () async {
      when(() => repository.canScheduleExactAlarms())
          .thenAnswer((_) async => const Right(true));

      final result = await CanScheduleExactAlarmsUseCase(repository)(const NoParams());

      expect(result, const Right(true));
      verify(() => repository.canScheduleExactAlarms()).called(1);
    });

    test('returns failure from repository', () async {
      const failure = PlatformFailure('Unavailable');
      when(() => repository.canScheduleExactAlarms())
          .thenAnswer((_) async => const Left(failure));

      final result = await CanScheduleExactAlarmsUseCase(repository)(const NoParams());

      expect(result, const Left(failure));
    });
  });

  group('RequestExactAlarmPermissionUseCase', () {
    test('calls repository requestExactAlarmPermission', () async {
      when(() => repository.requestExactAlarmPermission())
          .thenAnswer((_) async => const Right(true));

      final result = await RequestExactAlarmPermissionUseCase(repository)(const NoParams());

      expect(result, const Right(true));
      verify(() => repository.requestExactAlarmPermission()).called(1);
    });
  });

  group('SyncSchedulesUseCase', () {
    test('calls repository syncSchedules', () async {
      when(() => repository.syncSchedules())
          .thenAnswer((_) async => const Right(null));

      final result = await SyncSchedulesUseCase(repository)(const NoParams());

      expect(result, const Right(null));
      verify(() => repository.syncSchedules()).called(1);
    });
  });

  group('AreNotificationsEnabledUseCase', () {
    test('calls repository areNotificationsEnabled', () async {
      when(() => repository.areNotificationsEnabled())
          .thenAnswer((_) async => const Right(true));

      final result = await AreNotificationsEnabledUseCase(repository)(const NoParams());

      expect(result, const Right(true));
      verify(() => repository.areNotificationsEnabled()).called(1);
    });
  });

  group('RequestNotificationPermissionUseCase', () {
    test('calls repository requestNotificationPermission', () async {
      when(() => repository.requestNotificationPermission())
          .thenAnswer((_) async => const Right(true));

      final result = await RequestNotificationPermissionUseCase(repository)(const NoParams());

      expect(result, const Right(true));
      verify(() => repository.requestNotificationPermission()).called(1);
    });
  });
}
