import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/temporary_pause_entity.dart';
import '../repositories/temporary_pause_repository.dart';

class ReconcileExpiredPausesParams {
  const ReconcileExpiredPausesParams({this.currentTime});

  final DateTime? currentTime;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReconcileExpiredPausesParams &&
          runtimeType == other.runtimeType &&
          currentTime == other.currentTime;

  @override
  int get hashCode => currentTime.hashCode;
}

class ReconcileExpiredPausesUseCase
    implements UseCase<List<TemporaryPauseEntity>, ReconcileExpiredPausesParams> {
  const ReconcileExpiredPausesUseCase(this.repository);

  final TemporaryPauseRepository repository;

  @override
  Future<Either<Failure, List<TemporaryPauseEntity>>> call(
    ReconcileExpiredPausesParams params,
  ) {
    return repository.reconcileExpiredPauses(currentTime: params.currentTime);
  }
}
