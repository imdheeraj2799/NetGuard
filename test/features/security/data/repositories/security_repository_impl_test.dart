import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/features/security/data/datasources/biometric_data_source.dart';
import 'package:net_guard/features/security/data/datasources/security_storage_data_source.dart';
import 'package:net_guard/features/security/data/repositories/security_repository_impl.dart';
import 'package:net_guard/features/security/domain/entities/security_settings_entity.dart';

class MockSecurityStorageDataSource extends Mock
    implements SecurityStorageDataSource {}

class MockBiometricDataSource extends Mock implements BiometricDataSource {}

void main() {
  late MockSecurityStorageDataSource mockStorage;
  late MockBiometricDataSource mockBio;
  late SecurityRepositoryImpl repository;

  setUp(() {
    mockStorage = MockSecurityStorageDataSource();
    mockBio = MockBiometricDataSource();
    repository = SecurityRepositoryImpl(
      storageDataSource: mockStorage,
      biometricDataSource: mockBio,
    );
  });

  group('SecurityRepositoryImpl Tests', () {
    test('checkBiometricsAvailable returns Right(bool)', () async {
      when(() => mockBio.canCheckBiometrics()).thenAnswer((_) async => true);

      final result = await repository.checkBiometricsAvailable();

      expect(result, const Right(true));
      verify(() => mockBio.canCheckBiometrics()).called(1);
    });

    test('authenticateBiometrics returns Right(bool)', () async {
      when(() => mockBio.authenticate(reason: any(named: 'reason')))
          .thenAnswer((_) async => true);

      final result = await repository.authenticateBiometrics();

      expect(result, const Right(true));
      verify(() => mockBio.authenticate(reason: any(named: 'reason'))).called(1);
    });

    test('verifyMasterPasscode returns Right(true) when matching', () async {
      when(() => mockStorage.readMasterPasscode())
          .thenAnswer((_) async => '9999');

      final result = await repository.verifyMasterPasscode('9999');

      expect(result, const Right(true));
    });

    test('verifyMasterPasscode returns Right(false) when mismatch', () async {
      when(() => mockStorage.readMasterPasscode())
          .thenAnswer((_) async => '9999');

      final result = await repository.verifyMasterPasscode('1111');

      expect(result, const Right(false));
    });

    test('setMasterPasscode calls storage write', () async {
      when(() => mockStorage.writeMasterPasscode('4321'))
          .thenAnswer((_) async {});

      final result = await repository.setMasterPasscode('4321');

      expect(result, const Right(null));
      verify(() => mockStorage.writeMasterPasscode('4321')).called(1);
    });

    test('toggleBiometrics calls storage setBiometricsEnabled', () async {
      when(() => mockStorage.setBiometricsEnabled(true))
          .thenAnswer((_) async {});

      final result = await repository.toggleBiometrics(true);

      expect(result, const Right(null));
      verify(() => mockStorage.setBiometricsEnabled(true)).called(1);
    });

    test('getSecuritySettings constructs entity correctly', () async {
      when(() => mockStorage.isBiometricsEnabled()).thenAnswer((_) async => true);
      when(() => mockStorage.readMasterPasscode()).thenAnswer((_) async => '1234');
      when(() => mockStorage.getAutoLockDuration()).thenAnswer((_) async => 5);

      final result = await repository.getSecuritySettings();

      expect(
        result,
        const Right(
          SecuritySettingsEntity(
            isBiometricsEnabled: true,
            hasMasterPasscode: true,
            autoLockDurationMinutes: 5,
          ),
        ),
      );
    });
  });
}
