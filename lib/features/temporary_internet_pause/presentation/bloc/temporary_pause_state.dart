import 'package:flutter/foundation.dart';

import '../../domain/entities/temporary_pause_entity.dart';

sealed class TemporaryPauseState {
  const TemporaryPauseState();
}

class TemporaryPauseInitial extends TemporaryPauseState {
  const TemporaryPauseInitial();
}

class TemporaryPauseLoading extends TemporaryPauseState {
  const TemporaryPauseLoading();
}

class TemporaryPauseLoaded extends TemporaryPauseState {
  const TemporaryPauseLoaded({
    required this.pauses,
    this.lastTick,
    this.actionMessage,
  });

  final List<TemporaryPauseEntity> pauses;
  final DateTime? lastTick;
  final String? actionMessage;

  TemporaryPauseLoaded copyWith({
    List<TemporaryPauseEntity>? pauses,
    DateTime? lastTick,
    String? actionMessage,
    bool clearActionMessage = false,
  }) {
    return TemporaryPauseLoaded(
      pauses: pauses ?? this.pauses,
      lastTick: lastTick ?? this.lastTick,
      actionMessage: clearActionMessage ? null : actionMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemporaryPauseLoaded &&
          listEquals(pauses, other.pauses) &&
          lastTick == other.lastTick &&
          actionMessage == other.actionMessage;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(pauses),
        lastTick,
        actionMessage,
      );
}

class TemporaryPauseError extends TemporaryPauseState {
  const TemporaryPauseError({
    required this.message,
    this.pauses = const [],
  });

  final String message;
  final List<TemporaryPauseEntity> pauses;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemporaryPauseError &&
          message == other.message &&
          listEquals(pauses, other.pauses);

  @override
  int get hashCode => Object.hash(message, Object.hashAll(pauses));
}
