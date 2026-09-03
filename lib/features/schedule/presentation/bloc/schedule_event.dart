import '../../domain/entities/schedule_entity.dart';

abstract class ScheduleEvent {
  const ScheduleEvent();
}

class LoadSchedulesEvent extends ScheduleEvent {
  const LoadSchedulesEvent();
}

class CreateScheduleEvent extends ScheduleEvent {
  const CreateScheduleEvent(this.schedule);
  final ScheduleEntity schedule;
}

class UpdateScheduleEvent extends ScheduleEvent {
  const UpdateScheduleEvent(this.schedule);
  final ScheduleEntity schedule;
}

class ToggleScheduleEvent extends ScheduleEvent {
  const ToggleScheduleEvent({
    required this.id,
    required this.isEnabled,
  });

  final String id;
  final bool isEnabled;
}

class DeleteScheduleEvent extends ScheduleEvent {
  const DeleteScheduleEvent(this.id);
  final String id;
}

class EvaluateSchedulesEvent extends ScheduleEvent {
  const EvaluateSchedulesEvent([this.evaluationTime]);
  final DateTime? evaluationTime;
}
