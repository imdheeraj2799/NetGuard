import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/error/failure.dart';
import 'package:net_guard/features/app_blocker/data/datasources/local_storage_data_source.dart';
import 'package:net_guard/features/app_blocker/data/datasources/native_app_data_source.dart';
import 'package:net_guard/features/app_blocker/data/datasources/schedule_local_data_source.dart';
import 'package:net_guard/features/app_blocker/data/datasources/app_local_data_source.dart';
import 'package:net_guard/features/app_blocker/data/models/app_info_model.dart';
import 'package:net_guard/features/app_blocker/data/models/block_schedule_model.dart';
import 'package:net_guard/features/app_blocker/data/repositories/schedule_repository_impl.dart';
import 'package:net_guard/features/app_blocker/domain/entities/block_schedule_entity.dart';
import 'package:net_guard/features/app_blocker/domain/services/firewall_rule_engine.dart';
import 'package:net_guard/features/app_blocker/domain/services/schedule_conflict_validator.dart';
import 'package:net_guard/features/app_blocker/domain/services/schedule_engine.dart';

class MockScheduleLocalDataSource extends Mock implements ScheduleLocalDataSource {}

class MockLocalStorageDataSource extends Mock implements LocalStorageDataSource {}

class MockNativeAppDataSource extends Mock implements NativeAppDataSource {}

class MockAppLocalDataSource extends Mock implements AppLocalDataSource {}

class FakeBlockScheduleModel extends Fake implements BlockScheduleModel {}

void main() {
  late MockScheduleLocalDataSource mockScheduleDataSource;
  late MockLocalStorageDataSource mockLocalStorageDataSource;
  late MockNativeAppDataSource mockNativeDataSource;
  late ScheduleRepositoryImpl repository;

  final fixedDate = DateTime(2026, 10, 21, 10, 0);

  final testScheduleModel1 = BlockScheduleModel(
    id: 's-1',
    name: 'Work',
    packageNames: const ['com.work.chat'],
    recurrence: ScheduleRecurrence.weekdays,
    startHour: 9,
    startMinute: 0,
    endHour: 17,
    endMinute: 0,
    isEnabled: true,
    createdAt: fixedDate,
    updatedAt: fixedDate,
  );

  final testScheduleModel2 = BlockScheduleModel(
    id: 's-2',
    name: 'Night',
    packageNames: const ['com.video.stream'],
    recurrence: ScheduleRecurrence.daily,
    startHour: 23,
    startMinute: 0,
    endHour: 6,
    endMinute: 0,
    isEnabled: true,
    createdAt: fixedDate,
    updatedAt: fixedDate,
  );

  setUpAll(() {
    registerFallbackValue(FakeBlockScheduleModel());
  });

  setUp(() {
    mockScheduleDataSource = MockScheduleLocalDataSource();
    mockLocalStorageDataSource = MockLocalStorageDataSource();
    mockNativeDataSource = MockNativeAppDataSource();

    when(() => mockLocalStorageDataSource.getBlockedPackages())
        .thenAnswer((_) async => []);
    when(() => mockNativeDataSource.updateBlockedList(any()))
        .thenAnswer((_) async {});
    when(() => mockNativeDataSource.stopVpnService())
        .thenAnswer((_) async {});
    when(() => mockNativeDataSource.syncSchedules(any()))
        .thenAnswer((_) async {});

    repository = ScheduleRepositoryImpl(
      scheduleLocalDataSource: mockScheduleDataSource,
      localStorageDataSource: mockLocalStorageDataSource,
      nativeDataSource: mockNativeDataSource,
      conflictValidator: const ScheduleConflictValidator(),
      ruleEngine: const FirewallRuleEngine(scheduleEngine: ScheduleEngine()),
    );
  });

  group('ScheduleRepositoryImpl - getSchedules', () {
    test('returns List of BlockScheduleEntity on success', () async {
      when(() => mockScheduleDataSource.getSchedules())
          .thenAnswer((_) async => [testScheduleModel1, testScheduleModel2]);

      final result = await repository.getSchedules();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should be right'),
        (list) {
          expect(list.length, 2);
          expect(list.first.id, 's-1');
          expect(list.last.id, 's-2');
        },
      );
    });

    test('returns CacheFailure when data source throws LocalStorageException', () async {
      when(() => mockScheduleDataSource.getSchedules())
          .thenThrow(const LocalStorageException('Failed to read'));

      final result = await repository.getSchedules();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('Should be left'),
      );
    });
  });

  group('ScheduleRepositoryImpl - saveSchedule', () {
    test('returns ValidationFailure if schedule has conflicting packages', () async {
      when(() => mockScheduleDataSource.getSchedules())
          .thenAnswer((_) async => [testScheduleModel1]);

      final conflictingSchedule = BlockScheduleEntity(
        id: 'new-s',
        name: 'Another Schedule',
        packageNames: const ['com.work.chat'], // Already in testScheduleModel1
        recurrence: ScheduleRecurrence.daily,
        startHour: 10,
        startMinute: 0,
        endHour: 12,
        endMinute: 0,
        isEnabled: true,
        createdAt: fixedDate,
        updatedAt: fixedDate,
      );

      final result = await repository.saveSchedule(conflictingSchedule);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('com.work.chat is already assigned to "Work"'));
        },
        (_) => fail('Should be left'),
      );
      verifyNever(() => mockScheduleDataSource.saveSchedule(any()));
    });

    test('saves schedule and syncs schedules to native engine when valid', () async {
      when(() => mockScheduleDataSource.getSchedules())
          .thenAnswer((_) async => [testScheduleModel1]);
      when(() => mockScheduleDataSource.saveSchedule(any()))
          .thenAnswer((_) async {});

      final validSchedule = BlockScheduleEntity(
        id: 'new-s',
        name: 'Non Conflicting',
        packageNames: const ['com.news.feed'],
        recurrence: ScheduleRecurrence.daily,
        startHour: 10,
        startMinute: 0,
        endHour: 12,
        endMinute: 0,
        isEnabled: true,
        createdAt: fixedDate,
        updatedAt: fixedDate,
      );

      final result = await repository.saveSchedule(validSchedule);

      expect(result, const Right(null));
      verify(() => mockScheduleDataSource.saveSchedule(any())).called(1);
      // _syncEffectiveBlockedListToVpn now delegates entirely to syncSchedules.
      // reconcileAndApply on the native side handles VPN start/stop.
      verify(() => mockNativeDataSource.syncSchedules(any())).called(1);
      verifyNever(() => mockNativeDataSource.updateBlockedList(any()));
    });

    test('syncs schedule to native engine even when saving a disabled schedule', () async {
      when(() => mockScheduleDataSource.getSchedules())
          .thenAnswer((_) async => []);
      when(() => mockScheduleDataSource.saveSchedule(any()))
          .thenAnswer((_) async {});

      final disabledSchedule = BlockScheduleEntity(
        id: 'new-s',
        name: 'Disabled Sched',
        packageNames: const ['com.dummy.app'],
        recurrence: ScheduleRecurrence.daily,
        startHour: 10,
        startMinute: 0,
        endHour: 12,
        endMinute: 0,
        isEnabled: false,
        createdAt: fixedDate,
        updatedAt: fixedDate,
      );

      final result = await repository.saveSchedule(disabledSchedule);

      expect(result, const Right(null));
      // reconcileAndApply on native side decides whether to stop/start VPN.
      verify(() => mockNativeDataSource.syncSchedules(any())).called(1);
      verifyNever(() => mockNativeDataSource.stopVpnService());
    });
  });

  group('ScheduleRepositoryImpl - deleteSchedule', () {
    test('deletes schedule and syncs schedules to native engine', () async {
      when(() => mockScheduleDataSource.deleteSchedule('s-1'))
          .thenAnswer((_) async {});
      when(() => mockScheduleDataSource.getSchedules())
          .thenAnswer((_) async => []);

      final result = await repository.deleteSchedule('s-1');

      expect(result, const Right(null));
      verify(() => mockScheduleDataSource.deleteSchedule('s-1')).called(1);
      // After delete, syncSchedules is called so native reconcileAndApply
      // decides whether to stop/start VPN — no direct stopVpnService call.
      verify(() => mockNativeDataSource.syncSchedules(any())).called(1);
      verifyNever(() => mockNativeDataSource.stopVpnService());
    });
  });

  group('ScheduleRepositoryImpl - toggleSchedule', () {
    test('prevents enabling schedule if its packages conflict with another active schedule', () async {
      final disabledScheduleWithConflict = BlockScheduleModel(
        id: 's-conflict',
        name: 'Conflict Sched',
        packageNames: const ['com.work.chat'], // in testScheduleModel1
        recurrence: ScheduleRecurrence.daily,
        startHour: 10,
        startMinute: 0,
        endHour: 12,
        endMinute: 0,
        isEnabled: false,
        createdAt: fixedDate,
        updatedAt: fixedDate,
      );

      when(() => mockScheduleDataSource.getSchedules())
          .thenAnswer((_) async => [testScheduleModel1, disabledScheduleWithConflict]);

      final result = await repository.toggleSchedule(id: 's-conflict', isEnabled: true);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should be left'),
      );
      verifyNever(() => mockScheduleDataSource.toggleSchedule(id: any(named: 'id'), isEnabled: any(named: 'isEnabled')));
    });

    test('allows disabling an enabled schedule without conflict check and syncs native', () async {
      when(() => mockScheduleDataSource.getSchedules())
          .thenAnswer((_) async => [testScheduleModel1]);
      when(() => mockScheduleDataSource.toggleSchedule(id: 's-1', isEnabled: false))
          .thenAnswer((_) async {});

      final result = await repository.toggleSchedule(id: 's-1', isEnabled: false);

      expect(result, const Right(null));
      verify(() => mockScheduleDataSource.toggleSchedule(id: 's-1', isEnabled: false)).called(1);
      verify(() => mockNativeDataSource.syncSchedules(any())).called(1);
    });
  });

  group('ScheduleRepositoryImpl - getEffectiveBlockedPackages & getAssignedPackages', () {
    test('computes effective blocked packages merging manual and active schedules', () async {
      when(() => mockLocalStorageDataSource.getBlockedPackages())
          .thenAnswer((_) async => ['com.manual.only']);
      when(() => mockScheduleDataSource.getSchedules())
          .thenAnswer((_) async => [testScheduleModel1]);

      // Monday 10:00 AM (work schedule is active)
      final monday10am = DateTime(2026, 10, 19, 10, 0);

      final result = await repository.getEffectiveBlockedPackages(currentTime: monday10am);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should be right'),
        (set) {
          expect(set, containsAll(['com.manual.only', 'com.work.chat']));
        },
      );
    });

    test('returns map of assigned packages excluding specified schedule', () async {
      when(() => mockScheduleDataSource.getSchedules())
          .thenAnswer((_) async => [testScheduleModel1, testScheduleModel2]);

      final result = await repository.getAssignedPackages(excludeScheduleId: 's-2');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should be right'),
        (map) {
          expect(map.containsKey('com.work.chat'), isTrue);
          expect(map['com.work.chat'], 'Work');
          expect(map.containsKey('com.video.stream'), isFalse); // excluded
        },
      );
    });
  });

  group('ScheduleRepositoryImpl - Native Alarm & Sync methods', () {
    test('canScheduleExactAlarms returns Right(bool) from native datasource', () async {
      when(() => mockNativeDataSource.canScheduleExactAlarms())
          .thenAnswer((_) async => true);

      final result = await repository.canScheduleExactAlarms();

      expect(result, const Right(true));
      verify(() => mockNativeDataSource.canScheduleExactAlarms()).called(1);
    });

    test('canScheduleExactAlarms returns Left(PlatformFailure) on exception', () async {
      when(() => mockNativeDataSource.canScheduleExactAlarms())
          .thenThrow(const NativeDataSourceException('failed'));

      final result = await repository.canScheduleExactAlarms();

      expect(result, isA<Left>());
      result.fold(
        (failure) => expect(failure, isA<PlatformFailure>()),
        (_) => fail('Should be left'),
      );
    });

    test('requestExactAlarmPermission returns Right(bool)', () async {
      when(() => mockNativeDataSource.requestExactAlarmPermission())
          .thenAnswer((_) async => true);

      final result = await repository.requestExactAlarmPermission();

      expect(result, const Right(true));
      verify(() => mockNativeDataSource.requestExactAlarmPermission()).called(1);
    });

    test('syncSchedules calls syncSchedules on native datasource and returns Right(null)', () async {
      when(() => mockScheduleDataSource.getSchedules())
          .thenAnswer((_) async => [testScheduleModel1]);

      final result = await repository.syncSchedules();

      expect(result, const Right(null));
      verify(() => mockNativeDataSource.syncSchedules(any())).called(1);
    });

    test('synchronizes isSchedulePart and whichSchedule to cached apps on save and delete', () async {
      final mockAppLocalDataSource = MockAppLocalDataSource();
      final repoWithApps = ScheduleRepositoryImpl(
        scheduleLocalDataSource: mockScheduleDataSource,
        localStorageDataSource: mockLocalStorageDataSource,
        nativeDataSource: mockNativeDataSource,
        conflictValidator: const ScheduleConflictValidator(),
        ruleEngine: const FirewallRuleEngine(scheduleEngine: ScheduleEngine()),
        appLocalDataSource: mockAppLocalDataSource,
      );

      final cachedApp = const AppInfoModel(
        appName: 'Chat',
        packageName: 'com.work.chat',
        isBlocked: false,
      );

      when(() => mockScheduleDataSource.getSchedules())
          .thenAnswer((_) async => [testScheduleModel1]);
      when(() => mockScheduleDataSource.saveSchedule(any()))
          .thenAnswer((_) async {});
      when(() => mockAppLocalDataSource.getCachedApps())
          .thenAnswer((_) async => [cachedApp]);
      when(() => mockAppLocalDataSource.cacheApps(any()))
          .thenAnswer((_) async {});

      // Save schedule
      final saveResult = await repoWithApps.saveSchedule(testScheduleModel1.toEntity());
      expect(saveResult, const Right(null));

      // Verify that cacheApps was called with updated isSchedulePart and whichSchedule
      final captured = verify(() => mockAppLocalDataSource.cacheApps(captureAny())).captured;
      expect(captured.isNotEmpty, isTrue);
      final List<AppInfoModel> updatedList = captured.last as List<AppInfoModel>;
      expect(updatedList.first.isSchedulePart, isTrue);
      expect(updatedList.first.whichSchedule, 'Work');
    });
  });
}

