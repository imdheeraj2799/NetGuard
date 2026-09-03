import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/app_blocker_repository.dart';

class ToggleBlockStatusParams {
  const ToggleBlockStatusParams({
    required this.packageName,
    required this.isBlocked,
  });

  final String packageName;
  final bool isBlocked;
}

class ToggleBlockStatusUseCase
    implements UseCase<void, ToggleBlockStatusParams> {
  ToggleBlockStatusUseCase(this._repository);

  final AppBlockerRepository _repository;

  @override
  Future<Either<Failure, void>> call(ToggleBlockStatusParams params) =>
      _repository.toggleBlockStatus(
        packageName: params.packageName,
        isBlocked: params.isBlocked,
      );
}
