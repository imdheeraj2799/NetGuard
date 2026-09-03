import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/analytics_summary_entity.dart';
import '../../domain/entities/analytics_time_range.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/analytics_native_data_source.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  const AnalyticsRepositoryImpl(this._nativeDataSource);

  final AnalyticsNativeDataSource _nativeDataSource;

  @override
  Future<Either<Failure, bool>> checkUsagePermission() async {
    try {
      final hasPermission = await _nativeDataSource.checkUsagePermission();
      return Right(hasPermission);
    } on AnalyticsNativeDataSourceException catch (e) {
      return Left(PlatformFailure(e.message));
    } catch (e) {
      return Left(PlatformFailure('Failed to check usage permission: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> requestUsagePermission() async {
    try {
      await _nativeDataSource.requestUsagePermission();
      return const Right(null);
    } on AnalyticsNativeDataSourceException catch (e) {
      return Left(PlatformFailure(e.message));
    } catch (e) {
      return Left(PlatformFailure('Failed to request usage permission: $e'));
    }
  }

  @override
  Future<Either<Failure, AnalyticsSummaryEntity>> getUsageAnalytics(
    AnalyticsTimeRange timeRange,
  ) async {
    try {
      final model = await _nativeDataSource.getAppUsageAnalytics(timeRange.name);
      return Right(model);
    } on AnalyticsNativeDataSourceException catch (e) {
      return Left(PlatformFailure(e.message));
    } catch (e) {
      return Left(PlatformFailure('Failed to get app usage analytics: $e'));
    }
  }
}
