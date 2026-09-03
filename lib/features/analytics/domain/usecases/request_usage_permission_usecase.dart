import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/analytics_repository.dart';

class RequestUsagePermissionUseCase implements UseCase<void, NoParams> {
  const RequestUsagePermissionUseCase(this._repository);

  final AnalyticsRepository _repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return _repository.requestUsagePermission();
  }
}
