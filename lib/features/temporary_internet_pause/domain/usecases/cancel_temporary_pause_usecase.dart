import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/temporary_pause_repository.dart';

class CancelTemporaryPauseParams {
  const CancelTemporaryPauseParams(this.id);

  final String id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CancelTemporaryPauseParams &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class CancelTemporaryPauseUseCase
    implements UseCase<void, CancelTemporaryPauseParams> {
  const CancelTemporaryPauseUseCase(this.repository);

  final TemporaryPauseRepository repository;

  @override
  Future<Either<Failure, void>> call(CancelTemporaryPauseParams params) {
    if (params.id.trim().isEmpty) {
      return Future.value(const Left(ValidationFailure('Pause ID cannot be empty')));
    }
    return repository.cancelPause(params.id);
  }
}
