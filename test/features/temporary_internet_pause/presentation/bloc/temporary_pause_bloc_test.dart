import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/error/failure.dart';
import 'package:net_guard/core/usecase/usecase.dart';
import 'package:net_guard/features/temporary_internet_pause/domain/entities/temporary_pause_entity.dart';
import 'package:net_guard/features/temporary_internet_pause/domain/usecases/cancel_temporary_pause_usecase.dart';
import 'package:net_guard/features/temporary_internet_pause/domain/usecases/create_temporary_pause_usecase.dart';
import 'package:net_guard/features/temporary_internet_pause/domain/usecases/get_active_pauses_usecase.dart';
import 'package:net_guard/features/temporary_internet_pause/domain/usecases/reconcile_expired_pauses_usecase.dart';
import 'package:net_guard/features/temporary_internet_pause/presentation/bloc/temporary_pause_bloc.dart';
import 'package:net_guard/features/temporary_internet_pause/presentation/bloc/temporary_pause_event.dart';
import 'package:net_guard/features/temporary_internet_pause/presentation/bloc/temporary_pause_state.dart';

class MockGetActivePausesUseCase extends Mock
    implements GetActivePausesUseCase {}

class MockCreateTemporaryPauseUseCase extends Mock
    implements CreateTemporaryPauseUseCase {}

class MockCancelTemporaryPauseUseCase extends Mock
    implements CancelTemporaryPauseUseCase {}

class MockReconcileExpiredPausesUseCase extends Mock
    implements ReconcileExpiredPausesUseCase {}

class FakeCreateTemporaryPauseParams extends Fake
    implements CreateTemporaryPauseParams {}

class FakeCancelTemporaryPauseParams extends Fake
    implements CancelTemporaryPauseParams {}

class FakeReconcileExpiredPausesParams extends Fake
    implements ReconcileExpiredPausesParams {}

void main() {
  late MockGetActivePausesUseCase mockGetActivePauses;
  late MockCreateTemporaryPauseUseCase mockCreatePause;
  late MockCancelTemporaryPauseUseCase mockCancelPause;
  late MockReconcileExpiredPausesUseCase mockReconcileExpiredPauses;
  late TemporaryPauseBloc bloc;

  final now = DateTime(2026, 10, 23, 12, 0);
  final samplePause = TemporaryPauseEntity(
    id: 'p-1',
    packageName: 'com.chat.app',
    appName: 'Chat App',
    startTime: now,
    pauseUntil: now.add(const Duration(minutes: 30)),
    duration: const Duration(minutes: 30),
    isCustom: false,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(FakeCreateTemporaryPauseParams());
    registerFallbackValue(FakeCancelTemporaryPauseParams());
    registerFallbackValue(FakeReconcileExpiredPausesParams());
  });

  setUp(() {
    mockGetActivePauses = MockGetActivePausesUseCase();
    mockCreatePause = MockCreateTemporaryPauseUseCase();
    mockCancelPause = MockCancelTemporaryPauseUseCase();
    mockReconcileExpiredPauses = MockReconcileExpiredPausesUseCase();

    bloc = TemporaryPauseBloc(
      getActivePauses: mockGetActivePauses,
      createPause: mockCreatePause,
      cancelPause: mockCancelPause,
      reconcileExpiredPauses: mockReconcileExpiredPauses,
      startTickerOnLoad: false, // Disabled in unit tests for deterministic testing
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('TemporaryPauseBloc - LoadTemporaryPausesEvent', () {
    blocTest<TemporaryPauseBloc, TemporaryPauseState>(
      'emits TemporaryPauseLoading then TemporaryPauseLoaded on success',
      build: () {
        when(() => mockGetActivePauses(any()))
            .thenAnswer((_) async => Right([samplePause]));
        return bloc;
      },
      act: (b) => b.add(const LoadTemporaryPausesEvent()),
      expect: () => [
        const TemporaryPauseLoading(),
        isA<TemporaryPauseLoaded>().having(
          (s) => s.pauses,
          'pauses',
          [samplePause],
        ),
      ],
    );

    blocTest<TemporaryPauseBloc, TemporaryPauseState>(
      'emits TemporaryPauseLoading then TemporaryPauseError on failure',
      build: () {
        when(() => mockGetActivePauses(any()))
            .thenAnswer((_) async => const Left(CacheFailure('Storage error')));
        return bloc;
      },
      act: (b) => b.add(const LoadTemporaryPausesEvent()),
      expect: () => [
        const TemporaryPauseLoading(),
        const TemporaryPauseError(message: 'Storage error'),
      ],
    );
  });

  group('TemporaryPauseBloc - CreateTemporaryPauseEvent', () {
    blocTest<TemporaryPauseBloc, TemporaryPauseState>(
      'creates pause and emits TemporaryPauseLoaded with actionMessage',
      build: () {
        when(() => mockCreatePause(any()))
            .thenAnswer((_) async => Right(samplePause));
        when(() => mockGetActivePauses(any()))
            .thenAnswer((_) async => Right([samplePause]));
        return bloc;
      },
      act: (b) => b.add(const CreateTemporaryPauseEvent(
        packageName: 'com.chat.app',
        appName: 'Chat App',
        duration: Duration(minutes: 30),
      )),
      expect: () => [
        isA<TemporaryPauseLoaded>()
            .having((s) => s.pauses, 'pauses', [samplePause])
            .having(
              (s) => s.actionMessage,
              'actionMessage',
              'Paused internet access for Chat App',
            ),
      ],
    );
  });

  group('TemporaryPauseBloc - CancelTemporaryPauseEvent', () {
    blocTest<TemporaryPauseBloc, TemporaryPauseState>(
      'cancels pause and emits updated state with confirmation actionMessage',
      seed: () => TemporaryPauseLoaded(pauses: [samplePause]),
      build: () {
        when(() => mockCancelPause(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockGetActivePauses(any()))
            .thenAnswer((_) async => const Right([]));
        return bloc;
      },
      act: (b) => b.add(const CancelTemporaryPauseEvent('p-1')),
      expect: () => [
        isA<TemporaryPauseLoaded>()
            .having((s) => s.pauses, 'pauses', isEmpty)
            .having(
              (s) => s.actionMessage,
              'actionMessage',
              'Temporary pause cancelled',
            ),
      ],
    );
  });

  group('TemporaryPauseBloc - TimerTickEvent and Reconcile', () {
    blocTest<TemporaryPauseBloc, TemporaryPauseState>(
      'updates lastTick when no pauses are expired',
      seed: () => TemporaryPauseLoaded(pauses: [samplePause]),
      build: () => bloc,
      act: (b) => b.add(TimerTickEvent(now.add(const Duration(minutes: 5)))),
      expect: () => [
        isA<TemporaryPauseLoaded>().having(
          (s) => s.lastTick,
          'lastTick',
          now.add(const Duration(minutes: 5)),
        ),
      ],
    );

    blocTest<TemporaryPauseBloc, TemporaryPauseState>(
      'triggers ReconcileExpiredPausesEvent when pause is expired',
      seed: () => TemporaryPauseLoaded(pauses: [samplePause]),
      build: () {
        when(() => mockReconcileExpiredPauses(any()))
            .thenAnswer((_) async => const Right([]));
        return bloc;
      },
      act: (b) => b.add(TimerTickEvent(now.add(const Duration(minutes: 35)))),
      expect: () => [
        isA<TemporaryPauseLoaded>().having(
          (s) => s.pauses,
          'pauses',
          isEmpty,
        ),
      ],
    );
    blocTest<TemporaryPauseBloc, TemporaryPauseState>(
      'clears actionMessage on TimerTickEvent without losing pauses',
      seed: () => TemporaryPauseLoaded(
        pauses: [samplePause],
        actionMessage: 'Paused internet access for Chat App',
      ),
      build: () => bloc,
      act: (b) => b.add(TimerTickEvent(now.add(const Duration(seconds: 1)))),
      expect: () => [
        isA<TemporaryPauseLoaded>()
            .having((s) => s.actionMessage, 'actionMessage', isNull)
            .having(
              (s) => s.lastTick,
              'lastTick',
              now.add(const Duration(seconds: 1)),
            ),
      ],
    );

    blocTest<TemporaryPauseBloc, TemporaryPauseState>(
      'clears actionMessage when ClearTemporaryPauseActionMessageEvent is dispatched',
      seed: () => TemporaryPauseLoaded(
        pauses: [samplePause],
        actionMessage: 'Paused internet access for Chat App',
      ),
      build: () => bloc,
      act: (b) => b.add(const ClearTemporaryPauseActionMessageEvent()),
      expect: () => [
        isA<TemporaryPauseLoaded>()
            .having((s) => s.actionMessage, 'actionMessage', isNull)
            .having((s) => s.pauses, 'pauses', [samplePause]),
      ],
    );
  });
}
