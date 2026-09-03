import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/blocked_domain_entity.dart';
import '../repositories/domain_filter_repository.dart';

class GetBlockedDomainsUseCase
    implements UseCase<List<BlockedDomainEntity>, NoParams> {
  const GetBlockedDomainsUseCase(this._repository);

  final DomainFilterRepository _repository;

  @override
  Future<Either<Failure, List<BlockedDomainEntity>>> call(NoParams params) =>
      _repository.getBlockedDomains();
}
