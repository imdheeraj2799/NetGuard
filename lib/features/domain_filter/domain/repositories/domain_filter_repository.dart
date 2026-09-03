import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/blocked_domain_entity.dart';

abstract class DomainFilterRepository {
  Future<Either<Failure, List<BlockedDomainEntity>>> getBlockedDomains();

  Future<Either<Failure, BlockedDomainEntity>> addDomain(String domain);

  Future<Either<Failure, void>> removeDomain(String id);

  Future<Either<Failure, BlockedDomainEntity>> toggleDomain(
    String id,
    bool isBlocked,
  );
}
