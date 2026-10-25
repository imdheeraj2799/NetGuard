import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/temporary_pause_entity.dart';
import '../repositories/temporary_pause_repository.dart';

class CreateTemporaryPauseParams {
  const CreateTemporaryPauseParams({
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
      other is CreateTemporaryPauseParams &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName &&
          appName == other.appName &&
          duration == other.duration &&
          isCustom == other.isCustom;

  @override
  int get hashCode => Object.hash(packageName, appName, duration, isCustom);
}

class CreateTemporaryPauseUseCase
    implements UseCase<TemporaryPauseEntity, CreateTemporaryPauseParams> {
  const CreateTemporaryPauseUseCase(this.repository);

  final TemporaryPauseRepository repository;

  @override
  Future<Either<Failure, TemporaryPauseEntity>> call(
    CreateTemporaryPauseParams params,
  ) async {
    if (params.packageName.trim().isEmpty) {
      return const Left(ValidationFailure('Package name cannot be empty'));
    }
    if (params.duration.inSeconds <= 0) {
      return const Left(ValidationFailure('Pause duration must be greater than zero'));
    }

    return repository.createPause(
      packageName: params.packageName,
      appName: params.appName,
      duration: params.duration,
      isCustom: params.isCustom,
    );
  }
}
