import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app_blocker/data/datasources/local_storage_data_source.dart';
import '../models/temporary_pause_model.dart';

abstract class TemporaryPauseLocalDataSource {
  Future<List<TemporaryPauseModel>> getPauses();
  Future<void> savePause(TemporaryPauseModel pause);
  Future<void> deletePause(String id);
  Future<List<TemporaryPauseModel>> clearExpiredPauses({DateTime? currentTime});
  Future<void> clearAllPauses();
}

class TemporaryPauseLocalDataSourceImpl implements TemporaryPauseLocalDataSource {
  TemporaryPauseLocalDataSourceImpl({
    required this.pausesBox,
    required this.preferences,
  });

  static const pausesBoxName = 'net_guard_temporary_pauses_box';
  static const pausesSharedPrefsKey = 'temporary_pauses_json';

  final Box<Map> pausesBox;
  final SharedPreferences preferences;

  @override
  Future<List<TemporaryPauseModel>> getPauses() async {
    try {
      final list = <TemporaryPauseModel>[];
      for (final value in pausesBox.values) {
        list.add(TemporaryPauseModel.fromMap(Map<dynamic, dynamic>.from(value)));
      }
      list.sort((a, b) => a.pauseUntil.compareTo(b.pauseUntil));
      return List.unmodifiable(list);
    } catch (error) {
      throw LocalStorageException('Unable to read temporary pauses: $error');
    }
  }

  @override
  Future<void> savePause(TemporaryPauseModel pause) async {
    try {
      await pausesBox.put(pause.id, pause.toMap());
      await _syncPausesToSharedPreferences();
    } catch (error) {
      throw LocalStorageException('Unable to save temporary pause ${pause.id}: $error');
    }
  }

  @override
  Future<void> deletePause(String id) async {
    try {
      await pausesBox.delete(id);
      await _syncPausesToSharedPreferences();
    } catch (error) {
      throw LocalStorageException('Unable to delete temporary pause $id: $error');
    }
  }

  @override
  Future<List<TemporaryPauseModel>> clearExpiredPauses({DateTime? currentTime}) async {
    try {
      final now = currentTime ?? DateTime.now();
      final all = await getPauses();
      final expired = <TemporaryPauseModel>[];
      for (final pause in all) {
        if (pause.isExpired(now)) {
          expired.add(pause);
          await pausesBox.delete(pause.id);
        }
      }
      if (expired.isNotEmpty) {
        await _syncPausesToSharedPreferences();
      }
      return expired;
    } catch (error) {
      throw LocalStorageException('Unable to clear expired pauses: $error');
    }
  }

  @override
  Future<void> clearAllPauses() async {
    try {
      await pausesBox.clear();
      await _syncPausesToSharedPreferences();
    } catch (error) {
      throw LocalStorageException('Unable to clear all temporary pauses: $error');
    }
  }

  Future<void> _syncPausesToSharedPreferences() async {
    try {
      final all = await getPauses();
      final maps = all.map((m) => m.toMap()).toList(growable: false);
      await preferences.setString(pausesSharedPrefsKey, jsonEncode(maps));
    } catch (_) {
      // Non-fatal SharedPreferences mirror sync
    }
  }
}
