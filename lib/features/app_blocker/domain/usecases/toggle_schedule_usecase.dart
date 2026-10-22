import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/schedule_repository.dart';

class ToggleScheduleParams {
  const ToggleScheduleParams({
    required this.id,
    required this.isEnabled,
  });

  final String id;
  final bool isEnabled;
}

class ToggleScheduleUseCase implements UseCase<void, ToggleScheduleParams> {
  const ToggleScheduleUseCase(this.repository);

  final ScheduleRepository repository;

  @override
  Future<Either<Failure, void>> call(ToggleScheduleParams params) {
    return repository.toggleSchedule(
      id: params.id,
      isEnabled: params.isEnabled,
    );
  }
}
