// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/block_schedule_entity.dart';
import '../../domain/usecases/can_schedule_exact_alarms_usecase.dart';
import '../../domain/usecases/delete_schedule_usecase.dart';
import '../../domain/usecases/get_assigned_packages_usecase.dart';
import '../../domain/usecases/get_schedules_usecase.dart';
import '../../domain/usecases/request_exact_alarm_permission_usecase.dart';
import '../../domain/usecases/save_schedule_usecase.dart';
import '../../domain/usecases/toggle_schedule_usecase.dart';
import 'schedule_event.dart';
import 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  ScheduleBloc({
    required GetSchedulesUseCase getSchedules,
    required SaveScheduleUseCase saveSchedule,
    required DeleteScheduleUseCase deleteSchedule,
    required ToggleScheduleUseCase toggleSchedule,
    required GetAssignedPackagesUseCase getAssignedPackages,
    required CanScheduleExactAlarmsUseCase canScheduleExactAlarms,
    required RequestExactAlarmPermissionUseCase requestExactAlarmPermission,
  })  : _getSchedules = getSchedules,
        _saveSchedule = saveSchedule,
        _deleteSchedule = deleteSchedule,
        _toggleSchedule = toggleSchedule,
        _getAssignedPackages = getAssignedPackages,
        _canScheduleExactAlarms = canScheduleExactAlarms,
        _requestExactAlarmPermission = requestExactAlarmPermission,
        super(const ScheduleInitial()) {
    on<LoadSchedulesEvent>(_onLoadSchedules);
    on<SaveScheduleEvent>(_onSaveSchedule);
    on<DeleteScheduleEvent>(_onDeleteSchedule);
    on<ToggleScheduleEvent>(_onToggleSchedule);
    on<RequestExactAlarmPermissionEvent>(_onRequestExactAlarmPermission);
  }

  final GetSchedulesUseCase _getSchedules;
  final SaveScheduleUseCase _saveSchedule;
  final DeleteScheduleUseCase _deleteSchedule;
  final ToggleScheduleUseCase _toggleSchedule;
  final GetAssignedPackagesUseCase _getAssignedPackages;
  final CanScheduleExactAlarmsUseCase _canScheduleExactAlarms;
  final RequestExactAlarmPermissionUseCase _requestExactAlarmPermission;

  Future<void> _onLoadSchedules(
    LoadSchedulesEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    if (state is! ScheduleLoaded) {
      emit(const ScheduleLoading());
    }

    final schedulesResult = await _getSchedules(const NoParams());
    final assignedResult = await _getAssignedPackages(const GetAssignedPackagesParams());
    final exactAlarmResult = await _canScheduleExactAlarms(const NoParams());

    final canSchedule = exactAlarmResult.getOrElse(() => true);
    final assignedPackages = assignedResult.getOrElse(() => const {});

    schedulesResult.fold(
      (failure) => emit(ScheduleError(
        message: failure.message,
        canScheduleExactAlarms: canSchedule,
      )),
      (schedules) {
        emit(ScheduleLoaded(
          schedules: schedules,
          assignedPackages: assignedPackages,
          canScheduleExactAlarms: canSchedule,
        ));
      },
    );
  }

  Future<void> _onSaveSchedule(
    SaveScheduleEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    final currentSchedules = _getCurrentSchedules();
    final currentAssigned = _getCurrentAssigned();
    final currentCanSchedule = _getCurrentCanSchedule();

    final result = await _saveSchedule(SaveScheduleParams(event.schedule));

    await result.fold(
      (failure) async {
        emit(ScheduleError(
          message: failure.message,
          schedules: currentSchedules,
          assignedPackages: currentAssigned,
          canScheduleExactAlarms: currentCanSchedule,
        ));
      },
      (_) async {
        final reloadedSchedules = await _getSchedules(const NoParams());
        final reloadedAssigned =
            await _getAssignedPackages(const GetAssignedPackagesParams());

        final schedules = reloadedSchedules.getOrElse(() => currentSchedules);
        final assigned = reloadedAssigned.getOrElse(() => currentAssigned);

        emit(ScheduleLoaded(
          schedules: schedules,
          assignedPackages: assigned,
          canScheduleExactAlarms: currentCanSchedule,
          actionMessage: 'Schedule "${event.schedule.name.isEmpty ? 'Schedule' : event.schedule.name}" saved successfully',
        ));
      },
    );
  }

  Future<void> _onDeleteSchedule(
    DeleteScheduleEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    final currentSchedules = _getCurrentSchedules();
    final currentAssigned = _getCurrentAssigned();
    final currentCanSchedule = _getCurrentCanSchedule();

    final result = await _deleteSchedule(DeleteScheduleParams(event.id));

    await result.fold(
      (failure) async {
        emit(ScheduleError(
          message: failure.message,
          schedules: currentSchedules,
          assignedPackages: currentAssigned,
          canScheduleExactAlarms: currentCanSchedule,
        ));
      },
      (_) async {
        final reloadedSchedules = await _getSchedules(const NoParams());
        final reloadedAssigned =
            await _getAssignedPackages(const GetAssignedPackagesParams());

        final schedules = reloadedSchedules.getOrElse(() => currentSchedules);
        final assigned = reloadedAssigned.getOrElse(() => currentAssigned);

        emit(ScheduleLoaded(
          schedules: schedules,
          assignedPackages: assigned,
          canScheduleExactAlarms: currentCanSchedule,
          actionMessage: 'Schedule deleted',
        ));
      },
    );
  }

  Future<void> _onToggleSchedule(
    ToggleScheduleEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    final currentSchedules = _getCurrentSchedules();
    final currentAssigned = _getCurrentAssigned();
    final currentCanSchedule = _getCurrentCanSchedule();

    final result = await _toggleSchedule(
      ToggleScheduleParams(id: event.id, isEnabled: event.isEnabled),
    );

    await result.fold(
      (failure) async {
        emit(ScheduleError(
          message: failure.message,
          schedules: currentSchedules,
          assignedPackages: currentAssigned,
          canScheduleExactAlarms: currentCanSchedule,
        ));
      },
      (_) async {
        final reloadedSchedules = await _getSchedules(const NoParams());
        final reloadedAssigned =
            await _getAssignedPackages(const GetAssignedPackagesParams());

        final schedules = reloadedSchedules.getOrElse(() => currentSchedules);
        final assigned = reloadedAssigned.getOrElse(() => currentAssigned);

        emit(ScheduleLoaded(
          schedules: schedules,
          assignedPackages: assigned,
          canScheduleExactAlarms: currentCanSchedule,
        ));
      },
    );
  }

  Future<void> _onRequestExactAlarmPermission(
    RequestExactAlarmPermissionEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    await _requestExactAlarmPermission(const NoParams());
    final check = await _canScheduleExactAlarms(const NoParams());
    final canSchedule = check.getOrElse(() => true);

    if (state is ScheduleLoaded) {
      final loaded = state as ScheduleLoaded;
      emit(loaded.copyWith(canScheduleExactAlarms: canSchedule));
    } else if (state is ScheduleError) {
      final err = state as ScheduleError;
      emit(ScheduleError(
        message: err.message,
        schedules: err.schedules,
        assignedPackages: err.assignedPackages,
        canScheduleExactAlarms: canSchedule,
      ));
    }
  }

  List<BlockScheduleEntity> _getCurrentSchedules() {
    if (state is ScheduleLoaded) {
      return (state as ScheduleLoaded).schedules;
    }
    if (state is ScheduleError) {
      return (state as ScheduleError).schedules;
    }
    return const [];
  }

  Map<String, String> _getCurrentAssigned() {
    if (state is ScheduleLoaded) {
      return (state as ScheduleLoaded).assignedPackages;
    }
    if (state is ScheduleError) {
      return (state as ScheduleError).assignedPackages;
    }
    return const {};
  }

  bool _getCurrentCanSchedule() {
    if (state is ScheduleLoaded) {
      return (state as ScheduleLoaded).canScheduleExactAlarms;
    }
    if (state is ScheduleError) {
      return (state as ScheduleError).canScheduleExactAlarms;
    }
    return true;
  }
}
