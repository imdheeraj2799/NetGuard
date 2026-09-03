import '../../domain/entities/analytics_time_range.dart';

abstract class AnalyticsEvent {
  const AnalyticsEvent();
}

class CheckAnalyticsPermissionEvent extends AnalyticsEvent {
  const CheckAnalyticsPermissionEvent();
}

class RequestAnalyticsPermissionEvent extends AnalyticsEvent {
  const RequestAnalyticsPermissionEvent();
}

class LoadAnalyticsEvent extends AnalyticsEvent {
  const LoadAnalyticsEvent({this.timeRange = AnalyticsTimeRange.week});

  final AnalyticsTimeRange timeRange;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadAnalyticsEvent &&
          runtimeType == other.runtimeType &&
          timeRange == other.timeRange;

  @override
  int get hashCode => timeRange.hashCode;
}
