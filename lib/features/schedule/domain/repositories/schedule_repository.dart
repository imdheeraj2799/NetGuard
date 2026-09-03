import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/schedule_entity.dart';

abstract class ScheduleRepository {
  Future<Either<Failure, List<ScheduleEntity>>> getSchedules();

  Future<Either<Failure, ScheduleEntity>> createSchedule(ScheduleEntity schedule);

  Future<Either<Failure, ScheduleEntity>> updateSchedule(ScheduleEntity schedule);

  Future<Either<Failure, void>> deleteSchedule(String id);

  Future<Either<Failure, ScheduleEntity>> toggleScheduleActive(
    String id,
    bool isEnabled,
  );
}
