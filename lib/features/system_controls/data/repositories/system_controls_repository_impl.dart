// ignore_for_file: prefer_initializing_formals

import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/dns_resolver_entity.dart';
import '../../domain/repositories/system_controls_repository.dart';
import '../datasources/system_controls_local_data_source.dart';
import '../datasources/system_controls_native_data_source.dart';

class SystemControlsRepositoryImpl implements SystemControlsRepository {
  const SystemControlsRepositoryImpl({
    required SystemControlsLocalDataSource localDataSource,
    required SystemControlsNativeDataSource nativeDataSource,
  })  : _localDataSource = localDataSource,
        _nativeDataSource = nativeDataSource;

  final SystemControlsLocalDataSource _localDataSource;
  final SystemControlsNativeDataSource _nativeDataSource;

  @override
  Future<Either<Failure, DnsResolverEntity>> getActiveDnsResolver() async {
    try {
      final selectedId = await _localDataSource.getSelectedDnsId();
      final customIp = await _localDataSource.getCustomDnsIp();

      if (selectedId == 'custom' && customIp != null && customIp.isNotEmpty) {
        return Right(
          DnsResolverEntity(
            id: 'custom',
            name: 'Custom DNS',
            primaryIp: customIp,
            secondaryIp: '',
            isCustom: true,
          ),
        );
      }

      final matched = DnsResolverEntity.predefined.firstWhere(
        (r) => r.id == selectedId,
        orElse: () => DnsResolverEntity.cloudflare,
      );
      return Right(matched);
    } catch (e) {
      return Left(StorageFailure('Failed to get active DNS resolver: $e'));
    }
  }

  @override
  Future<Either<Failure, List<DnsResolverEntity>>> getAvailableDnsResolvers() async {
    try {
      final customIp = await _localDataSource.getCustomDnsIp();
      final list = List<DnsResolverEntity>.from(DnsResolverEntity.predefined);
      if (customIp != null && customIp.isNotEmpty) {
        list.add(
          DnsResolverEntity(
            id: 'custom',
            name: 'Custom DNS',
            primaryIp: customIp,
            secondaryIp: '',
            isCustom: true,
          ),
        );
      }
      return Right(list);
    } catch (e) {
      return Left(StorageFailure('Failed to load available DNS resolvers: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> setDnsResolver(DnsResolverEntity resolver) async {
    try {
      await _localDataSource.setSelectedDnsId(resolver.id);
      if (resolver.isCustom) {
        await _localDataSource.setCustomDnsIp(resolver.primaryIp);
      }
      await _nativeDataSource.setCustomDnsResolver(resolver.primaryIp);
      return const Right(null);
    } catch (e) {
      return Left(PlatformFailure('Failed to set DNS resolver: $e'));
    }
  }

  @override
  Future<Either<Failure, DnsResolverEntity>> setCustomDnsIp(String ip) async {
    try {
      final trimmed = ip.trim();
      await _localDataSource.setCustomDnsIp(trimmed);
      await _localDataSource.setSelectedDnsId('custom');
      final entity = DnsResolverEntity(
        id: 'custom',
        name: 'Custom DNS',
        primaryIp: trimmed,
        secondaryIp: '',
        isCustom: true,
      );
      await _nativeDataSource.setCustomDnsResolver(trimmed);
      return Right(entity);
    } catch (e) {
      return Left(PlatformFailure('Failed to configure custom DNS IP: $e'));
    }
  }
}
