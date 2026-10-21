// ignore_for_file: prefer_initializing_formals

import 'package:hive/hive.dart';

import '../models/app_info_model.dart';
import 'local_storage_data_source.dart';

abstract class AppLocalDataSource {
  Future<bool> isFirstLaunch();
  Future<void> setFirstLaunchCompleted();
  Future<List<AppInfoModel>> getCachedApps();
  Future<void> cacheApps(List<AppInfoModel> apps);
  Future<void> saveApp(AppInfoModel app);
  Future<void> deleteApps(List<String> packageNames);
  Future<void> clearAll();
}

class AppLocalDataSourceImpl implements AppLocalDataSource {
  AppLocalDataSourceImpl({
    required Box<Map> appsBox,
    required Box<dynamic> settingsBox,
  })  : _appsBox = appsBox,
        _settingsBox = settingsBox;

  static const appsBoxName = 'net_guard_apps_box';
  static const settingsBoxName = 'net_guard_settings_box';
  static const _firstLaunchKey = 'is_first_launch_completed';

  final Box<Map> _appsBox;
  final Box<dynamic> _settingsBox;

  @override
  Future<bool> isFirstLaunch() async {
    try {
      final isCompleted = _settingsBox.get(_firstLaunchKey, defaultValue: false) as bool;
      return !isCompleted;
    } catch (error) {
      throw LocalStorageException('Unable to check first launch: $error');
    }
  }

  @override
  Future<void> setFirstLaunchCompleted() async {
    try {
      await _settingsBox.put(_firstLaunchKey, true);
    } catch (error) {
      throw LocalStorageException('Unable to set first launch completed: $error');
    }
  }

  @override
  Future<List<AppInfoModel>> getCachedApps() async {
    try {
      final apps = <AppInfoModel>[];
      for (final value in _appsBox.values) {
        apps.add(AppInfoModel.fromMap(Map<dynamic, dynamic>.from(value)));
      }
      return List.unmodifiable(apps);
    } catch (error) {
      throw LocalStorageException('Unable to read cached applications: $error');
    }
  }

  @override
  Future<void> cacheApps(List<AppInfoModel> apps) async {
    try {
      final entries = <String, Map<String, dynamic>>{
        for (final app in apps) app.packageName: app.toMap(),
      };
      await _appsBox.putAll(entries);
    } catch (error) {
      throw LocalStorageException('Unable to cache applications: $error');
    }
  }

  @override
  Future<void> saveApp(AppInfoModel app) async {
    try {
      await _appsBox.put(app.packageName, app.toMap());
    } catch (error) {
      throw LocalStorageException('Unable to save application ${app.packageName}: $error');
    }
  }

  @override
  Future<void> deleteApps(List<String> packageNames) async {
    try {
      await _appsBox.deleteAll(packageNames);
    } catch (error) {
      throw LocalStorageException('Unable to delete applications from cache: $error');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await _appsBox.clear();
      await _settingsBox.clear();
    } catch (error) {
      throw LocalStorageException('Unable to clear local storage: $error');
    }
  }
}
