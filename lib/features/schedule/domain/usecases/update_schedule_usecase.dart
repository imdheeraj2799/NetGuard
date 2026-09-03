import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/schedule_entity.dart';
import '../repositories/schedule_repository.dart';

class UpdateScheduleParams {
  const UpdateScheduleParams(this.schedule);
  final ScheduleEntity schedule;
}

class UpdateScheduleUseCase implements UseCase<ScheduleEntity, UpdateScheduleParams> {
  const UpdateScheduleUseCase(this._repository);

  final ScheduleRepository _repository;

  @override
  Future<Either<Failure, ScheduleEntity>> call(UpdateScheduleParams params) {
    return _repository.updateSchedule(params.schedule);
  }
}
