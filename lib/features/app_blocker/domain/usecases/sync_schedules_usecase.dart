import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/schedule_repository.dart';

class SyncSchedulesUseCase implements UseCase<void, NoParams> {
  const SyncSchedulesUseCase(this._repository);

  final ScheduleRepository _repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return _repository.syncSchedules();
  }
}
