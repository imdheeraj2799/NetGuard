import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/schedule_repository.dart';

class AreNotificationsEnabledUseCase implements UseCase<bool, NoParams> {
  const AreNotificationsEnabledUseCase(this._repository);

  final ScheduleRepository _repository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return _repository.areNotificationsEnabled();
  }
}
