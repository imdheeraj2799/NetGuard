import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/temporary_pause_entity.dart';
import '../../domain/usecases/cancel_temporary_pause_usecase.dart';
import '../../domain/usecases/create_temporary_pause_usecase.dart';
import '../../domain/usecases/get_active_pauses_usecase.dart';
import '../../domain/usecases/reconcile_expired_pauses_usecase.dart';
import 'temporary_pause_event.dart';
import 'temporary_pause_state.dart';

class TemporaryPauseBloc
    extends Bloc<TemporaryPauseEvent, TemporaryPauseState> {
  TemporaryPauseBloc({
    required this.getActivePauses,
    required this.createPause,
    required this.cancelPause,
    required this.reconcileExpiredPauses,
    this.startTickerOnLoad = true,
  }) : super(const TemporaryPauseInitial()) {
    on<LoadTemporaryPausesEvent>(_onLoadPauses);
    on<CreateTemporaryPauseEvent>(_onCreatePause);
    on<CancelTemporaryPauseEvent>(_onCancelPause);
    on<ReconcileExpiredPausesEvent>(_onReconcileExpiredPauses);
    on<TimerTickEvent>(_onTimerTick);
    on<ClearTemporaryPauseActionMessageEvent>(_onClearActionMessage);
  }

  final GetActivePausesUseCase getActivePauses;
  final CreateTemporaryPauseUseCase createPause;
  final CancelTemporaryPauseUseCase cancelPause;
  final ReconcileExpiredPausesUseCase reconcileExpiredPauses;
  final bool startTickerOnLoad;

  Timer? _tickerTimer;

  void startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(TimerTickEvent(DateTime.now()));
    });
  }

  void stopTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = null;
  }

  Future<void> _onLoadPauses(
    LoadTemporaryPausesEvent event,
    Emitter<TemporaryPauseState> emit,
  ) async {
    if (state is! TemporaryPauseLoaded) {
      emit(const TemporaryPauseLoading());
    }

    final result = await getActivePauses(const NoParams());
    result.fold(
      (failure) => emit(TemporaryPauseError(
        message: failure.message,
        pauses: _getCurrentPauses(),
      )),
      (pauses) {
        if (startTickerOnLoad && pauses.isNotEmpty) {
          startTicker();
        }
        emit(TemporaryPauseLoaded(
          pauses: pauses,
          lastTick: DateTime.now(),
        ));
      },
    );
  }

  Future<void> _onCreatePause(
    CreateTemporaryPauseEvent event,
    Emitter<TemporaryPauseState> emit,
  ) async {
    final result = await createPause(
      CreateTemporaryPauseParams(
        packageName: event.packageName,
        appName: event.appName,
        duration: event.duration,
        isCustom: event.isCustom,
      ),
    );

    await result.fold(
      (failure) async {
        emit(TemporaryPauseError(
          message: failure.message,
          pauses: _getCurrentPauses(),
        ));
      },
      (created) async {
        final activeResult = await getActivePauses(const NoParams());
        final pauses = activeResult.getOrElse(() => [created]);
        if (startTickerOnLoad) {
          startTicker();
        }
        emit(TemporaryPauseLoaded(
          pauses: pauses,
          lastTick: DateTime.now(),
          actionMessage: 'Paused internet access for ${event.appName}',
        ));
      },
    );
  }

  Future<void> _onCancelPause(
    CancelTemporaryPauseEvent event,
    Emitter<TemporaryPauseState> emit,
  ) async {
    final result = await cancelPause(CancelTemporaryPauseParams(event.id));

    await result.fold(
      (failure) async {
        emit(TemporaryPauseError(
          message: failure.message,
          pauses: _getCurrentPauses(),
        ));
      },
      (_) async {
        final activeResult = await getActivePauses(const NoParams());
        final pauses = activeResult.getOrElse(() => const []);
        if (pauses.isEmpty) {
          stopTicker();
        }
        emit(TemporaryPauseLoaded(
          pauses: pauses,
          lastTick: DateTime.now(),
          actionMessage: 'Temporary pause cancelled',
        ));
      },
    );
  }

  Future<void> _onReconcileExpiredPauses(
    ReconcileExpiredPausesEvent event,
    Emitter<TemporaryPauseState> emit,
  ) async {
    final result = await reconcileExpiredPauses(
      ReconcileExpiredPausesParams(currentTime: event.currentTime),
    );

    result.fold(
      (failure) => emit(TemporaryPauseError(
        message: failure.message,
        pauses: _getCurrentPauses(),
      )),
      (pauses) {
        if (pauses.isEmpty) {
          stopTicker();
        }
        if (state is TemporaryPauseLoaded) {
          emit((state as TemporaryPauseLoaded).copyWith(
            pauses: pauses,
            lastTick: event.currentTime ?? DateTime.now(),
          ));
        } else {
          emit(TemporaryPauseLoaded(
            pauses: pauses,
            lastTick: event.currentTime ?? DateTime.now(),
          ));
        }
      },
    );
  }

  void _onTimerTick(
    TimerTickEvent event,
    Emitter<TemporaryPauseState> emit,
  ) {
    if (state is! TemporaryPauseLoaded) return;
    final current = state as TemporaryPauseLoaded;

    final hasExpired = current.pauses.any((p) => p.isExpired(event.currentTime));
    if (hasExpired) {
      add(ReconcileExpiredPausesEvent(currentTime: event.currentTime));
    } else {
      emit(current.copyWith(lastTick: event.currentTime));
    }
  }

  void _onClearActionMessage(
    ClearTemporaryPauseActionMessageEvent event,
    Emitter<TemporaryPauseState> emit,
  ) {
    if (state is TemporaryPauseLoaded) {
      final current = state as TemporaryPauseLoaded;
      if (current.actionMessage != null) {
        emit(current.copyWith(clearActionMessage: true));
      }
    }
  }

  List<TemporaryPauseEntity> _getCurrentPauses() {
    if (state is TemporaryPauseLoaded) {
      return (state as TemporaryPauseLoaded).pauses;
    }
    if (state is TemporaryPauseError) {
      return (state as TemporaryPauseError).pauses;
    }
    return const [];
  }

  @override
  Future<void> close() {
    stopTicker();
    return super.close();
  }
}
