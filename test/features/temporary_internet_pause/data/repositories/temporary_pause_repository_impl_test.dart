import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/error/failure.dart';
import 'package:net_guard/features/app_blocker/data/datasources/local_storage_data_source.dart';
import 'package:net_guard/features/temporary_internet_pause/data/datasources/temporary_pause_local_data_source.dart';
import 'package:net_guard/features/temporary_internet_pause/data/datasources/temporary_pause_native_data_source.dart';
import 'package:net_guard/features/temporary_internet_pause/data/models/temporary_pause_model.dart';
import 'package:net_guard/features/temporary_internet_pause/data/repositories/temporary_pause_repository_impl.dart';

class MockTemporaryPauseLocalDataSource extends Mock
    implements TemporaryPauseLocalDataSource {}

class MockTemporaryPauseNativeDataSource extends Mock
    implements TemporaryPauseNativeDataSource {}

class FakeTemporaryPauseModel extends Fake implements TemporaryPauseModel {}

void main() {
  late MockTemporaryPauseLocalDataSource mockLocalDataSource;
  late MockTemporaryPauseNativeDataSource mockNativeDataSource;
  late TemporaryPauseRepositoryImpl repository;

  final now = DateTime.now().add(const Duration(hours: 1));
  final sampleModel = TemporaryPauseModel(
    id: 'pause-1',
    packageName: 'com.test.app',
    appName: 'Test App',
    startTime: now,
    pauseUntil: now.add(const Duration(minutes: 30)),
    durationMillis: 30 * 60 * 1000,
    isCustom: false,
  );

  setUpAll(() {
    registerFallbackValue(FakeTemporaryPauseModel());
  });

  setUp(() {
    mockLocalDataSource = MockTemporaryPauseLocalDataSource();
    mockNativeDataSource = MockTemporaryPauseNativeDataSource();
    repository = TemporaryPauseRepositoryImpl(
      localDataSource: mockLocalDataSource,
      nativeDataSource: mockNativeDataSource,
    );
  });

  group('TemporaryPauseRepositoryImpl', () {
    test('getActivePauses returns active unexpired entities', () async {
      when(() => mockLocalDataSource.clearExpiredPauses(currentTime: any(named: 'currentTime')))
          .thenAnswer((_) async => []);
      when(() => mockLocalDataSource.getPauses())
          .thenAnswer((_) async => [sampleModel]);

      final result = await repository.getActivePauses();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should be right'),
        (list) {
          expect(list.length, 1);
          expect(list.first.packageName, 'com.test.app');
        },
      );
    });

    test('createPause saves pause, syncs to native, and returns entity', () async {
      when(() => mockLocalDataSource.savePause(any()))
          .thenAnswer((_) async {});
      when(() => mockLocalDataSource.getPauses())
          .thenAnswer((_) async => [sampleModel]);
      when(() => mockNativeDataSource.syncTemporaryPauses(any()))
          .thenAnswer((_) async {});

      final result = await repository.createPause(
        packageName: 'com.test.app',
        appName: 'Test App',
        duration: const Duration(minutes: 30),
      );

      expect(result.isRight(), isTrue);
      verify(() => mockLocalDataSource.savePause(any())).called(1);
      verify(() => mockNativeDataSource.syncTemporaryPauses(any())).called(1);
    });

    test('cancelPause deletes pause and syncs to native', () async {
      when(() => mockLocalDataSource.deletePause('pause-1'))
          .thenAnswer((_) async {});
      when(() => mockLocalDataSource.getPauses())
          .thenAnswer((_) async => []);
      when(() => mockNativeDataSource.syncTemporaryPauses(any()))
          .thenAnswer((_) async {});

      final result = await repository.cancelPause('pause-1');

      expect(result, const Right(null));
      verify(() => mockLocalDataSource.deletePause('pause-1')).called(1);
      verify(() => mockNativeDataSource.syncTemporaryPauses(any())).called(1);
    });

    test('reconcileExpiredPauses clears expired and syncs remaining', () async {
      when(() => mockLocalDataSource.clearExpiredPauses(currentTime: any(named: 'currentTime')))
          .thenAnswer((_) async => [sampleModel]);
      when(() => mockLocalDataSource.getPauses())
          .thenAnswer((_) async => []);
      when(() => mockNativeDataSource.syncTemporaryPauses(any()))
          .thenAnswer((_) async {});

      final result = await repository.reconcileExpiredPauses(currentTime: now);

      expect(result.isRight(), isTrue);
      verify(() => mockNativeDataSource.syncTemporaryPauses(any())).called(1);
    });

    test('getActivePausedPackages returns set of active packages', () async {
      when(() => mockLocalDataSource.getPauses())
          .thenAnswer((_) async => [sampleModel]);

      final result = await repository.getActivePausedPackages(currentTime: now);

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => {}), {'com.test.app'});
    });

    test('maps LocalStorageException to CacheFailure', () async {
      when(() => mockLocalDataSource.clearExpiredPauses(currentTime: any(named: 'currentTime')))
          .thenThrow(const LocalStorageException('Disk error'));

      final result = await repository.getActivePauses();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('Should be left'),
      );
    });
  });
}
