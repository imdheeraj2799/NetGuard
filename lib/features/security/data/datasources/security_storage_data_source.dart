import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecurityStorageDataSource {
  Future<String?> readMasterPasscode();
  Future<void> writeMasterPasscode(String passcode);
  Future<void> deleteMasterPasscode();
  Future<bool> isBiometricsEnabled();
  Future<void> setBiometricsEnabled(bool isEnabled);
  Future<int> getAutoLockDuration();
  Future<void> setAutoLockDuration(int minutes);
}

class SecurityStorageDataSourceImpl implements SecurityStorageDataSource {
  const SecurityStorageDataSourceImpl(this._storage);

  final FlutterSecureStorage _storage;

  static const _keyMasterPasscode = 'net_guard_master_passcode';
  static const _keyBiometricsEnabled = 'net_guard_biometrics_enabled';
  static const _keyAutoLockMinutes = 'net_guard_autolock_minutes';

  @override
  Future<String?> readMasterPasscode() {
    return _storage.read(key: _keyMasterPasscode);
  }

  @override
  Future<void> writeMasterPasscode(String passcode) {
    return _storage.write(key: _keyMasterPasscode, value: passcode);
  }

  @override
  Future<void> deleteMasterPasscode() {
    return _storage.delete(key: _keyMasterPasscode);
  }

  @override
  Future<bool> isBiometricsEnabled() async {
    final val = await _storage.read(key: _keyBiometricsEnabled);
    return val == 'true';
  }

  @override
  Future<void> setBiometricsEnabled(bool isEnabled) {
    return _storage.write(
      key: _keyBiometricsEnabled,
      value: isEnabled ? 'true' : 'false',
    );
  }

  @override
  Future<int> getAutoLockDuration() async {
    final val = await _storage.read(key: _keyAutoLockMinutes);
    if (val == null) return 5;
    return int.tryParse(val) ?? 5;
  }

  @override
  Future<void> setAutoLockDuration(int minutes) {
    return _storage.write(
      key: _keyAutoLockMinutes,
      value: minutes.toString(),
    );
  }
}
