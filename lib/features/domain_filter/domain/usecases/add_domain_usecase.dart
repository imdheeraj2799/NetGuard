import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/blocked_domain_entity.dart';
import '../repositories/domain_filter_repository.dart';

class AddDomainParams {
  const AddDomainParams(this.domain);

  final String domain;
}

class AddDomainUseCase
    implements UseCase<BlockedDomainEntity, AddDomainParams> {
  const AddDomainUseCase(this._repository);

  final DomainFilterRepository _repository;

  @override
  Future<Either<Failure, BlockedDomainEntity>> call(AddDomainParams params) =>
      _repository.addDomain(params.domain);
}
