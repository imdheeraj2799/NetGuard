import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/temporary_pause_entity.dart';

abstract class TemporaryPauseRepository {
  Future<Either<Failure, List<TemporaryPauseEntity>>> getActivePauses();

  Future<Either<Failure, TemporaryPauseEntity>> createPause({
    required String packageName,
    required String appName,
    required Duration duration,
    bool isCustom = false,
  });

  Future<Either<Failure, void>> cancelPause(String id);

  Future<Either<Failure, List<TemporaryPauseEntity>>> reconcileExpiredPauses({
    DateTime? currentTime,
  });

  Future<Either<Failure, Set<String>>> getActivePausedPackages({
    DateTime? currentTime,
  });
}
