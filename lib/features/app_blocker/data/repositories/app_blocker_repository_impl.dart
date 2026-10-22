import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/app_info_entity.dart';
import '../../domain/entities/vpn_status_entity.dart';
import '../../domain/repositories/app_blocker_repository.dart';
import '../datasources/app_local_data_source.dart';
import '../datasources/installed_apps_data_source.dart';
import '../datasources/local_storage_data_source.dart';
import '../datasources/native_app_data_source.dart';
import '../models/app_info_model.dart';

class AppBlockerRepositoryImpl implements AppBlockerRepository {
  AppBlockerRepositoryImpl({
    required InstalledAppsDataSource installedAppsDataSource,
    required NativeAppDataSource nativeDataSource,
    required LocalStorageDataSource localStorageDataSource,
    required AppLocalDataSource appLocalDataSource,
  }) : _installedAppsDataSource = installedAppsDataSource,
       _nativeDataSource = nativeDataSource,
       _localStorageDataSource = localStorageDataSource,
       _appLocalDataSource = appLocalDataSource;

  final InstalledAppsDataSource _installedAppsDataSource;
  final NativeAppDataSource _nativeDataSource;
  final LocalStorageDataSource _localStorageDataSource;
  final AppLocalDataSource _appLocalDataSource;

  @override
  Future<Either<Failure, List<AppInfoEntity>>> getInstalledApps() async {
    try {
      final isFirst = await _appLocalDataSource.isFirstLaunch();
      if (isFirst) {
        return await _handleFirstLaunch();
      } else {
        return await _handleSubsequentLaunch();
      }
    } on InstalledAppsException catch (error) {
      return Left(PlatformFailure(error.message));
    } on LocalStorageException catch (error) {
      return Left(CacheFailure(error.message));
    } on NativeDataSourceException catch (error) {
      return Left(PlatformFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Unable to get installed apps: $error'));
    }
  }

  Future<Either<Failure, List<AppInfoEntity>>> _handleFirstLaunch() async {
    final results = await Future.wait<dynamic>([
      _installedAppsDataSource.getInstalledApps(),
      _localStorageDataSource.getBlockedPackages(),
    ]);
    final deviceApps = results[0] as List<AppInfoModel>;
    final blocked = (results[1] as List<String>).toSet();

    final appsToCache = deviceApps
        .map(
          (app) => app.copyWith(isBlocked: blocked.contains(app.packageName)),
        )
        .toList(growable: false);

    await _appLocalDataSource.cacheApps(appsToCache);
    await _appLocalDataSource.setFirstLaunchCompleted();

    final cached = await _appLocalDataSource.getCachedApps();
    return Right(cached.map((m) => m.toEntity()).toList(growable: false));
  }

  Future<Either<Failure, List<AppInfoEntity>>> _handleSubsequentLaunch() async {
    final cachedApps = await _appLocalDataSource.getCachedApps();
    if (cachedApps.isEmpty) {
      return _handleFirstLaunch();
    }

    final deviceApps = await _installedAppsDataSource.getInstalledApps();
    final currentBlocked = (await _localStorageDataSource.getBlockedPackages()).toSet();

    final cachedMap = {for (final a in cachedApps) a.packageName: a};
    final deviceMap = {for (final a in deviceApps) a.packageName: a};

    // 1. Detect uninstalled / deleted applications (in cache, but not on device)
    final uninstalledPackageNames = cachedMap.keys
        .where((pkg) => !deviceMap.containsKey(pkg))
        .toList(growable: false);

    if (uninstalledPackageNames.isNotEmpty) {
      await _appLocalDataSource.deleteApps(uninstalledPackageNames);
      final hadBlockedUninstalled = uninstalledPackageNames.any(currentBlocked.contains);
      if (hadBlockedUninstalled) {
        currentBlocked.removeAll(uninstalledPackageNames);
        await _localStorageDataSource.setBlockedPackages(currentBlocked.toList(growable: false));
        await _nativeDataSource.updateBlockedList(currentBlocked.toList(growable: false));
      }
    }

    // 2. Detect newly installed applications (on device, but not in cache)
    final newPackageNames = deviceMap.keys
        .where((pkg) => !cachedMap.containsKey(pkg))
        .toList(growable: false);

    if (newPackageNames.isNotEmpty) {
      final newApps = newPackageNames.map((pkg) {
        final deviceApp = deviceMap[pkg]!;
        return deviceApp.copyWith(isBlocked: currentBlocked.contains(pkg));
      }).toList(growable: false);
      await _appLocalDataSource.cacheApps(newApps);
    }

    // 3. Update existing applications' metadata (name/icon) while preserving block status
    for (final pkg in cachedMap.keys) {
      if (deviceMap.containsKey(pkg)) {
        final cached = cachedMap[pkg]!;
        final device = deviceMap[pkg]!;
        if (cached.appName != device.appName || cached.iconBytes != device.iconBytes) {
          await _appLocalDataSource.saveApp(
            cached.copyWith(
              appName: device.appName,
              iconBytes: device.iconBytes,
            ),
          );
        }
      }
    }

    final freshCached = await _appLocalDataSource.getCachedApps();
    return Right(freshCached.map((m) => m.toEntity()).toList(growable: false));
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
      await _nativeDataSource.updateBlockedList(
        updated.toList(growable: false),
      );
      await _localStorageDataSource.setBlockedPackages(updated.toList(growable: false));

      // Also persist updated block status to local Hive storage
      final cachedApps = await _appLocalDataSource.getCachedApps();
      for (final app in cachedApps) {
        if (app.packageName == packageName) {
          await _appLocalDataSource.saveApp(app.copyWith(isBlocked: isBlocked));
          break;
        }
      }

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

  @override
  Future<Either<Failure, VpnStatusInfo>> getVpnStatus() async {
    try {
      final status = await _nativeDataSource.getVpnStatus();
      return Right(status);
    } on NativeDataSourceException catch (error) {
      return Left(PlatformFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Unable to get VPN status: $error'));
    }
  }

  @override
  Stream<VpnStatusInfo> get vpnStatusStream => _nativeDataSource.vpnStatusStream;

  @override
  Future<Either<Failure, void>> restartVpn() async {
    try {
      await _nativeDataSource.restartVpn();
      return const Right(null);
    } on NativeDataSourceException catch (error) {
      return Left(PlatformFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Unable to restart VPN service: $error'));
    }
  }
}
// Public dependency names are intentionally retained for ergonomic composition.
// ignore_for_file: prefer_initializing_formals
