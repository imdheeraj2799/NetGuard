import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/block_schedule_entity.dart';

abstract class ScheduleRepository {
  Future<Either<Failure, List<BlockScheduleEntity>>> getSchedules();
  Future<Either<Failure, void>> saveSchedule(BlockScheduleEntity schedule);
  Future<Either<Failure, void>> deleteSchedule(String id);
  Future<Either<Failure, void>> toggleSchedule({
    required String id,
    required bool isEnabled,
  });
  Future<Either<Failure, Set<String>>> getEffectiveBlockedPackages({
    DateTime? currentTime,
  });
  Future<Either<Failure, Map<String, String>>> getAssignedPackages({
    String? excludeScheduleId,
  });
  Future<Either<Failure, bool>> canScheduleExactAlarms();
  Future<Either<Failure, bool>> requestExactAlarmPermission();
  Future<Either<Failure, void>> syncSchedules();
}
