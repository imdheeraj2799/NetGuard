import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/analytics_summary_entity.dart';
import '../entities/analytics_time_range.dart';

abstract class AnalyticsRepository {
  Future<Either<Failure, AnalyticsSummaryEntity>> getUsageAnalytics(
    AnalyticsTimeRange timeRange,
  );
  Future<Either<Failure, bool>> checkUsagePermission();
  Future<Either<Failure, void>> requestUsagePermission();
}
