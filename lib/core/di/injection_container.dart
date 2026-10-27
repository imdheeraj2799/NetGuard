import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/app_blocker/data/datasources/app_local_data_source.dart';
import '../../features/app_blocker/data/datasources/installed_apps_data_source.dart';
import '../../features/app_blocker/data/datasources/local_storage_data_source.dart';
import '../../features/app_blocker/data/datasources/native_app_data_source.dart';
import '../../features/app_blocker/data/datasources/schedule_local_data_source.dart';
import '../../features/app_blocker/data/repositories/app_blocker_repository_impl.dart';
import '../../features/app_blocker/data/repositories/schedule_repository_impl.dart';
import '../../features/app_blocker/domain/repositories/app_blocker_repository.dart';
import '../../features/app_blocker/domain/repositories/schedule_repository.dart';
import '../../features/app_blocker/domain/services/firewall_rule_engine.dart';
import '../../features/app_blocker/domain/services/schedule_conflict_validator.dart';
import '../../features/app_blocker/domain/services/schedule_engine.dart';
import '../../features/app_blocker/domain/usecases/are_notifications_enabled_usecase.dart';
import '../../features/app_blocker/domain/usecases/can_schedule_exact_alarms_usecase.dart';
import '../../features/app_blocker/domain/usecases/delete_schedule_usecase.dart';
import '../../features/app_blocker/domain/usecases/get_assigned_packages_usecase.dart';
import '../../features/app_blocker/domain/usecases/get_effective_blocked_packages_usecase.dart';
import '../../features/app_blocker/domain/usecases/get_installed_apps_usecase.dart';
import '../../features/app_blocker/domain/usecases/get_schedules_usecase.dart';
import '../../features/app_blocker/domain/usecases/get_vpn_status_usecase.dart';
import '../../features/app_blocker/domain/usecases/request_exact_alarm_permission_usecase.dart';
import '../../features/app_blocker/domain/usecases/request_notification_permission_usecase.dart';
import '../../features/app_blocker/domain/usecases/restart_vpn_usecase.dart';
import '../../features/app_blocker/domain/usecases/save_schedule_usecase.dart';
import '../../features/app_blocker/domain/usecases/sync_schedules_usecase.dart';
import '../../features/app_blocker/domain/usecases/toggle_block_status_usecase.dart';
import '../../features/app_blocker/domain/usecases/toggle_schedule_usecase.dart';
import '../../features/app_blocker/domain/usecases/watch_vpn_status_usecase.dart';
import '../../features/app_blocker/presentation/bloc/app_blocker_bloc.dart';
import '../../features/app_blocker/presentation/bloc/schedule_bloc.dart';

import '../../features/temporary_internet_pause/data/datasources/temporary_pause_local_data_source.dart';
import '../../features/temporary_internet_pause/data/datasources/temporary_pause_native_data_source.dart';
import '../../features/temporary_internet_pause/data/repositories/temporary_pause_repository_impl.dart';
import '../../features/temporary_internet_pause/domain/repositories/temporary_pause_repository.dart';
import '../../features/temporary_internet_pause/domain/usecases/cancel_temporary_pause_usecase.dart';
import '../../features/temporary_internet_pause/domain/usecases/create_temporary_pause_usecase.dart';
import '../../features/temporary_internet_pause/domain/usecases/get_active_pauses_usecase.dart';
import '../../features/temporary_internet_pause/domain/usecases/reconcile_expired_pauses_usecase.dart';
import '../../features/temporary_internet_pause/presentation/bloc/temporary_pause_bloc.dart';

final serviceLocator = GetIt.instance;

Future<void> initializeDependencies({
  Box<Map>? appsBox,
  Box<dynamic>? settingsBox,
  Box<Map>? schedulesBox,
  Box<Map>? temporaryPausesBox,
}) async {
  if (serviceLocator.isRegistered<AppBlockerBloc>()) return;

  final preferences = await SharedPreferences.getInstance();
  final resolvedAppsBox =
      appsBox ?? await Hive.openBox<Map>(AppLocalDataSourceImpl.appsBoxName);
  final resolvedSettingsBox =
      settingsBox ??
      await Hive.openBox<dynamic>(AppLocalDataSourceImpl.settingsBoxName);
  final resolvedSchedulesBox =
      schedulesBox ??
      await Hive.openBox<Map>(ScheduleLocalDataSourceImpl.schedulesBoxName);
  final resolvedPausesBox =
      temporaryPausesBox ??
      await Hive.openBox<Map>(TemporaryPauseLocalDataSourceImpl.pausesBoxName);

  serviceLocator
    ..registerLazySingleton<SharedPreferences>(() => preferences)
    ..registerLazySingleton<Box<Map>>(
      () => resolvedAppsBox,
      instanceName: 'appsBox',
    )
    ..registerLazySingleton<Box<dynamic>>(
      () => resolvedSettingsBox,
      instanceName: 'settingsBox',
    )
    ..registerLazySingleton<Box<Map>>(
      () => resolvedSchedulesBox,
      instanceName: 'schedulesBox',
    )
    ..registerLazySingleton<Box<Map>>(
      () => resolvedPausesBox,
      instanceName: 'temporaryPausesBox',
    )
    ..registerLazySingleton<NativeAppDataSource>(NativeAppDataSourceImpl.new)
    ..registerLazySingleton<InstalledAppsGateway>(InstalledAppsGatewayImpl.new)
    ..registerLazySingleton<InstalledAppsDataSource>(
      () => InstalledAppsDataSourceImpl(serviceLocator()),
    )
    ..registerLazySingleton<LocalStorageDataSource>(
      () => LocalStorageDataSourceImpl(serviceLocator()),
    )
    ..registerLazySingleton<AppLocalDataSource>(
      () => AppLocalDataSourceImpl(
        appsBox: resolvedAppsBox,
        settingsBox: resolvedSettingsBox,
      ),
    )
    ..registerLazySingleton<ScheduleLocalDataSource>(
      () => ScheduleLocalDataSourceImpl(
        schedulesBox: resolvedSchedulesBox,
        preferences: serviceLocator(),
      ),
    )
    ..registerLazySingleton<ScheduleEngine>(ScheduleEngine.new)
    ..registerLazySingleton<ScheduleConflictValidator>(
      ScheduleConflictValidator.new,
    )
    ..registerLazySingleton<FirewallRuleEngine>(
      () => FirewallRuleEngine(scheduleEngine: serviceLocator()),
    )
    ..registerLazySingleton<AppBlockerRepository>(
      () => AppBlockerRepositoryImpl(
        installedAppsDataSource: serviceLocator(),
        nativeDataSource: serviceLocator(),
        localStorageDataSource: serviceLocator(),
        appLocalDataSource: serviceLocator(),
      ),
    )
    ..registerLazySingleton<ScheduleRepository>(
      () => ScheduleRepositoryImpl(
        scheduleLocalDataSource: serviceLocator(),
        localStorageDataSource: serviceLocator(),
        nativeDataSource: serviceLocator(),
        appLocalDataSource: serviceLocator(),
        conflictValidator: serviceLocator(),
        ruleEngine: serviceLocator(),
      ),
    )
    ..registerLazySingleton(() => GetInstalledAppsUseCase(serviceLocator()))
    ..registerLazySingleton(() => ToggleBlockStatusUseCase(serviceLocator()))
    ..registerLazySingleton(() => GetVpnStatusUseCase(serviceLocator()))
    ..registerLazySingleton(() => WatchVpnStatusUseCase(serviceLocator()))
    ..registerLazySingleton(() => RestartVpnUseCase(serviceLocator()))
    ..registerLazySingleton(() => GetSchedulesUseCase(serviceLocator()))
    ..registerLazySingleton(() => SaveScheduleUseCase(serviceLocator()))
    ..registerLazySingleton(() => DeleteScheduleUseCase(serviceLocator()))
    ..registerLazySingleton(() => ToggleScheduleUseCase(serviceLocator()))
    ..registerLazySingleton(
      () => GetEffectiveBlockedPackagesUseCase(serviceLocator()),
    )
    ..registerLazySingleton(() => GetAssignedPackagesUseCase(serviceLocator()))
    ..registerLazySingleton(
      () => CanScheduleExactAlarmsUseCase(serviceLocator()),
    )
    ..registerLazySingleton(
      () => RequestExactAlarmPermissionUseCase(serviceLocator()),
    )
    ..registerLazySingleton(
      () => AreNotificationsEnabledUseCase(serviceLocator()),
    )
    ..registerLazySingleton(
      () => RequestNotificationPermissionUseCase(serviceLocator()),
    )
    ..registerLazySingleton(() => SyncSchedulesUseCase(serviceLocator()))
    ..registerFactory(
      () => AppBlockerBloc(
        getInstalledApps: serviceLocator(),
        toggleBlockStatus: serviceLocator(),
        getVpnStatus: serviceLocator(),
        watchVpnStatus: serviceLocator(),
        restartVpn: serviceLocator(),
      ),
    )
    ..registerFactory(
      () => ScheduleBloc(
        getSchedules: serviceLocator(),
        saveSchedule: serviceLocator(),
        deleteSchedule: serviceLocator(),
        toggleSchedule: serviceLocator(),
        getAssignedPackages: serviceLocator(),
        canScheduleExactAlarms: serviceLocator(),
        requestExactAlarmPermission: serviceLocator(),
        areNotificationsEnabled: serviceLocator(),
        requestNotificationPermission: serviceLocator(),
      ),
    )
    ..registerLazySingleton<TemporaryPauseLocalDataSource>(
      () => TemporaryPauseLocalDataSourceImpl(
        pausesBox: resolvedPausesBox,
        preferences: serviceLocator(),
      ),
    )
    ..registerLazySingleton<TemporaryPauseNativeDataSource>(
      TemporaryPauseNativeDataSourceImpl.new,
    )
    ..registerLazySingleton<TemporaryPauseRepository>(
      () => TemporaryPauseRepositoryImpl(
        localDataSource: serviceLocator(),
        nativeDataSource: serviceLocator(),
      ),
    )
    ..registerLazySingleton(() => GetActivePausesUseCase(serviceLocator()))
    ..registerLazySingleton(() => CreateTemporaryPauseUseCase(serviceLocator()))
    ..registerLazySingleton(() => CancelTemporaryPauseUseCase(serviceLocator()))
    ..registerLazySingleton(() => ReconcileExpiredPausesUseCase(serviceLocator()))
    ..registerFactory(
      () => TemporaryPauseBloc(
        getActivePauses: serviceLocator(),
        createPause: serviceLocator(),
        cancelPause: serviceLocator(),
        reconcileExpiredPauses: serviceLocator(),
      ),
    );
}
