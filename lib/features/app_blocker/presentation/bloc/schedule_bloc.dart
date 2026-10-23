// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/block_schedule_entity.dart';
import '../../domain/usecases/are_notifications_enabled_usecase.dart';
import '../../domain/usecases/can_schedule_exact_alarms_usecase.dart';
import '../../domain/usecases/delete_schedule_usecase.dart';
import '../../domain/usecases/get_assigned_packages_usecase.dart';
import '../../domain/usecases/get_schedules_usecase.dart';
import '../../domain/usecases/request_exact_alarm_permission_usecase.dart';
import '../../domain/usecases/request_notification_permission_usecase.dart';
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
    AreNotificationsEnabledUseCase? areNotificationsEnabled,
    RequestNotificationPermissionUseCase? requestNotificationPermission,
  })  : _getSchedules = getSchedules,
        _saveSchedule = saveSchedule,
        _deleteSchedule = deleteSchedule,
        _toggleSchedule = toggleSchedule,
        _getAssignedPackages = getAssignedPackages,
        _canScheduleExactAlarms = canScheduleExactAlarms,
        _requestExactAlarmPermission = requestExactAlarmPermission,
        _areNotificationsEnabled = areNotificationsEnabled,
        _requestNotificationPermission = requestNotificationPermission,
        super(const ScheduleInitial()) {
    on<LoadSchedulesEvent>(_onLoadSchedules);
    on<SaveScheduleEvent>(_onSaveSchedule);
    on<DeleteScheduleEvent>(_onDeleteSchedule);
    on<ToggleScheduleEvent>(_onToggleSchedule);
    on<RequestExactAlarmPermissionEvent>(_onRequestExactAlarmPermission);
    on<CheckNotificationPermissionEvent>(_onCheckNotificationPermission);
    on<RequestNotificationPermissionEvent>(_onRequestNotificationPermission);
  }

  final GetSchedulesUseCase _getSchedules;
  final SaveScheduleUseCase _saveSchedule;
  final DeleteScheduleUseCase _deleteSchedule;
  final ToggleScheduleUseCase _toggleSchedule;
  final GetAssignedPackagesUseCase _getAssignedPackages;
  final CanScheduleExactAlarmsUseCase _canScheduleExactAlarms;
  final RequestExactAlarmPermissionUseCase _requestExactAlarmPermission;
  final AreNotificationsEnabledUseCase? _areNotificationsEnabled;
  final RequestNotificationPermissionUseCase? _requestNotificationPermission;

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
    final notifResult = _areNotificationsEnabled != null
        ? await _areNotificationsEnabled(const NoParams())
        : null;

    final canSchedule = exactAlarmResult.getOrElse(() => true);
    final areNotificationsEnabled = notifResult?.getOrElse(() => true) ?? true;
    final assignedPackages = assignedResult.getOrElse(() => const {});

    schedulesResult.fold(
      (failure) => emit(ScheduleError(
        message: failure.message,
        canScheduleExactAlarms: canSchedule,
        areNotificationsEnabled: areNotificationsEnabled,
      )),
      (schedules) {
        emit(ScheduleLoaded(
          schedules: schedules,
          assignedPackages: assignedPackages,
          canScheduleExactAlarms: canSchedule,
          areNotificationsEnabled: areNotificationsEnabled,
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
    final currentAreNotificationsEnabled = _getCurrentAreNotificationsEnabled();

    final result = await _saveSchedule(SaveScheduleParams(event.schedule));

    await result.fold(
      (failure) async {
        emit(ScheduleError(
          message: failure.message,
          schedules: currentSchedules,
          assignedPackages: currentAssigned,
          canScheduleExactAlarms: currentCanSchedule,
          areNotificationsEnabled: currentAreNotificationsEnabled,
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
          areNotificationsEnabled: currentAreNotificationsEnabled,
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
    final currentAreNotificationsEnabled = _getCurrentAreNotificationsEnabled();

    final result = await _deleteSchedule(DeleteScheduleParams(event.id));

    await result.fold(
      (failure) async {
        emit(ScheduleError(
          message: failure.message,
          schedules: currentSchedules,
          assignedPackages: currentAssigned,
          canScheduleExactAlarms: currentCanSchedule,
          areNotificationsEnabled: currentAreNotificationsEnabled,
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
          areNotificationsEnabled: currentAreNotificationsEnabled,
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
    final currentAreNotificationsEnabled = _getCurrentAreNotificationsEnabled();

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
          areNotificationsEnabled: currentAreNotificationsEnabled,
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
          areNotificationsEnabled: currentAreNotificationsEnabled,
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
        areNotificationsEnabled: err.areNotificationsEnabled,
      ));
    }
  }

  Future<void> _onCheckNotificationPermission(
    CheckNotificationPermissionEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    if (_areNotificationsEnabled == null) return;
    final check = await _areNotificationsEnabled(const NoParams());
    final areEnabled = check.getOrElse(() => true);

    if (state is ScheduleLoaded) {
      emit((state as ScheduleLoaded).copyWith(areNotificationsEnabled: areEnabled));
    } else if (state is ScheduleError) {
      final err = state as ScheduleError;
      emit(ScheduleError(
        message: err.message,
        schedules: err.schedules,
        assignedPackages: err.assignedPackages,
        canScheduleExactAlarms: err.canScheduleExactAlarms,
        areNotificationsEnabled: areEnabled,
      ));
    }
  }

  Future<void> _onRequestNotificationPermission(
    RequestNotificationPermissionEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    if (_requestNotificationPermission != null) {
      await _requestNotificationPermission(const NoParams());
    }
    final check = _areNotificationsEnabled != null
        ? await _areNotificationsEnabled(const NoParams())
        : null;
    final areEnabled = check?.getOrElse(() => true) ?? true;

    if (state is ScheduleLoaded) {
      emit((state as ScheduleLoaded).copyWith(areNotificationsEnabled: areEnabled));
    } else if (state is ScheduleError) {
      final err = state as ScheduleError;
      emit(ScheduleError(
        message: err.message,
        schedules: err.schedules,
        assignedPackages: err.assignedPackages,
        canScheduleExactAlarms: err.canScheduleExactAlarms,
        areNotificationsEnabled: areEnabled,
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

  bool _getCurrentAreNotificationsEnabled() {
    if (state is ScheduleLoaded) {
      return (state as ScheduleLoaded).areNotificationsEnabled;
    }
    if (state is ScheduleError) {
      return (state as ScheduleError).areNotificationsEnabled;
    }
    return true;
  }
}
