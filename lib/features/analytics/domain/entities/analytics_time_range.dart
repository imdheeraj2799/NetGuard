enum AnalyticsTimeRange {
  day,
  week,
  month;

  String get displayName {
    switch (this) {
      case AnalyticsTimeRange.day:
        return 'Today';
      case AnalyticsTimeRange.week:
        return 'Last 7 Days';
      case AnalyticsTimeRange.month:
        return 'Last 30 Days';
    }
  }
}
