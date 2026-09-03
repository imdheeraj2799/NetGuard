import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/security_settings_entity.dart';
import '../repositories/security_repository.dart';

class GetSecuritySettingsUseCase
    implements UseCase<SecuritySettingsEntity, NoParams> {
  const GetSecuritySettingsUseCase(this._repository);

  final SecurityRepository _repository;

  @override
  Future<Either<Failure, SecuritySettingsEntity>> call(NoParams params) {
    return _repository.getSecuritySettings();
  }
}
