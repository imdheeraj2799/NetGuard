import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/schedule_repository.dart';

class RequestExactAlarmPermissionUseCase implements UseCase<bool, NoParams> {
  const RequestExactAlarmPermissionUseCase(this._repository);

  final ScheduleRepository _repository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return _repository.requestExactAlarmPermission();
  }
}
