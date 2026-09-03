import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/security_repository.dart';

class SetMasterPasscodeParams {
  const SetMasterPasscodeParams({required this.passcode});

  final String passcode;
}

class SetMasterPasscodeUseCase
    implements UseCase<void, SetMasterPasscodeParams> {
  const SetMasterPasscodeUseCase(this._repository);

  final SecurityRepository _repository;

  @override
  Future<Either<Failure, void>> call(SetMasterPasscodeParams params) {
    if (params.passcode.trim().length < 4) {
      return Future.value(
        const Left(ValidationFailure('Passcode must be at least 4 digits.')),
      );
    }
    return _repository.setMasterPasscode(params.passcode.trim());
  }
}
