import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/schedule_entity.dart';
import '../repositories/schedule_repository.dart';

class ToggleScheduleActiveParams {
  const ToggleScheduleActiveParams({
    required this.id,
    required this.isEnabled,
  });

  final String id;
  final bool isEnabled;
}

class ToggleScheduleActiveUseCase
    implements UseCase<ScheduleEntity, ToggleScheduleActiveParams> {
  const ToggleScheduleActiveUseCase(this._repository);

  final ScheduleRepository _repository;

  @override
  Future<Either<Failure, ScheduleEntity>> call(
    ToggleScheduleActiveParams params,
  ) {
    return _repository.toggleScheduleActive(params.id, params.isEnabled);
  }
}
