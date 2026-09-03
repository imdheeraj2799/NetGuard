// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/schedule_entity.dart';
import '../../domain/usecases/create_schedule_usecase.dart';
import '../../domain/usecases/delete_schedule_usecase.dart';
import '../../domain/usecases/get_schedules_usecase.dart';
import '../../domain/usecases/toggle_schedule_active_usecase.dart';
import '../../domain/usecases/update_schedule_usecase.dart';
import 'schedule_event.dart';
import 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  ScheduleBloc({
    required GetSchedulesUseCase getSchedules,
    required CreateScheduleUseCase createSchedule,
    required UpdateScheduleUseCase updateSchedule,
    required DeleteScheduleUseCase deleteSchedule,
    required ToggleScheduleActiveUseCase toggleScheduleActive,
    bool enableTimer = true,
  })  : _getSchedules = getSchedules,
        _createSchedule = createSchedule,
        _updateSchedule = updateSchedule,
        _deleteSchedule = deleteSchedule,
        _toggleScheduleActive = toggleScheduleActive,
        super(const ScheduleInitial()) {
    on<LoadSchedulesEvent>(_onLoadSchedules);
    on<CreateScheduleEvent>(_onCreateSchedule);
    on<UpdateScheduleEvent>(_onUpdateSchedule);
    on<ToggleScheduleEvent>(_onToggleSchedule);
    on<DeleteScheduleEvent>(_onDeleteSchedule);
    on<EvaluateSchedulesEvent>(_onEvaluateSchedules);

    // Periodic evaluation every 60 seconds to re-evaluate active schedule boundaries
    if (enableTimer) {
      _ticker = Timer.periodic(const Duration(seconds: 60), (_) {
        add(const EvaluateSchedulesEvent());
      });
    }
  }

  final GetSchedulesUseCase _getSchedules;
  final CreateScheduleUseCase _createSchedule;
  final UpdateScheduleUseCase _updateSchedule;
  final DeleteScheduleUseCase _deleteSchedule;
  final ToggleScheduleActiveUseCase _toggleScheduleActive;
  Timer? _ticker;

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }

  Future<void> _onLoadSchedules(
    LoadSchedulesEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(const ScheduleLoading());
    final result = await _getSchedules(const NoParams());
    result.fold(
      (failure) => emit(ScheduleError(failure.message)),
      (schedules) => emit(_buildLoadedState(schedules)),
    );
  }

  Future<void> _onCreateSchedule(
    CreateScheduleEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    final currentState = state;
    final result = await _createSchedule(CreateScheduleParams(event.schedule));
    result.fold(
      (failure) => emit(ScheduleError(failure.message)),
      (newSchedule) {
        if (currentState is ScheduleLoaded) {
          final updated = [...currentState.allSchedules, newSchedule];
          emit(_buildLoadedState(updated));
        } else {
          emit(_buildLoadedState([newSchedule]));
        }
      },
    );
  }

  Future<void> _onUpdateSchedule(
    UpdateScheduleEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    final currentState = state;
    final result = await _updateSchedule(UpdateScheduleParams(event.schedule));
    result.fold(
      (failure) => emit(ScheduleError(failure.message)),
      (updatedSchedule) {
        if (currentState is ScheduleLoaded) {
          final updated = currentState.allSchedules
              .map((s) => s.id == updatedSchedule.id ? updatedSchedule : s)
              .toList();
          emit(_buildLoadedState(updated));
        }
      },
    );
  }

  Future<void> _onToggleSchedule(
    ToggleScheduleEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ScheduleLoaded) return;

    // Optimistically update
    final optimisticList = currentState.allSchedules
        .map((s) => s.id == event.id ? s.copyWith(isEnabled: event.isEnabled) : s)
        .toList();
    emit(_buildLoadedState(optimisticList));

    final result = await _toggleScheduleActive(
      ToggleScheduleActiveParams(id: event.id, isEnabled: event.isEnabled),
    );
    result.fold(
      (failure) => emit(_buildLoadedState(currentState.allSchedules)),
      (_) {},
    );
  }

  Future<void> _onDeleteSchedule(
    DeleteScheduleEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ScheduleLoaded) return;

    // Optimistically delete
    final optimisticList =
        currentState.allSchedules.where((s) => s.id != event.id).toList();
    emit(_buildLoadedState(optimisticList));

    final result = await _deleteSchedule(DeleteScheduleParams(event.id));
    result.fold(
      (failure) => emit(_buildLoadedState(currentState.allSchedules)),
      (_) {},
    );
  }

  void _onEvaluateSchedules(
    EvaluateSchedulesEvent event,
    Emitter<ScheduleState> emit,
  ) {
    final currentState = state;
    if (currentState is! ScheduleLoaded) return;
    emit(_buildLoadedState(currentState.allSchedules, event.evaluationTime));
  }

  ScheduleLoaded _buildLoadedState(
    List<ScheduleEntity> schedules, [
    DateTime? evalTime,
  ]) {
    final now = evalTime ?? DateTime.now();
    final active = <ScheduleEntity>[];
    final activePackages = <String>{};

    for (final schedule in schedules) {
      if (schedule.isCurrentlyActive(now)) {
        active.add(schedule);
        activePackages.addAll(schedule.targetPackages);
      }
    }

    return ScheduleLoaded(
      allSchedules: List.unmodifiable(schedules),
      activeSchedules: List.unmodifiable(active),
      activeBlockedPackages: Set.unmodifiable(activePackages),
    );
  }
}
