/// Represents a time-based traffic restriction schedule.
class ScheduleEntity {
  const ScheduleEntity({
    required this.id,
    required this.name,
    required this.startTimeMinutes,
    required this.endTimeMinutes,
    required this.activeDays,
    required this.targetPackages,
    this.isEnabled = true,
  });

  final String id;
  final String name;

  /// Start time in minutes from midnight (0 .. 1439). E.g. 22:00 = 1320.
  final int startTimeMinutes;

  /// End time in minutes from midnight (0 .. 1439). E.g. 07:00 = 420.
  final int endTimeMinutes;

  /// Active days of week, matching [DateTime.monday] (1) .. [DateTime.sunday] (7).
  final List<int> activeDays;

  /// Target application package names blocked by this schedule.
  final List<String> targetPackages;

  /// Whether this schedule is enabled.
  final bool isEnabled;

  /// Evaluates whether this schedule is currently active at [now].
  ///
  /// Handles both:
  /// 1. Same-day schedules (e.g. 09:00 to 17:00).
  /// 2. Overnight / Midnight crossover schedules (e.g. 22:00 to 07:00 next day).
  bool isCurrentlyActive(DateTime now) {
    if (!isEnabled || activeDays.isEmpty) return false;

    final currentMinutes = now.hour * 60 + now.minute;
    final currentDay = now.weekday; // 1 = Monday .. 7 = Sunday

    if (startTimeMinutes <= endTimeMinutes) {
      // Same-day schedule
      final isDayActive = activeDays.contains(currentDay);
      final isTimeActive = currentMinutes >= startTimeMinutes &&
          currentMinutes < endTimeMinutes;
      return isDayActive && isTimeActive;
    } else {
      // Overnight schedule (Midnight Crossover)
      // E.g., 22:00 to 07:00 next morning.

      // Case A: Late evening of an active day (>= startTimeMinutes)
      final isActiveEvening =
          activeDays.contains(currentDay) && currentMinutes >= startTimeMinutes;

      // Case B: Early morning (< endTimeMinutes) belonging to yesterday's active schedule
      final previousDay = currentDay == 1 ? 7 : currentDay - 1;
      final isActiveMorning =
          activeDays.contains(previousDay) && currentMinutes < endTimeMinutes;

      return isActiveEvening || isActiveMorning;
    }
  }

  /// Formats the schedule as a human-readable time range (e.g. "10:00 PM - 07:00 AM").
  String formattedTimeRange() {
    return '${_formatMinutes(startTimeMinutes)} - ${_formatMinutes(endTimeMinutes)}';
  }

  /// Short human-readable summary of active days (e.g., "Mon-Fri", "Everyday", "Weekends").
  String formattedActiveDays() {
    if (activeDays.length == 7) return 'Everyday';
    if (activeDays.length == 5 &&
        activeDays.contains(1) &&
        activeDays.contains(2) &&
        activeDays.contains(3) &&
        activeDays.contains(4) &&
        activeDays.contains(5)) {
      return 'Mon - Fri';
    }
    if (activeDays.length == 2 &&
        activeDays.contains(6) &&
        activeDays.contains(7)) {
      return 'Weekends';
    }

    const dayLabels = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = [...activeDays]..sort();
    return sorted.map((d) => dayLabels[d]).join(', ');
  }

  static String _formatMinutes(int minutes) {
    final hour24 = minutes ~/ 60;
    final min = minutes % 60;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final minStr = min.toString().padLeft(2, '0');
    final hourStr = hour12.toString().padLeft(2, '0');
    return '$hourStr:$minStr $period';
  }

  ScheduleEntity copyWith({
    String? id,
    String? name,
    int? startTimeMinutes,
    int? endTimeMinutes,
    List<int>? activeDays,
    List<String>? targetPackages,
    bool? isEnabled,
  }) {
    return ScheduleEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      startTimeMinutes: startTimeMinutes ?? this.startTimeMinutes,
      endTimeMinutes: endTimeMinutes ?? this.endTimeMinutes,
      activeDays: activeDays ?? this.activeDays,
      targetPackages: targetPackages ?? this.targetPackages,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          startTimeMinutes == other.startTimeMinutes &&
          endTimeMinutes == other.endTimeMinutes &&
          isEnabled == other.isEnabled;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      startTimeMinutes.hashCode ^
      endTimeMinutes.hashCode ^
      isEnabled.hashCode;
}
