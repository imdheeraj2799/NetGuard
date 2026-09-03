import '../../domain/entities/schedule_entity.dart';

abstract class ScheduleState {
  const ScheduleState();
}

class ScheduleInitial extends ScheduleState {
  const ScheduleInitial();
}

class ScheduleLoading extends ScheduleState {
  const ScheduleLoading();
}

class ScheduleLoaded extends ScheduleState {
  const ScheduleLoaded({
    required this.allSchedules,
    required this.activeSchedules,
    required this.activeBlockedPackages,
  });

  final List<ScheduleEntity> allSchedules;
  final List<ScheduleEntity> activeSchedules;
  final Set<String> activeBlockedPackages;

  bool isPackageBlocked(String packageName) =>
      activeBlockedPackages.contains(packageName);

  ScheduleEntity? getScheduleForPackage(String packageName) {
    for (final schedule in allSchedules) {
      if (schedule.targetPackages.contains(packageName)) {
        return schedule;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ScheduleLoaded || runtimeType != other.runtimeType) {
      return false;
    }
    if (allSchedules.length != other.allSchedules.length ||
        activeSchedules.length != other.activeSchedules.length ||
        activeBlockedPackages.length != other.activeBlockedPackages.length) {
      return false;
    }
    for (var i = 0; i < allSchedules.length; i++) {
      if (allSchedules[i] != other.allSchedules[i]) return false;
    }
    for (var i = 0; i < activeSchedules.length; i++) {
      if (activeSchedules[i] != other.activeSchedules[i]) return false;
    }
    return activeBlockedPackages.containsAll(other.activeBlockedPackages);
  }

  @override
  int get hashCode =>
      Object.hashAll(allSchedules) ^
      Object.hashAll(activeSchedules) ^
      Object.hashAll(activeBlockedPackages);
}

class ScheduleError extends ScheduleState {
  const ScheduleError(this.message);
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
