// ignore_for_file: prefer_initializing_formals

import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/security_settings_entity.dart';
import '../../domain/repositories/security_repository.dart';
import '../datasources/biometric_data_source.dart';
import '../datasources/security_storage_data_source.dart';

class SecurityRepositoryImpl implements SecurityRepository {
  const SecurityRepositoryImpl({
    required SecurityStorageDataSource storageDataSource,
    required BiometricDataSource biometricDataSource,
  })  : _storageDataSource = storageDataSource,
        _biometricDataSource = biometricDataSource;

  final SecurityStorageDataSource _storageDataSource;
  final BiometricDataSource _biometricDataSource;

  @override
  Future<Either<Failure, bool>> checkBiometricsAvailable() async {
    try {
      final isAvailable = await _biometricDataSource.canCheckBiometrics();
      return Right(isAvailable);
    } catch (e) {
      return Left(PlatformFailure('Failed to check biometrics: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> authenticateBiometrics({
    String reason = 'Authenticate to access NetGuard Security',
  }) async {
    try {
      final success = await _biometricDataSource.authenticate(reason: reason);
      return Right(success);
    } catch (e) {
      return Left(PlatformFailure('Biometric authentication failed: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyMasterPasscode(String passcode) async {
    try {
      final storedPasscode = await _storageDataSource.readMasterPasscode();
      if (storedPasscode == null || storedPasscode.isEmpty) {
        return const Right(true); // No passcode configured yet
      }
      return Right(storedPasscode == passcode.trim());
    } catch (e) {
      return Left(StorageFailure('Failed to verify master passcode: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> setMasterPasscode(String passcode) async {
    try {
      await _storageDataSource.writeMasterPasscode(passcode.trim());
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('Failed to set master passcode: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleBiometrics(bool isEnabled) async {
    try {
      await _storageDataSource.setBiometricsEnabled(isEnabled);
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('Failed to update biometrics preference: $e'));
    }
  }

  @override
  Future<Either<Failure, SecuritySettingsEntity>> getSecuritySettings() async {
    try {
      final isBioEnabled = await _storageDataSource.isBiometricsEnabled();
      final passcode = await _storageDataSource.readMasterPasscode();
      final autoLockMinutes = await _storageDataSource.getAutoLockDuration();

      return Right(
        SecuritySettingsEntity(
          isBiometricsEnabled: isBioEnabled,
          hasMasterPasscode: passcode != null && passcode.isNotEmpty,
          autoLockDurationMinutes: autoLockMinutes,
        ),
      );
    } catch (e) {
      return Left(StorageFailure('Failed to read security settings: $e'));
    }
  }
}
