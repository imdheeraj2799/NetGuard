import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/analytics_repository.dart';

class CheckUsagePermissionUseCase implements UseCase<bool, NoParams> {
  const CheckUsagePermissionUseCase(this._repository);

  final AnalyticsRepository _repository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return _repository.checkUsagePermission();
  }
}
