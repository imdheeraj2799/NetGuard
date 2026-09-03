import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/core/error/failure.dart';
import 'package:net_guard/core/usecase/usecase.dart';
import 'package:net_guard/features/security/domain/entities/security_settings_entity.dart';
import 'package:net_guard/features/security/domain/repositories/security_repository.dart';
import 'package:net_guard/features/security/domain/usecases/authenticate_user_usecase.dart';
import 'package:net_guard/features/security/domain/usecases/get_security_settings_usecase.dart';
import 'package:net_guard/features/security/domain/usecases/set_master_passcode_usecase.dart';
import 'package:net_guard/features/security/domain/usecases/toggle_biometrics_usecase.dart';

class MockSecurityRepository extends Mock implements SecurityRepository {}

void main() {
  late MockSecurityRepository mockRepo;
  late AuthenticateUserUseCase authenticateUserUseCase;
  late SetMasterPasscodeUseCase setMasterPasscodeUseCase;
  late ToggleBiometricsUseCase toggleBiometricsUseCase;
  late GetSecuritySettingsUseCase getSecuritySettingsUseCase;

  setUp(() {
    mockRepo = MockSecurityRepository();
    authenticateUserUseCase = AuthenticateUserUseCase(mockRepo);
    setMasterPasscodeUseCase = SetMasterPasscodeUseCase(mockRepo);
    toggleBiometricsUseCase = ToggleBiometricsUseCase(mockRepo);
    getSecuritySettingsUseCase = GetSecuritySettingsUseCase(mockRepo);
  });

  group('Security Domain UseCases', () {
    test('AuthenticateUserUseCase verifies PIN when provided', () async {
      when(() => mockRepo.verifyMasterPasscode('1234'))
          .thenAnswer((_) async => const Right(true));

      final result = await authenticateUserUseCase(
        const AuthenticateUserParams(passcode: '1234', useBiometrics: false),
      );

      expect(result, const Right(true));
      verify(() => mockRepo.verifyMasterPasscode('1234')).called(1);
      verifyNever(() => mockRepo.checkBiometricsAvailable());
    });

    test('AuthenticateUserUseCase checks biometrics when useBiometrics is true', () async {
      when(() => mockRepo.checkBiometricsAvailable())
          .thenAnswer((_) async => const Right(true));
      when(() => mockRepo.authenticateBiometrics())
          .thenAnswer((_) async => const Right(true));

      final result = await authenticateUserUseCase(
        const AuthenticateUserParams(useBiometrics: true),
      );

      expect(result, const Right(true));
      verify(() => mockRepo.checkBiometricsAvailable()).called(1);
      verify(() => mockRepo.authenticateBiometrics()).called(1);
    });

    test('SetMasterPasscodeUseCase validates minimum 4 digits', () async {
      final result = await setMasterPasscodeUseCase(
        const SetMasterPasscodeParams(passcode: '12'),
      );

      expect(
        result,
        const Left(ValidationFailure('Passcode must be at least 4 digits.')),
      );
      verifyNever(() => mockRepo.setMasterPasscode(any()));
    });

    test('SetMasterPasscodeUseCase calls repository on valid passcode', () async {
      when(() => mockRepo.setMasterPasscode('1234'))
          .thenAnswer((_) async => const Right(null));

      final result = await setMasterPasscodeUseCase(
        const SetMasterPasscodeParams(passcode: '1234'),
      );

      expect(result, const Right(null));
      verify(() => mockRepo.setMasterPasscode('1234')).called(1);
    });

    test('ToggleBiometricsUseCase calls repository', () async {
      when(() => mockRepo.toggleBiometrics(true))
          .thenAnswer((_) async => const Right(null));

      final result = await toggleBiometricsUseCase(
        const ToggleBiometricsParams(isEnabled: true),
      );

      expect(result, const Right(null));
      verify(() => mockRepo.toggleBiometrics(true)).called(1);
    });

    test('GetSecuritySettingsUseCase returns settings from repository', () async {
      const expected = SecuritySettingsEntity(
        isBiometricsEnabled: true,
        hasMasterPasscode: true,
        autoLockDurationMinutes: 5,
      );

      when(() => mockRepo.getSecuritySettings())
          .thenAnswer((_) async => const Right(expected));

      final result = await getSecuritySettingsUseCase(NoParams());

      expect(result, const Right(expected));
      verify(() => mockRepo.getSecuritySettings()).called(1);
    });
  });
}
