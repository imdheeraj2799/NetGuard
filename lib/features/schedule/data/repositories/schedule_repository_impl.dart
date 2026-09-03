// ignore_for_file: prefer_initializing_formals

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/schedule_entity.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../datasources/schedule_local_data_source.dart';
import '../datasources/schedule_native_data_source.dart';
import '../models/schedule_model.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  const ScheduleRepositoryImpl({
    required ScheduleLocalDataSource localDataSource,
    required ScheduleNativeDataSource nativeDataSource,
  })  : _localDataSource = localDataSource,
        _nativeDataSource = nativeDataSource;

  final ScheduleLocalDataSource _localDataSource;
  final ScheduleNativeDataSource _nativeDataSource;

  @override
  Future<Either<Failure, List<ScheduleEntity>>> getSchedules() async {
    try {
      final models = await _localDataSource.getSchedules();
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on ScheduleLocalDataSourceException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error loading schedules: $e'));
    }
  }

  @override
  Future<Either<Failure, ScheduleEntity>> createSchedule(
    ScheduleEntity schedule,
  ) async {
    try {
      final model = ScheduleModel.fromEntity(schedule);
      final created = await _localDataSource.createSchedule(model);
      await _syncActivePackages();
      return Right(created.toEntity());
    } on ScheduleLocalDataSourceException catch (e) {
      return Left(CacheFailure(e.message));
    } on ScheduleNativeDataSourceException catch (e) {
      return Left(PlatformFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to create schedule: $e'));
    }
  }

  @override
  Future<Either<Failure, ScheduleEntity>> updateSchedule(
    ScheduleEntity schedule,
  ) async {
    try {
      final model = ScheduleModel.fromEntity(schedule);
      final updated = await _localDataSource.updateSchedule(model);
      await _syncActivePackages();
      return Right(updated.toEntity());
    } on ScheduleLocalDataSourceException catch (e) {
      return Left(CacheFailure(e.message));
    } on ScheduleNativeDataSourceException catch (e) {
      return Left(PlatformFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to update schedule: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSchedule(String id) async {
    try {
      await _localDataSource.deleteSchedule(id);
      await _syncActivePackages();
      return const Right(null);
    } on ScheduleLocalDataSourceException catch (e) {
      return Left(CacheFailure(e.message));
    } on ScheduleNativeDataSourceException catch (e) {
      return Left(PlatformFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to delete schedule: $e'));
    }
  }

  @override
  Future<Either<Failure, ScheduleEntity>> toggleScheduleActive(
    String id,
    bool isEnabled,
  ) async {
    try {
      final toggled = await _localDataSource.toggleSchedule(id, isEnabled);
      await _syncActivePackages();
      return Right(toggled.toEntity());
    } on ScheduleLocalDataSourceException catch (e) {
      return Left(CacheFailure(e.message));
    } on ScheduleNativeDataSourceException catch (e) {
      return Left(PlatformFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to toggle schedule: $e'));
    }
  }

  Future<void> _syncActivePackages() async {
    try {
      final allSchedules = await _localDataSource.getSchedules();
      final now = DateTime.now();
      final activePackages = <String>{};
      for (final schedule in allSchedules) {
        if (schedule.isCurrentlyActive(now)) {
          activePackages.addAll(schedule.targetPackages);
        }
      }
      await _nativeDataSource
          .syncActiveScheduledPackages(activePackages.toList());
    } catch (_) {
      // Gracefully continue; BLoC also emits dynamic evaluation on timers
    }
  }
}
