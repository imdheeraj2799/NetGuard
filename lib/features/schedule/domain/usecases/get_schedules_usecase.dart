import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/schedule_entity.dart';
import '../repositories/schedule_repository.dart';

class GetSchedulesUseCase implements UseCase<List<ScheduleEntity>, NoParams> {
  const GetSchedulesUseCase(this._repository);

  final ScheduleRepository _repository;

  @override
  Future<Either<Failure, List<ScheduleEntity>>> call(NoParams params) {
    return _repository.getSchedules();
  }
}
