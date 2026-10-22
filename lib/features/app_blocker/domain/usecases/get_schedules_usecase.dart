import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/block_schedule_entity.dart';
import '../repositories/schedule_repository.dart';

class GetSchedulesUseCase implements UseCase<List<BlockScheduleEntity>, NoParams> {
  const GetSchedulesUseCase(this.repository);

  final ScheduleRepository repository;

  @override
  Future<Either<Failure, List<BlockScheduleEntity>>> call(NoParams params) {
    return repository.getSchedules();
  }
}
