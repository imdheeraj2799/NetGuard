import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStorageDataSource {
  Future<List<String>> getBlockedPackages();
  Future<void> setBlockedPackages(List<String> packageNames);
}

class LocalStorageDataSourceImpl implements LocalStorageDataSource {
  LocalStorageDataSourceImpl(this._preferences);

  static const blockedPackagesKey = 'blocked_packages';
  final SharedPreferences _preferences;

  @override
  Future<List<String>> getBlockedPackages() async {
    try {
      return List.unmodifiable(
        _preferences.getStringList(blockedPackagesKey) ?? const <String>[],
      );
    } catch (error) {
      throw LocalStorageException('Unable to read blocked packages: $error');
    }
  }

  @override
  Future<void> setBlockedPackages(List<String> packageNames) async {
    try {
      final saved = await _preferences.setStringList(
        blockedPackagesKey,
        packageNames.toSet().toList(growable: false),
      );
      if (!saved) {
        throw const LocalStorageException('Unable to save blocked packages');
      }
    } on LocalStorageException {
      rethrow;
    } catch (error) {
      throw LocalStorageException('Unable to save blocked packages: $error');
    }
  }
}

class LocalStorageException implements Exception {
  const LocalStorageException(this.message);
  final String message;
}
