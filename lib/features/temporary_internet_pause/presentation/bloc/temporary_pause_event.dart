sealed class TemporaryPauseEvent {
  const TemporaryPauseEvent();
}

class LoadTemporaryPausesEvent extends TemporaryPauseEvent {
  const LoadTemporaryPausesEvent();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LoadTemporaryPausesEvent;

  @override
  int get hashCode => runtimeType.hashCode;
}

class CreateTemporaryPauseEvent extends TemporaryPauseEvent {
  const CreateTemporaryPauseEvent({
    required this.packageName,
    required this.appName,
    required this.duration,
    this.isCustom = false,
  });

  final String packageName;
  final String appName;
  final Duration duration;
  final bool isCustom;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateTemporaryPauseEvent &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName &&
          appName == other.appName &&
          duration == other.duration &&
          isCustom == other.isCustom;

  @override
  int get hashCode => Object.hash(packageName, appName, duration, isCustom);
}

class CancelTemporaryPauseEvent extends TemporaryPauseEvent {
  const CancelTemporaryPauseEvent(this.id);

  final String id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CancelTemporaryPauseEvent &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ReconcileExpiredPausesEvent extends TemporaryPauseEvent {
  const ReconcileExpiredPausesEvent({this.currentTime});

  final DateTime? currentTime;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReconcileExpiredPausesEvent &&
          runtimeType == other.runtimeType &&
          currentTime == other.currentTime;

  @override
  int get hashCode => currentTime.hashCode;
}

class TimerTickEvent extends TemporaryPauseEvent {
  const TimerTickEvent(this.currentTime);

  final DateTime currentTime;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerTickEvent &&
          runtimeType == other.runtimeType &&
          currentTime == other.currentTime;

  @override
  int get hashCode => currentTime.hashCode;
}

class ClearTemporaryPauseActionMessageEvent extends TemporaryPauseEvent {
  const ClearTemporaryPauseActionMessageEvent();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ClearTemporaryPauseActionMessageEvent;

  @override
  int get hashCode => runtimeType.hashCode;
}
