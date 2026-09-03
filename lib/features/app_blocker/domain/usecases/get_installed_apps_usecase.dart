import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_info_entity.dart';
import '../repositories/app_blocker_repository.dart';

class GetInstalledAppsUseCase
    implements UseCase<List<AppInfoEntity>, NoParams> {
  GetInstalledAppsUseCase(this._repository);

  final AppBlockerRepository _repository;

  @override
  Future<Either<Failure, List<AppInfoEntity>>> call(NoParams params) =>
      _repository.getInstalledApps();
}
