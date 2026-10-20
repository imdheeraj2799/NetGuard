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

final serviceLocator = GetIt.instance;

Future<void> initializeDependencies() async {
  if (serviceLocator.isRegistered<AppBlockerBloc>()) return;

  final preferences = await SharedPreferences.getInstance();
  serviceLocator
    ..registerLazySingleton<SharedPreferences>(() => preferences)
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
    );
}
