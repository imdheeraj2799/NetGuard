import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/temporary_pause_entity.dart';
import '../repositories/temporary_pause_repository.dart';

class GetActivePausesUseCase implements UseCase<List<TemporaryPauseEntity>, NoParams> {
  const GetActivePausesUseCase(this.repository);

  final TemporaryPauseRepository repository;

  @override
  Future<Either<Failure, List<TemporaryPauseEntity>>> call(NoParams params) =>
      repository.getActivePauses();
}
