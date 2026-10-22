import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/block_schedule_entity.dart';
import '../repositories/schedule_repository.dart';

class SaveScheduleParams {
  const SaveScheduleParams(this.schedule);
  final BlockScheduleEntity schedule;
}

class SaveScheduleUseCase implements UseCase<void, SaveScheduleParams> {
  const SaveScheduleUseCase(this.repository);

  final ScheduleRepository repository;

  @override
  Future<Either<Failure, void>> call(SaveScheduleParams params) {
    return repository.saveSchedule(params.schedule);
  }
}
