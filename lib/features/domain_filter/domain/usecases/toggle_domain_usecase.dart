import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/blocked_domain_entity.dart';
import '../repositories/domain_filter_repository.dart';

class ToggleDomainParams {
  const ToggleDomainParams({
    required this.id,
    required this.isBlocked,
  });

  final String id;
  final bool isBlocked;
}

class ToggleDomainUseCase
    implements UseCase<BlockedDomainEntity, ToggleDomainParams> {
  const ToggleDomainUseCase(this._repository);

  final DomainFilterRepository _repository;

  @override
  Future<Either<Failure, BlockedDomainEntity>> call(
    ToggleDomainParams params,
  ) =>
      _repository.toggleDomain(params.id, params.isBlocked);
}
