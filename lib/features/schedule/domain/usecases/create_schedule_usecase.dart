import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/schedule_entity.dart';
import '../repositories/schedule_repository.dart';

class CreateScheduleParams {
  const CreateScheduleParams(this.schedule);
  final ScheduleEntity schedule;
}

class CreateScheduleUseCase implements UseCase<ScheduleEntity, CreateScheduleParams> {
  const CreateScheduleUseCase(this._repository);

  final ScheduleRepository _repository;

  @override
  Future<Either<Failure, ScheduleEntity>> call(CreateScheduleParams params) {
    return _repository.createSchedule(params.schedule);
  }
}
