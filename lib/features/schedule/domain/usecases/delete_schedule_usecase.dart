import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/schedule_repository.dart';

class DeleteScheduleParams {
  const DeleteScheduleParams(this.id);
  final String id;
}

class DeleteScheduleUseCase implements UseCase<void, DeleteScheduleParams> {
  const DeleteScheduleUseCase(this._repository);

  final ScheduleRepository _repository;

  @override
  Future<Either<Failure, void>> call(DeleteScheduleParams params) {
    return _repository.deleteSchedule(params.id);
  }
}
