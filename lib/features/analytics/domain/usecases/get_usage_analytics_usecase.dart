import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/analytics_summary_entity.dart';
import '../entities/analytics_time_range.dart';
import '../repositories/analytics_repository.dart';

class GetUsageAnalyticsParams {
  const GetUsageAnalyticsParams(this.timeRange);
  final AnalyticsTimeRange timeRange;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetUsageAnalyticsParams &&
          runtimeType == other.runtimeType &&
          timeRange == other.timeRange;

  @override
  int get hashCode => timeRange.hashCode;
}

class GetUsageAnalyticsUseCase
    implements UseCase<AnalyticsSummaryEntity, GetUsageAnalyticsParams> {
  const GetUsageAnalyticsUseCase(this._repository);

  final AnalyticsRepository _repository;

  @override
  Future<Either<Failure, AnalyticsSummaryEntity>> call(
    GetUsageAnalyticsParams params,
  ) {
    return _repository.getUsageAnalytics(params.timeRange);
  }
}
