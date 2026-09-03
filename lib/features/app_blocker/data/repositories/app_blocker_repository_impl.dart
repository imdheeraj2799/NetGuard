import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/app_info_entity.dart';
import '../../domain/repositories/app_blocker_repository.dart';
import '../datasources/installed_apps_data_source.dart';
import '../datasources/local_storage_data_source.dart';
import '../datasources/native_app_data_source.dart';

class AppBlockerRepositoryImpl implements AppBlockerRepository {
  AppBlockerRepositoryImpl({
    required InstalledAppsDataSource installedAppsDataSource,
    required NativeAppDataSource nativeDataSource,
    required LocalStorageDataSource localStorageDataSource,
  }) : _installedAppsDataSource = installedAppsDataSource,
       _nativeDataSource = nativeDataSource,
       _localStorageDataSource = localStorageDataSource;

  final InstalledAppsDataSource _installedAppsDataSource;
  final NativeAppDataSource _nativeDataSource;
  final LocalStorageDataSource _localStorageDataSource;

  @override
  Future<Either<Failure, List<AppInfoEntity>>> getInstalledApps() async {
    try {
      final results = await Future.wait<dynamic>([
        _installedAppsDataSource.getInstalledApps(),
        _localStorageDataSource.getBlockedPackages(),
      ]);
      final apps = results[0] as List<AppInfoEntity>;
      final blocked = (results[1] as List<String>).toSet();
      return Right(
        apps
            .map(
              (app) =>
                  app.copyWith(isBlocked: blocked.contains(app.packageName)),
            )
            .toList(growable: false),
      );
    } on InstalledAppsException catch (error) {
      return Left(PlatformFailure(error.message));
    } on LocalStorageException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Unable to get installed apps: $error'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleBlockStatus({
    required String packageName,
    required bool isBlocked,
  }) async {
    try {
      final current = await _localStorageDataSource.getBlockedPackages();
      final updated = current.toSet();
      isBlocked ? updated.add(packageName) : updated.remove(packageName);
      if (updated.isEmpty) {
        await _nativeDataSource.stopVpnService();
      } else {
        await _nativeDataSource.updateBlockedList(
          updated.toList(growable: false),
        );
      }
      await _localStorageDataSource.setBlockedPackages(updated.toList());
      return const Right(null);
    } on NativeDataSourceException catch (error) {
      return Left(PlatformFailure(error.message));
    } on LocalStorageException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Unable to update block status: $error'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getBlockedPackages() async {
    try {
      return Right(await _localStorageDataSource.getBlockedPackages());
    } on LocalStorageException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Unable to get blocked packages: $error'));
    }
  }
}
// Public dependency names are intentionally retained for ergonomic composition.
// ignore_for_file: prefer_initializing_formals
