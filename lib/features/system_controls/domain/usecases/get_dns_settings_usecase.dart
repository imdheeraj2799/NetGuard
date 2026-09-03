import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/dns_resolver_entity.dart';
import '../repositories/system_controls_repository.dart';

class DnsSettingsResult {
  const DnsSettingsResult({
    required this.currentResolver,
    required this.availableResolvers,
  });

  final DnsResolverEntity currentResolver;
  final List<DnsResolverEntity> availableResolvers;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DnsSettingsResult &&
          runtimeType == other.runtimeType &&
          currentResolver == other.currentResolver;

  @override
  int get hashCode => currentResolver.hashCode;
}

class GetDnsSettingsUseCase implements UseCase<DnsSettingsResult, NoParams> {
  const GetDnsSettingsUseCase(this._repository);

  final SystemControlsRepository _repository;

  @override
  Future<Either<Failure, DnsSettingsResult>> call(NoParams params) async {
    final currentEither = await _repository.getActiveDnsResolver();
    return currentEither.fold(
      (failure) => Left(failure),
      (current) async {
        final availableEither = await _repository.getAvailableDnsResolvers();
        return availableEither.fold(
          (failure) => Left(failure),
          (available) => Right(
            DnsSettingsResult(
              currentResolver: current,
              availableResolvers: available,
            ),
          ),
        );
      },
    );
  }
}
