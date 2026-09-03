import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/features/security/data/datasources/security_storage_data_source.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecurityStorageDataSourceImpl dataSource;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    dataSource = SecurityStorageDataSourceImpl(mockStorage);
  });

  group('SecurityStorageDataSourceImpl Tests', () {
    test('readMasterPasscode reads key net_guard_master_passcode', () async {
      when(() => mockStorage.read(key: 'net_guard_master_passcode'))
          .thenAnswer((_) async => '1234');

      final result = await dataSource.readMasterPasscode();

      expect(result, '1234');
      verify(() => mockStorage.read(key: 'net_guard_master_passcode')).called(1);
    });

    test('writeMasterPasscode writes key net_guard_master_passcode', () async {
      when(() => mockStorage.write(
            key: 'net_guard_master_passcode',
            value: '5678',
          )).thenAnswer((_) async {});

      await dataSource.writeMasterPasscode('5678');

      verify(() => mockStorage.write(
            key: 'net_guard_master_passcode',
            value: '5678',
          )).called(1);
    });

    test('isBiometricsEnabled returns true when stored value is true', () async {
      when(() => mockStorage.read(key: 'net_guard_biometrics_enabled'))
          .thenAnswer((_) async => 'true');

      final result = await dataSource.isBiometricsEnabled();

      expect(result, true);
    });

    test('setBiometricsEnabled writes string true or false', () async {
      when(() => mockStorage.write(
            key: 'net_guard_biometrics_enabled',
            value: 'true',
          )).thenAnswer((_) async {});

      await dataSource.setBiometricsEnabled(true);

      verify(() => mockStorage.write(
            key: 'net_guard_biometrics_enabled',
            value: 'true',
          )).called(1);
    });
  });
}
