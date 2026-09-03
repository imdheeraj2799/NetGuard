import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/dns_resolver_entity.dart';
import '../repositories/system_controls_repository.dart';

class SetDnsResolverParams {
  const SetDnsResolverParams({required this.resolver});

  final DnsResolverEntity resolver;
}

class SetDnsResolverUseCase implements UseCase<void, SetDnsResolverParams> {
  const SetDnsResolverUseCase(this._repository);

  final SystemControlsRepository _repository;

  @override
  Future<Either<Failure, void>> call(SetDnsResolverParams params) {
    if (params.resolver.isCustom) {
      final ip = params.resolver.primaryIp.trim();
      final ipv4Regex = RegExp(
        r'^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$',
      );
      if (!ipv4Regex.hasMatch(ip)) {
        return Future.value(
          const Left(ValidationFailure('Invalid IPv4 DNS address.')),
        );
      }
    }
    return _repository.setDnsResolver(params.resolver);
  }
}
