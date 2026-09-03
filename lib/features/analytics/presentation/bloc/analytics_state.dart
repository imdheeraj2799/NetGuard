import '../../domain/entities/analytics_summary_entity.dart';
import '../../domain/entities/analytics_time_range.dart';

abstract class AnalyticsState {
  const AnalyticsState();
}

class AnalyticsInitial extends AnalyticsState {
  const AnalyticsInitial();
}

class AnalyticsLoading extends AnalyticsState {
  const AnalyticsLoading();
}

class AnalyticsPermissionRequired extends AnalyticsState {
  const AnalyticsPermissionRequired();
}

class AnalyticsLoaded extends AnalyticsState {
  const AnalyticsLoaded({
    required this.summary,
    required this.selectedRange,
  });

  final AnalyticsSummaryEntity summary;
  final AnalyticsTimeRange selectedRange;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsLoaded &&
          runtimeType == other.runtimeType &&
          summary == other.summary &&
          selectedRange == other.selectedRange;

  @override
  int get hashCode => summary.hashCode ^ selectedRange.hashCode;
}

class AnalyticsError extends AnalyticsState {
  const AnalyticsError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
