import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/schedule_repository.dart';

class GetAssignedPackagesParams {
  const GetAssignedPackagesParams({this.excludeScheduleId});
  final String? excludeScheduleId;
}

class GetAssignedPackagesUseCase
    implements UseCase<Map<String, String>, GetAssignedPackagesParams> {
  const GetAssignedPackagesUseCase(this.repository);

  final ScheduleRepository repository;

  @override
  Future<Either<Failure, Map<String, String>>> call(
    GetAssignedPackagesParams params,
  ) {
    return repository.getAssignedPackages(
      excludeScheduleId: params.excludeScheduleId,
    );
  }
}
