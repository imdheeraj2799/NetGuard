import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/app_blocker/data/datasources/installed_apps_data_source.dart';
import '../../features/app_blocker/data/datasources/local_storage_data_source.dart';
import '../../features/app_blocker/data/datasources/native_app_data_source.dart';
import '../../features/app_blocker/data/repositories/app_blocker_repository_impl.dart';
import '../../features/app_blocker/domain/repositories/app_blocker_repository.dart';
import '../../features/app_blocker/domain/usecases/get_installed_apps_usecase.dart';
import '../../features/app_blocker/domain/usecases/toggle_block_status_usecase.dart';
import '../../features/app_blocker/presentation/bloc/app_blocker_bloc.dart';
import '../../features/domain_filter/data/datasources/domain_local_data_source.dart';
import '../../features/domain_filter/data/datasources/domain_native_data_source.dart';
import '../../features/domain_filter/data/repositories/domain_filter_repository_impl.dart';
import '../../features/domain_filter/domain/repositories/domain_filter_repository.dart';
import '../../features/domain_filter/domain/usecases/add_domain_usecase.dart';
import '../../features/domain_filter/domain/usecases/get_blocked_domains_usecase.dart';
import '../../features/domain_filter/domain/usecases/remove_domain_usecase.dart';
import '../../features/domain_filter/domain/usecases/toggle_domain_usecase.dart';
import '../../features/domain_filter/presentation/bloc/domain_filter_bloc.dart';
import '../../features/schedule/data/datasources/schedule_local_data_source.dart';
import '../../features/schedule/data/datasources/schedule_native_data_source.dart';
import '../../features/schedule/data/repositories/schedule_repository_impl.dart';
import '../../features/schedule/domain/repositories/schedule_repository.dart';
import '../../features/schedule/domain/usecases/create_schedule_usecase.dart';
import '../../features/schedule/domain/usecases/delete_schedule_usecase.dart';
import '../../features/schedule/domain/usecases/get_schedules_usecase.dart';
import '../../features/schedule/domain/usecases/toggle_schedule_active_usecase.dart';
import '../../features/schedule/domain/usecases/update_schedule_usecase.dart';
import '../../features/schedule/presentation/bloc/schedule_bloc.dart';
import '../../features/analytics/data/datasources/analytics_native_data_source.dart';
import '../../features/analytics/data/repositories/analytics_repository_impl.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '../../features/analytics/domain/usecases/check_usage_permission_usecase.dart';
import '../../features/analytics/domain/usecases/get_usage_analytics_usecase.dart';
import '../../features/analytics/domain/usecases/request_usage_permission_usecase.dart';
import '../../features/analytics/presentation/bloc/analytics_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../../features/security/data/datasources/biometric_data_source.dart';
import '../../features/security/data/datasources/security_storage_data_source.dart';
import '../../features/security/data/repositories/security_repository_impl.dart';
import '../../features/security/domain/repositories/security_repository.dart';
import '../../features/security/domain/usecases/authenticate_user_usecase.dart';
import '../../features/security/domain/usecases/get_security_settings_usecase.dart';
import '../../features/security/domain/usecases/set_master_passcode_usecase.dart';
import '../../features/security/domain/usecases/toggle_biometrics_usecase.dart';
import '../../features/security/presentation/bloc/auth_bloc.dart';
import '../../features/system_controls/data/datasources/system_controls_local_data_source.dart';
import '../../features/system_controls/data/datasources/system_controls_native_data_source.dart';
import '../../features/system_controls/data/repositories/system_controls_repository_impl.dart';
import '../../features/system_controls/domain/repositories/system_controls_repository.dart';
import '../../features/system_controls/domain/usecases/get_dns_settings_usecase.dart';
import '../../features/system_controls/domain/usecases/set_dns_resolver_usecase.dart';
import '../../features/system_controls/presentation/bloc/system_controls_bloc.dart';

final serviceLocator = GetIt.instance;

Future<void> initializeDependencies() async {
  if (serviceLocator.isRegistered<AppBlockerBloc>()) return;

  final preferences = await SharedPreferences.getInstance();
  serviceLocator
    ..registerLazySingleton<SharedPreferences>(() => preferences)
    // App Blocker dependencies
    ..registerLazySingleton<NativeAppDataSource>(NativeAppDataSourceImpl.new)
    ..registerLazySingleton<InstalledAppsGateway>(InstalledAppsGatewayImpl.new)
    ..registerLazySingleton<InstalledAppsDataSource>(
      () => InstalledAppsDataSourceImpl(serviceLocator()),
    )
    ..registerLazySingleton<LocalStorageDataSource>(
      () => LocalStorageDataSourceImpl(serviceLocator()),
    )
    ..registerLazySingleton<AppBlockerRepository>(
      () => AppBlockerRepositoryImpl(
        installedAppsDataSource: serviceLocator(),
        nativeDataSource: serviceLocator(),
        localStorageDataSource: serviceLocator(),
      ),
    )
    ..registerLazySingleton(() => GetInstalledAppsUseCase(serviceLocator()))
    ..registerLazySingleton(() => ToggleBlockStatusUseCase(serviceLocator()))
    ..registerFactory(
      () => AppBlockerBloc(
        getInstalledApps: serviceLocator(),
        toggleBlockStatus: serviceLocator(),
      ),
    )
    // Domain Filter dependencies
    ..registerLazySingleton<DomainLocalDataSource>(
      () => DomainLocalDataSourceImpl(serviceLocator()),
    )
    ..registerLazySingleton<DomainNativeDataSource>(
      DomainNativeDataSourceImpl.new,
    )
    ..registerLazySingleton<DomainFilterRepository>(
      () => DomainFilterRepositoryImpl(
        localDataSource: serviceLocator(),
        nativeDataSource: serviceLocator(),
      ),
    )
    ..registerLazySingleton(() => GetBlockedDomainsUseCase(serviceLocator()))
    ..registerLazySingleton(() => AddDomainUseCase(serviceLocator()))
    ..registerLazySingleton(() => ToggleDomainUseCase(serviceLocator()))
    ..registerLazySingleton(() => RemoveDomainUseCase(serviceLocator()))
    ..registerFactory(
      () => DomainFilterBloc(
        getBlockedDomains: serviceLocator(),
        addDomain: serviceLocator(),
        toggleDomain: serviceLocator(),
        removeDomain: serviceLocator(),
      ),
    )
    // Schedule dependencies
    ..registerLazySingleton<ScheduleLocalDataSource>(
      () => ScheduleLocalDataSourceImpl(serviceLocator()),
    )
    ..registerLazySingleton<ScheduleNativeDataSource>(
      ScheduleNativeDataSourceImpl.new,
    )
    ..registerLazySingleton<ScheduleRepository>(
      () => ScheduleRepositoryImpl(
        localDataSource: serviceLocator(),
        nativeDataSource: serviceLocator(),
      ),
    )
    ..registerLazySingleton(() => GetSchedulesUseCase(serviceLocator()))
    ..registerLazySingleton(() => CreateScheduleUseCase(serviceLocator()))
    ..registerLazySingleton(() => UpdateScheduleUseCase(serviceLocator()))
    ..registerLazySingleton(() => DeleteScheduleUseCase(serviceLocator()))
    ..registerLazySingleton(() => ToggleScheduleActiveUseCase(serviceLocator()))
    ..registerFactory(
      () => ScheduleBloc(
        getSchedules: serviceLocator(),
        createSchedule: serviceLocator(),
        updateSchedule: serviceLocator(),
        deleteSchedule: serviceLocator(),
        toggleScheduleActive: serviceLocator(),
      ),
    )
    // Analytics dependencies
    ..registerLazySingleton<AnalyticsNativeDataSource>(
      AnalyticsNativeDataSourceImpl.new,
    )
    ..registerLazySingleton<AnalyticsRepository>(
      () => AnalyticsRepositoryImpl(serviceLocator()),
    )
    ..registerLazySingleton(() => CheckUsagePermissionUseCase(serviceLocator()))
    ..registerLazySingleton(() => RequestUsagePermissionUseCase(serviceLocator()))
    ..registerLazySingleton(() => GetUsageAnalyticsUseCase(serviceLocator()))
    ..registerFactory(
      () => AnalyticsBloc(
        checkUsagePermission: serviceLocator(),
        requestUsagePermission: serviceLocator(),
        getUsageAnalytics: serviceLocator(),
      ),
    )
    // Security & Auth dependencies
    ..registerLazySingleton(() => const FlutterSecureStorage())
    ..registerLazySingleton(() => LocalAuthentication())
    ..registerLazySingleton<SecurityStorageDataSource>(
      () => SecurityStorageDataSourceImpl(serviceLocator()),
    )
    ..registerLazySingleton<BiometricDataSource>(
      () => BiometricDataSourceImpl(serviceLocator()),
    )
    ..registerLazySingleton<SecurityRepository>(
      () => SecurityRepositoryImpl(
        storageDataSource: serviceLocator(),
        biometricDataSource: serviceLocator(),
      ),
    )
    ..registerLazySingleton(() => AuthenticateUserUseCase(serviceLocator()))
    ..registerLazySingleton(() => SetMasterPasscodeUseCase(serviceLocator()))
    ..registerLazySingleton(() => ToggleBiometricsUseCase(serviceLocator()))
    ..registerLazySingleton(() => GetSecuritySettingsUseCase(serviceLocator()))
    ..registerFactory(
      () => AuthBloc(
        authenticateUser: serviceLocator(),
        setMasterPasscode: serviceLocator(),
        toggleBiometrics: serviceLocator(),
        getSecuritySettings: serviceLocator(),
      ),
    )
    // System Controls dependencies
    ..registerLazySingleton<SystemControlsLocalDataSource>(
      () => SystemControlsLocalDataSourceImpl(serviceLocator()),
    )
    ..registerLazySingleton<SystemControlsNativeDataSource>(
      SystemControlsNativeDataSourceImpl.new,
    )
    ..registerLazySingleton<SystemControlsRepository>(
      () => SystemControlsRepositoryImpl(
        localDataSource: serviceLocator(),
        nativeDataSource: serviceLocator(),
      ),
    )
    ..registerLazySingleton(() => GetDnsSettingsUseCase(serviceLocator()))
    ..registerLazySingleton(() => SetDnsResolverUseCase(serviceLocator()))
    ..registerFactory(
      () => SystemControlsBloc(
        getDnsSettings: serviceLocator(),
        setDnsResolver: serviceLocator(),
      ),
    );
}
