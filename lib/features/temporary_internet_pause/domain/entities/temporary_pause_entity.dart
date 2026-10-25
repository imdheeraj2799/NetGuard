class TemporaryPauseEntity {
  const TemporaryPauseEntity({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.startTime,
    required this.pauseUntil,
    required this.duration,
    this.isCustom = false,
  });

  final String id;
  final String packageName;
  final String appName;
  final DateTime startTime;
  final DateTime pauseUntil;
  final Duration duration;
  final bool isCustom;

  bool isExpired([DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();
    return now.isAfter(pauseUntil) || now.isAtSameMomentAs(pauseUntil);
  }

  Duration remainingTime([DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();
    final diff = pauseUntil.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  double progressFraction([DateTime? currentTime]) {
    final totalMillis = duration.inMilliseconds;
    if (totalMillis <= 0) return 1.0;
    final remainingMillis = remainingTime(currentTime).inMilliseconds;
    final elapsed = totalMillis - remainingMillis;
    final frac = elapsed / totalMillis;
    return frac.clamp(0.0, 1.0);
  }

  TemporaryPauseEntity copyWith({
    String? id,
    String? packageName,
    String? appName,
    DateTime? startTime,
    DateTime? pauseUntil,
    Duration? duration,
    bool? isCustom,
  }) {
    return TemporaryPauseEntity(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      startTime: startTime ?? this.startTime,
      pauseUntil: pauseUntil ?? this.pauseUntil,
      duration: duration ?? this.duration,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemporaryPauseEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          packageName == other.packageName &&
          appName == other.appName &&
          startTime == other.startTime &&
          pauseUntil == other.pauseUntil &&
          duration == other.duration &&
          isCustom == other.isCustom;

  @override
  int get hashCode => Object.hash(
        id,
        packageName,
        appName,
        startTime,
        pauseUntil,
        duration,
        isCustom,
      );
}
