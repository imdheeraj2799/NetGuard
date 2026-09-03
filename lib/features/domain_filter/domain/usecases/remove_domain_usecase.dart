import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/domain_filter_repository.dart';

class RemoveDomainParams {
  const RemoveDomainParams(this.id);

  final String id;
}

class RemoveDomainUseCase implements UseCase<void, RemoveDomainParams> {
  const RemoveDomainUseCase(this._repository);

  final DomainFilterRepository _repository;

  @override
  Future<Either<Failure, void>> call(RemoveDomainParams params) =>
      _repository.removeDomain(params.id);
}
