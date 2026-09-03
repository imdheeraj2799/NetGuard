import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/security_repository.dart';

class AuthenticateUserParams {
  const AuthenticateUserParams({
    this.passcode,
    this.useBiometrics = true,
  });

  final String? passcode;
  final bool useBiometrics;
}

class AuthenticateUserUseCase implements UseCase<bool, AuthenticateUserParams> {
  const AuthenticateUserUseCase(this._repository);

  final SecurityRepository _repository;

  @override
  Future<Either<Failure, bool>> call(AuthenticateUserParams params) async {
    if (params.passcode != null && params.passcode!.isNotEmpty) {
      return _repository.verifyMasterPasscode(params.passcode!);
    }

    if (params.useBiometrics) {
      final bioAvailableEither = await _repository.checkBiometricsAvailable();
      return bioAvailableEither.fold(
        (failure) => Left(failure),
        (isAvailable) async {
          if (!isAvailable) {
            return const Left(
              PlatformFailure('Biometrics not available on this device.'),
            );
          }
          return _repository.authenticateBiometrics();
        },
      );
    }

    return const Left(PlatformFailure('No authentication method provided.'));
  }
}
