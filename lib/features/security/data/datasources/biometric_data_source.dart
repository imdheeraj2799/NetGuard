import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

abstract class BiometricDataSource {
  Future<bool> canCheckBiometrics();
  Future<bool> isDeviceSupported();
  Future<bool> authenticate({required String reason});
}

class BiometricDataSourceImpl implements BiometricDataSource {
  const BiometricDataSourceImpl(this._localAuth);

  final LocalAuthentication _localAuth;

  @override
  Future<bool> canCheckBiometrics() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return isSupported && canCheck;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isDeviceSupported() {
    return _localAuth.isDeviceSupported();
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
      );
    } catch (_) {
      return false;
    }
  }
}
