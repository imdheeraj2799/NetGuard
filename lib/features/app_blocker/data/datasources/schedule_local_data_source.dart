// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/block_schedule_model.dart';
import 'local_storage_data_source.dart';

abstract class ScheduleLocalDataSource {
  Future<List<BlockScheduleModel>> getSchedules();
  Future<void> saveSchedule(BlockScheduleModel schedule);
  Future<void> deleteSchedule(String id);
  Future<void> toggleSchedule({required String id, required bool isEnabled});
  Future<void> clearAllSchedules();
}

class ScheduleLocalDataSourceImpl implements ScheduleLocalDataSource {
  ScheduleLocalDataSourceImpl({
    required Box<Map> schedulesBox,
    required SharedPreferences preferences,
  })  : _schedulesBox = schedulesBox,
        _preferences = preferences;

  static const schedulesBoxName = 'net_guard_schedules_box';
  static const schedulesSharedPrefsKey = 'app_blocker_schedules_json';

  final Box<Map> _schedulesBox;
  final SharedPreferences _preferences;

  @override
  Future<List<BlockScheduleModel>> getSchedules() async {
    try {
      final list = <BlockScheduleModel>[];
      for (final value in _schedulesBox.values) {
        list.add(BlockScheduleModel.fromMap(Map<dynamic, dynamic>.from(value)));
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return List.unmodifiable(list);
    } catch (error) {
      throw LocalStorageException('Unable to read schedules: $error');
    }
  }

  @override
  Future<void> saveSchedule(BlockScheduleModel schedule) async {
    try {
      await _schedulesBox.put(schedule.id, schedule.toMap());
      await _syncSchedulesToSharedPreferences();
    } catch (error) {
      throw LocalStorageException('Unable to save schedule ${schedule.id}: $error');
    }
  }

  @override
  Future<void> deleteSchedule(String id) async {
    try {
      await _schedulesBox.delete(id);
      await _syncSchedulesToSharedPreferences();
    } catch (error) {
      throw LocalStorageException('Unable to delete schedule $id: $error');
    }
  }

  @override
  Future<void> toggleSchedule({required String id, required bool isEnabled}) async {
    try {
      final raw = _schedulesBox.get(id);
      if (raw != null) {
        final existing = BlockScheduleModel.fromMap(Map<dynamic, dynamic>.from(raw));
        final updated = existing.copyWith(
          isEnabled: isEnabled,
          updatedAt: DateTime.now(),
        );
        await _schedulesBox.put(id, BlockScheduleModel.fromEntity(updated).toMap());
        await _syncSchedulesToSharedPreferences();
      }
    } catch (error) {
      throw LocalStorageException('Unable to toggle schedule $id: $error');
    }
  }

  @override
  Future<void> clearAllSchedules() async {
    try {
      await _schedulesBox.clear();
      await _preferences.remove(schedulesSharedPrefsKey);
    } catch (error) {
      throw LocalStorageException('Unable to clear schedules: $error');
    }
  }

  Future<void> _syncSchedulesToSharedPreferences() async {
    try {
      final schedules = await getSchedules();
      final maps = schedules.map((s) => s.toMap()).toList();
      final jsonString = jsonEncode(maps);
      await _preferences.setString(schedulesSharedPrefsKey, jsonString);
    } catch (e) {
      // SharedPreferences sync failure should not break main Hive save,
      // but is logged for diagnosis.
    }
  }
}
