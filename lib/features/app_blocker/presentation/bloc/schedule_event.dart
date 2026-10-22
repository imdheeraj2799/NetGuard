import '../../domain/entities/block_schedule_entity.dart';

sealed class ScheduleEvent {
  const ScheduleEvent();
}

class LoadSchedulesEvent extends ScheduleEvent {
  const LoadSchedulesEvent();
}

class SaveScheduleEvent extends ScheduleEvent {
  const SaveScheduleEvent(this.schedule);
  final BlockScheduleEntity schedule;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaveScheduleEvent && schedule == other.schedule;

  @override
  int get hashCode => schedule.hashCode;
}

class DeleteScheduleEvent extends ScheduleEvent {
  const DeleteScheduleEvent(this.id);
  final String id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeleteScheduleEvent && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ToggleScheduleEvent extends ScheduleEvent {
  const ToggleScheduleEvent({
    required this.id,
    required this.isEnabled,
  });

  final String id;
  final bool isEnabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToggleScheduleEvent &&
          id == other.id &&
          isEnabled == other.isEnabled;

  @override
  int get hashCode => Object.hash(id, isEnabled);
}

class RequestExactAlarmPermissionEvent extends ScheduleEvent {
  const RequestExactAlarmPermissionEvent();
}
