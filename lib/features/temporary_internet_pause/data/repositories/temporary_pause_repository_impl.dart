import 'dart:convert';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../app_blocker/data/datasources/local_storage_data_source.dart';
import '../../../app_blocker/data/datasources/native_app_data_source.dart';
import '../../domain/entities/temporary_pause_entity.dart';
import '../../domain/repositories/temporary_pause_repository.dart';
import '../datasources/temporary_pause_local_data_source.dart';
import '../datasources/temporary_pause_native_data_source.dart';
import '../models/temporary_pause_model.dart';

class TemporaryPauseRepositoryImpl implements TemporaryPauseRepository {
  TemporaryPauseRepositoryImpl({
    required this.localDataSource,
    required this.nativeDataSource,
  });

  final TemporaryPauseLocalDataSource localDataSource;
  final TemporaryPauseNativeDataSource nativeDataSource;

  @override
  Future<Either<Failure, List<TemporaryPauseEntity>>> getActivePauses() async {
    try {
      final now = DateTime.now();
      // Clean up any already expired pauses
      await localDataSource.clearExpiredPauses(currentTime: now);
      final models = await localDataSource.getPauses();
      final entities = models
          .where((m) => !m.isExpired(now))
          .map((m) => m.toEntity())
          .toList(growable: false);
      return Right(entities);
    } on LocalStorageException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Unable to get active temporary pauses: $error'));
    }
  }

  @override
  Future<Either<Failure, TemporaryPauseEntity>> createPause({
    required String packageName,
    required String appName,
    required Duration duration,
    bool isCustom = false,
  }) async {
    try {
      final now = DateTime.now();
      final pauseUntil = now.add(duration);
      final id = 'pause_${packageName}_${now.millisecondsSinceEpoch}';

      final model = TemporaryPauseModel(
        id: id,
        packageName: packageName,
        appName: appName,
        startTime: now,
        pauseUntil: pauseUntil,
        durationMillis: duration.inMilliseconds,
        isCustom: isCustom,
      );

      await localDataSource.savePause(model);
      await _syncToNative();

      return Right(model.toEntity());
    } on LocalStorageException catch (error) {
      return Left(CacheFailure(error.message));
    } on NativeDataSourceException catch (error) {
      return Left(PlatformFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Unable to create temporary pause: $error'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelPause(String id) async {
    try {
      await localDataSource.deletePause(id);
      await _syncToNative();
      return const Right(null);
    } on LocalStorageException catch (error) {
      return Left(CacheFailure(error.message));
    } on NativeDataSourceException catch (error) {
      return Left(PlatformFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Unable to cancel temporary pause: $error'));
    }
  }

  @override
  Future<Either<Failure, List<TemporaryPauseEntity>>> reconcileExpiredPauses({
    DateTime? currentTime,
  }) async {
    try {
      final now = currentTime ?? DateTime.now();
      final expired = await localDataSource.clearExpiredPauses(currentTime: now);
      if (expired.isNotEmpty) {
        await _syncToNative();
      }
      final remaining = await localDataSource.getPauses();
      return Right(remaining.map((m) => m.toEntity()).toList(growable: false));
    } on LocalStorageException catch (error) {
      return Left(CacheFailure(error.message));
    } on NativeDataSourceException catch (error) {
      return Left(PlatformFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Unable to reconcile expired pauses: $error'));
    }
  }

  @override
  Future<Either<Failure, Set<String>>> getActivePausedPackages({
    DateTime? currentTime,
  }) async {
    try {
      final now = currentTime ?? DateTime.now();
      final models = await localDataSource.getPauses();
      final active = models
          .where((m) => !m.isExpired(now))
          .map((m) => m.packageName)
          .toSet();
      return Right(active);
    } on LocalStorageException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Unable to get active paused packages: $error'));
    }
  }

  Future<void> _syncToNative() async {
    try {
      final all = await localDataSource.getPauses();
      final maps = all.map((m) => m.toMap()).toList(growable: false);
      await nativeDataSource.syncTemporaryPauses(jsonEncode(maps));
    } catch (_) {
      // Non-fatal background sync
    }
  }
}
