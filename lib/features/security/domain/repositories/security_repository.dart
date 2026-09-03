import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/security_settings_entity.dart';

abstract class SecurityRepository {
  Future<Either<Failure, bool>> checkBiometricsAvailable();
  Future<Either<Failure, bool>> authenticateBiometrics({
    String reason = 'Authenticate to access NetGuard Security',
  });
  Future<Either<Failure, bool>> verifyMasterPasscode(String passcode);
  Future<Either<Failure, void>> setMasterPasscode(String passcode);
  Future<Either<Failure, void>> toggleBiometrics(bool isEnabled);
  Future<Either<Failure, SecuritySettingsEntity>> getSecuritySettings();
}
