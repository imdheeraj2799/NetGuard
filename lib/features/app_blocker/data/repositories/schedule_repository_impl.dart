import 'dart:convert';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/block_schedule_entity.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../domain/services/firewall_rule_engine.dart';
import '../../domain/services/schedule_conflict_validator.dart';
import '../datasources/app_local_data_source.dart';
import '../datasources/local_storage_data_source.dart';
import '../datasources/native_app_data_source.dart';
import '../datasources/schedule_local_data_source.dart';
import '../models/block_schedule_model.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  ScheduleRepositoryImpl({
    required ScheduleLocalDataSource scheduleLocalDataSource,
    required LocalStorageDataSource localStorageDataSource,
    required NativeAppDataSource nativeDataSource,
    AppLocalDataSource? appLocalDataSource,
    ScheduleConflictValidator conflictValidator = const ScheduleConflictValidator(),
    FirewallRuleEngine ruleEngine = const FirewallRuleEngine(),
  })  : _scheduleLocalDataSource = scheduleLocalDataSource,
        _localStorageDataSource = localStorageDataSource,
        _nativeDataSource = nativeDataSource,
        _appLocalDataSource = appLocalDataSource,
        _conflictValidator = conflictValidator,
        _ruleEngine = ruleEngine;

  final ScheduleLocalDataSource _scheduleLocalDataSource;
  final LocalStorageDataSource _localStorageDataSource;
  final NativeAppDataSource _nativeDataSource;
  final AppLocalDataSource? _appLocalDataSource;
  final ScheduleConflictValidator _conflictValidator;
  final FirewallRuleEngine _ruleEngine;

  @override
  Future<Either<Failure, List<BlockScheduleEntity>>> getSchedules() async {
    try {
      final models = await _scheduleLocalDataSource.getSchedules();
      return Right(models.map((m) => m.toEntity()).toList(growable: false));
    } on LocalStorageException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Unable to get schedules: $error'));
    }
  }

  @override
  Future<Either<Failure, void>> saveSchedule(BlockScheduleEntity schedule) async {
    try {
      final existingModels = await _scheduleLocalDataSource.getSchedules();
      final existingEntities = existingModels.map((m) => m.toEntity()).toList();

      final validation = _conflictValidator.validateSchedule(
        schedule: schedule,
        existingSchedules: existingEntities,
      );

      if (!validation.isValid) {
        return Left(ValidationFailure(validation.errorMessage ?? 'Schedule validation failed'));
      }

      await _scheduleLocalDataSource.saveSchedule(
        BlockScheduleModel.fromEntity(schedule),
      );

      await _syncAppScheduleRestrictions();
      await _syncEffectiveBlockedListToVpn();
      return const Right(null);
    } on LocalStorageException catch (error) {
      return Left(CacheFailure(error.message));
    } on NativeDataSourceException catch (error) {
      return Left(PlatformFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Unable to save schedule: $error'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSchedule(String id) async {
    try {
      await _scheduleLocalDataSource.deleteSchedule(id);
      await _syncAppScheduleRestrictions();
      await _syncEffectiveBlockedListToVpn();
      return const Right(null);
    } on LocalStorageException catch (error) {
      return Left(CacheFailure(error.message));
    } on NativeDataSourceException catch (error) {
      return Left(PlatformFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Unable to delete schedule: $error'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleSchedule({
    required String id,
    required bool isEnabled,
  }) async {
    try {
      final existingModels = await _scheduleLocalDataSource.getSchedules();
      final target = existingModels.firstWhere(
        (s) => s.id == id,
        orElse: () => throw const LocalStorageException('Schedule not found'),
      );

      if (isEnabled) {
        final existingEntities = existingModels.map((m) => m.toEntity()).toList();
        final updatedTarget = target.copyWith(isEnabled: true);
        final validation = _conflictValidator.validateSchedule(
          schedule: updatedTarget,
          existingSchedules: existingEntities,
        );
        if (!validation.isValid) {
          return Left(ValidationFailure(validation.errorMessage ?? 'Schedule validation failed'));
        }
      }

      await _scheduleLocalDataSource.toggleSchedule(id: id, isEnabled: isEnabled);
      await _syncAppScheduleRestrictions();
      await _syncEffectiveBlockedListToVpn();
      return const Right(null);
    } on LocalStorageException catch (error) {
      return Left(CacheFailure(error.message));
    } on NativeDataSourceException catch (error) {
      return Left(PlatformFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Unable to toggle schedule: $error'));
    }
  }

  @override
  Future<Either<Failure, Set<String>>> getEffectiveBlockedPackages({
    DateTime? currentTime,
  }) async {
    try {
      final now = currentTime ?? DateTime.now();
      final manualList = await _localStorageDataSource.getBlockedPackages();
      final scheduleModels = await _scheduleLocalDataSource.getSchedules();

      final effective = _ruleEngine.calculateEffectiveBlockedPackages(
        manualBlockedPackages: manualList.toSet(),
        schedules: scheduleModels.map((m) => m.toEntity()).toList(),
        currentTime: now,
      );

      return Right(effective);
    } on LocalStorageException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Unable to compute effective blocked packages: $error'));
    }
  }

  @override
  Future<Either<Failure, Map<String, String>>> getAssignedPackages({
    String? excludeScheduleId,
  }) async {
    try {
      final scheduleModels = await _scheduleLocalDataSource.getSchedules();
      final assigned = _conflictValidator.getAssignedPackagesMap(
        scheduleModels.map((m) => m.toEntity()).toList(),
        excludeScheduleId: excludeScheduleId,
      );
      return Right(assigned);
    } on LocalStorageException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Unable to get assigned packages: $error'));
    }
  }

  @override
  Future<Either<Failure, bool>> canScheduleExactAlarms() async {
    try {
      final canSchedule = await _nativeDataSource.canScheduleExactAlarms();
      return Right(canSchedule);
    } on NativeDataSourceException catch (error) {
      return Left(PlatformFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Unable to check exact alarm capability: $error'));
    }
  }

  @override
  Future<Either<Failure, bool>> requestExactAlarmPermission() async {
    try {
      final granted = await _nativeDataSource.requestExactAlarmPermission();
      return Right(granted);
    } on NativeDataSourceException catch (error) {
      return Left(PlatformFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Unable to request exact alarm permission: $error'));
    }
  }

  @override
  Future<Either<Failure, bool>> areNotificationsEnabled() async {
    try {
      final enabled = await _nativeDataSource.areNotificationsEnabled();
      return Right(enabled);
    } on NativeDataSourceException catch (error) {
      return Left(PlatformFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Unable to check notification permission: $error'));
    }
  }

  @override
  Future<Either<Failure, bool>> requestNotificationPermission() async {
    try {
      final granted = await _nativeDataSource.requestNotificationPermission();
      return Right(granted);
    } on NativeDataSourceException catch (error) {
      return Left(PlatformFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Unable to request notification permission: $error'));
    }
  }

  @override
  Future<Either<Failure, void>> syncSchedules() async {
    try {
      await _syncEffectiveBlockedListToVpn();
      return const Right(null);
    } on LocalStorageException catch (error) {
      return Left(CacheFailure(error.message));
    } on NativeDataSourceException catch (error) {
      return Left(PlatformFailure(error.message));
    } catch (error) {
      return Left(ServerFailure('Unable to sync schedules: $error'));
    }
  }

  Future<void> _syncEffectiveBlockedListToVpn() async {
    // Only sync schedule definitions to the native engine.
    // ScheduleAlarmManager.reconcileAndApply() on the native side will compute
    // effective = manualPackages ∪ activeSchedulePackages and correctly
    // start/stop/update the VPN service without corrupting manual firewall rules.
    try {
      final scheduleModels = await _scheduleLocalDataSource.getSchedules();
      final maps = scheduleModels.map((m) => m.toMap()).toList();
      await _nativeDataSource.syncSchedules(jsonEncode(maps));
    } catch (_) {
      // Non-fatal: native background engine sync failure should not break local UI.
    }
  }

  Future<void> _syncAppScheduleRestrictions() async {
    if (_appLocalDataSource == null) return;
    try {
      final scheduleModels = await _scheduleLocalDataSource.getSchedules();
      final schedules = scheduleModels.map((m) => m.toEntity()).toList();
      final assigned = _conflictValidator.getAssignedPackagesMap(schedules);

      final cachedApps = await _appLocalDataSource.getCachedApps();
      if (cachedApps.isEmpty) return;

      final updatedApps = cachedApps.map((app) {
        final assignedSchedule = assigned[app.packageName];
        final isPart = assignedSchedule != null;
        if (app.isSchedulePart != isPart || app.whichSchedule != assignedSchedule) {
          return app.copyWith(
            isSchedulePart: isPart,
            whichSchedule: assignedSchedule,
            clearWhichSchedule: !isPart,
          );
        }
        return app;
      }).toList();

      await _appLocalDataSource.cacheApps(updatedApps);
    } catch (_) {}
  }
}
// Public dependency names are intentionally retained for ergonomic composition.
// ignore_for_file: prefer_initializing_formals
