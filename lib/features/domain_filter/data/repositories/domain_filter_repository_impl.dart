// ignore_for_file: prefer_initializing_formals

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/blocked_domain_entity.dart';
import '../../domain/repositories/domain_filter_repository.dart';
import '../datasources/domain_local_data_source.dart';
import '../datasources/domain_native_data_source.dart';

class DomainFilterRepositoryImpl implements DomainFilterRepository {
  const DomainFilterRepositoryImpl({
    required DomainLocalDataSource localDataSource,
    required DomainNativeDataSource nativeDataSource,
  })  : _localDataSource = localDataSource,
        _nativeDataSource = nativeDataSource;

  final DomainLocalDataSource _localDataSource;
  final DomainNativeDataSource _nativeDataSource;

  @override
  Future<Either<Failure, List<BlockedDomainEntity>>> getBlockedDomains() async {
    try {
      final models = await _localDataSource.getDomains();
      return Right(models.map((m) => m.toEntity()).toList());
    } on DomainLocalDataSourceException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error loading domains: $e'));
    }
  }

  @override
  Future<Either<Failure, BlockedDomainEntity>> addDomain(String domain) async {
    try {
      final addedModel = await _localDataSource.addDomain(domain);
      await _syncNativeBlacklist();
      return Right(addedModel.toEntity());
    } on DomainLocalDataSourceException catch (e) {
      return Left(CacheFailure(e.message));
    } on DomainNativeDataSourceException catch (e) {
      return Left(PlatformFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to add domain: $e'));
    }
  }

  @override
  Future<Either<Failure, BlockedDomainEntity>> toggleDomain(
    String id,
    bool isBlocked,
  ) async {
    try {
      final updatedModel = await _localDataSource.toggleDomain(id, isBlocked);
      await _syncNativeBlacklist();
      return Right(updatedModel.toEntity());
    } on DomainLocalDataSourceException catch (e) {
      return Left(CacheFailure(e.message));
    } on DomainNativeDataSourceException catch (e) {
      return Left(PlatformFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to toggle domain: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> removeDomain(String id) async {
    try {
      await _localDataSource.removeDomain(id);
      await _syncNativeBlacklist();
      return const Right(null);
    } on DomainLocalDataSourceException catch (e) {
      return Left(CacheFailure(e.message));
    } on DomainNativeDataSourceException catch (e) {
      return Left(PlatformFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to remove domain: $e'));
    }
  }

  Future<void> _syncNativeBlacklist() async {
    final allDomains = await _localDataSource.getDomains();
    final activeDomains = allDomains
        .where((d) => d.isBlocked)
        .map((d) => d.domain)
        .toList();
    await _nativeDataSource.updateDnsBlacklist(activeDomains);
  }
}
