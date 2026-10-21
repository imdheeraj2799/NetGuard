import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/app_blocker/data/datasources/app_local_data_source.dart';
import '../../features/app_blocker/data/datasources/installed_apps_data_source.dart';
import '../../features/app_blocker/data/datasources/local_storage_data_source.dart';
import '../../features/app_blocker/data/datasources/native_app_data_source.dart';
import '../../features/app_blocker/data/repositories/app_blocker_repository_impl.dart';
import '../../features/app_blocker/domain/repositories/app_blocker_repository.dart';
import '../../features/app_blocker/domain/usecases/get_installed_apps_usecase.dart';
import '../../features/app_blocker/domain/usecases/toggle_block_status_usecase.dart';
import '../../features/app_blocker/presentation/bloc/app_blocker_bloc.dart';

final serviceLocator = GetIt.instance;

Future<void> initializeDependencies({
  Box<Map>? appsBox,
  Box<dynamic>? settingsBox,
}) async {
  if (serviceLocator.isRegistered<AppBlockerBloc>()) return;

  final preferences = await SharedPreferences.getInstance();
  final resolvedAppsBox =
      appsBox ?? await Hive.openBox<Map>(AppLocalDataSourceImpl.appsBoxName);
  final resolvedSettingsBox =
      settingsBox ??
      await Hive.openBox<dynamic>(AppLocalDataSourceImpl.settingsBoxName);

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
    ..registerLazySingleton<AppBlockerRepository>(
      () => AppBlockerRepositoryImpl(
        installedAppsDataSource: serviceLocator(),
        nativeDataSource: serviceLocator(),
        localStorageDataSource: serviceLocator(),
        appLocalDataSource: serviceLocator(),
      ),
    )
    ..registerLazySingleton(() => GetInstalledAppsUseCase(serviceLocator()))
    ..registerLazySingleton(() => ToggleBlockStatusUseCase(serviceLocator()))
    ..registerFactory(
      () => AppBlockerBloc(
        getInstalledApps: serviceLocator(),
        toggleBlockStatus: serviceLocator(),
      ),
    );
}
