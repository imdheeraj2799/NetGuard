import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/schedule_repository.dart';

class RequestNotificationPermissionUseCase implements UseCase<bool, NoParams> {
  const RequestNotificationPermissionUseCase(this.repository);

  final ScheduleRepository repository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) =>
      repository.requestNotificationPermission();
}
