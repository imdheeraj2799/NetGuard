import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/schedule_repository.dart';

class GetEffectiveBlockedPackagesParams {
  const GetEffectiveBlockedPackagesParams({this.currentTime});
  final DateTime? currentTime;
}

class GetEffectiveBlockedPackagesUseCase
    implements UseCase<Set<String>, GetEffectiveBlockedPackagesParams> {
  const GetEffectiveBlockedPackagesUseCase(this.repository);

  final ScheduleRepository repository;

  @override
  Future<Either<Failure, Set<String>>> call(
    GetEffectiveBlockedPackagesParams params,
  ) {
    return repository.getEffectiveBlockedPackages(
      currentTime: params.currentTime,
    );
  }
}
