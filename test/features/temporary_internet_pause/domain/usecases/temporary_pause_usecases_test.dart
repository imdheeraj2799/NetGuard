import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/error/failure.dart';
import 'package:net_guard/core/usecase/usecase.dart';
import 'package:net_guard/features/temporary_internet_pause/domain/entities/temporary_pause_entity.dart';
import 'package:net_guard/features/temporary_internet_pause/domain/repositories/temporary_pause_repository.dart';
import 'package:net_guard/features/temporary_internet_pause/domain/usecases/cancel_temporary_pause_usecase.dart';
import 'package:net_guard/features/temporary_internet_pause/domain/usecases/create_temporary_pause_usecase.dart';
import 'package:net_guard/features/temporary_internet_pause/domain/usecases/get_active_pauses_usecase.dart';
import 'package:net_guard/features/temporary_internet_pause/domain/usecases/reconcile_expired_pauses_usecase.dart';

class MockTemporaryPauseRepository extends Mock
    implements TemporaryPauseRepository {}

void main() {
  late MockTemporaryPauseRepository repository;

  final now = DateTime(2026, 10, 23, 12, 0);
  final sampleEntity = TemporaryPauseEntity(
    id: 'p-1',
    packageName: 'com.chat.app',
    appName: 'Chat App',
    startTime: now,
    pauseUntil: now.add(const Duration(minutes: 15)),
    duration: const Duration(minutes: 15),
    isCustom: false,
  );

  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    repository = MockTemporaryPauseRepository();
  });

  group('GetActivePausesUseCase', () {
    test('calls repository getActivePauses', () async {
      when(() => repository.getActivePauses())
          .thenAnswer((_) async => Right([sampleEntity]));

      final result = await GetActivePausesUseCase(repository)(const NoParams());

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => []), [sampleEntity]);
      verify(() => repository.getActivePauses()).called(1);
    });
  });

  group('CreateTemporaryPauseUseCase', () {
    test('returns ValidationFailure when packageName is empty', () async {
      final result = await CreateTemporaryPauseUseCase(repository)(
        const CreateTemporaryPauseParams(
          packageName: '  ',
          appName: 'Chat',
          duration: Duration(minutes: 15),
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('Should fail'),
      );
    });

    test('returns ValidationFailure when duration is zero or negative', () async {
      final result = await CreateTemporaryPauseUseCase(repository)(
        const CreateTemporaryPauseParams(
          packageName: 'com.chat.app',
          appName: 'Chat',
          duration: Duration.zero,
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('Should fail'),
      );
    });

    test('calls repository createPause on valid params', () async {
      when(() => repository.createPause(
            packageName: any(named: 'packageName'),
            appName: any(named: 'appName'),
            duration: any(named: 'duration'),
            isCustom: any(named: 'isCustom'),
          )).thenAnswer((_) async => Right(sampleEntity));

      final result = await CreateTemporaryPauseUseCase(repository)(
        const CreateTemporaryPauseParams(
          packageName: 'com.chat.app',
          appName: 'Chat App',
          duration: Duration(minutes: 15),
        ),
      );

      expect(result, Right(sampleEntity));
      verify(() => repository.createPause(
            packageName: 'com.chat.app',
            appName: 'Chat App',
            duration: const Duration(minutes: 15),
            isCustom: false,
          )).called(1);
    });
  });

  group('CancelTemporaryPauseUseCase', () {
    test('returns ValidationFailure when id is empty', () async {
      final result = await CancelTemporaryPauseUseCase(repository)(
        const CancelTemporaryPauseParams('  '),
      );

      expect(result.isLeft(), isTrue);
    });

    test('calls repository cancelPause when id is valid', () async {
      when(() => repository.cancelPause('p-1'))
          .thenAnswer((_) async => const Right(null));

      final result = await CancelTemporaryPauseUseCase(repository)(
        const CancelTemporaryPauseParams('p-1'),
      );

      expect(result, const Right(null));
      verify(() => repository.cancelPause('p-1')).called(1);
    });
  });

  group('ReconcileExpiredPausesUseCase', () {
    test('calls repository reconcileExpiredPauses', () async {
      when(() => repository.reconcileExpiredPauses(currentTime: any(named: 'currentTime')))
          .thenAnswer((_) async => Right([sampleEntity]));

      final result = await ReconcileExpiredPausesUseCase(repository)(
        ReconcileExpiredPausesParams(currentTime: now),
      );

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => []), [sampleEntity]);
      verify(() => repository.reconcileExpiredPauses(currentTime: now)).called(1);
    });
  });
}
