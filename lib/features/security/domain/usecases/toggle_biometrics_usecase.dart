import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/security_repository.dart';

class ToggleBiometricsParams {
  const ToggleBiometricsParams({required this.isEnabled});

  final bool isEnabled;
}

class ToggleBiometricsUseCase
    implements UseCase<void, ToggleBiometricsParams> {
  const ToggleBiometricsUseCase(this._repository);

  final SecurityRepository _repository;

  @override
  Future<Either<Failure, void>> call(ToggleBiometricsParams params) {
    return _repository.toggleBiometrics(params.isEnabled);
  }
}
