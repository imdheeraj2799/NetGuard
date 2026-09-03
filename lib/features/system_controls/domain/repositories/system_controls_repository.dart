import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/dns_resolver_entity.dart';

abstract class SystemControlsRepository {
  Future<Either<Failure, DnsResolverEntity>> getActiveDnsResolver();
  Future<Either<Failure, List<DnsResolverEntity>>> getAvailableDnsResolvers();
  Future<Either<Failure, void>> setDnsResolver(DnsResolverEntity resolver);
  Future<Either<Failure, DnsResolverEntity>> setCustomDnsIp(String ip);
}
