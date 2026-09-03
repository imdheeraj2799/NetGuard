import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_model.dart';

class ScheduleLocalDataSourceException implements Exception {
  const ScheduleLocalDataSourceException(this.message);
  final String message;

  @override
  String toString() => 'ScheduleLocalDataSourceException: $message';
}

abstract class ScheduleLocalDataSource {
  Future<List<ScheduleModel>> getSchedules();
  Future<ScheduleModel> createSchedule(ScheduleModel schedule);
  Future<ScheduleModel> updateSchedule(ScheduleModel schedule);
  Future<void> deleteSchedule(String id);
  Future<ScheduleModel> toggleSchedule(String id, bool isEnabled);
}

class ScheduleLocalDataSourceImpl implements ScheduleLocalDataSource {
  const ScheduleLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;
  static const _storageKey = 'net_guard_schedules';

  @override
  Future<List<ScheduleModel>> getSchedules() async {
    try {
      final rawJson = _prefs.getString(_storageKey);
      if (rawJson == null || rawJson.trim().isEmpty) {
        return const [];
      }
      final decoded = jsonDecode(rawJson) as List<dynamic>;
      return decoded
          .map((item) => ScheduleModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ScheduleLocalDataSourceException('Failed to load schedules: $e');
    }
  }

  @override
  Future<ScheduleModel> createSchedule(ScheduleModel schedule) async {
    try {
      final list = await getSchedules();
      final updated = [...list, schedule];
      await _persistSchedules(updated);
      return schedule;
    } catch (e) {
      throw ScheduleLocalDataSourceException('Failed to create schedule: $e');
    }
  }

  @override
  Future<ScheduleModel> updateSchedule(ScheduleModel schedule) async {
    try {
      final list = await getSchedules();
      final index = list.indexWhere((s) => s.id == schedule.id);
      if (index == -1) {
        throw ScheduleLocalDataSourceException(
          'Schedule not found with id: ${schedule.id}',
        );
      }
      final updated = List<ScheduleModel>.from(list)..[index] = schedule;
      await _persistSchedules(updated);
      return schedule;
    } catch (e) {
      throw ScheduleLocalDataSourceException('Failed to update schedule: $e');
    }
  }

  @override
  Future<void> deleteSchedule(String id) async {
    try {
      final list = await getSchedules();
      final updated = list.where((s) => s.id != id).toList();
      await _persistSchedules(updated);
    } catch (e) {
      throw ScheduleLocalDataSourceException('Failed to delete schedule: $e');
    }
  }

  @override
  Future<ScheduleModel> toggleSchedule(String id, bool isEnabled) async {
    try {
      final list = await getSchedules();
      final index = list.indexWhere((s) => s.id == id);
      if (index == -1) {
        throw ScheduleLocalDataSourceException('Schedule not found with id: $id');
      }
      final toggled = list[index].copyWith(isEnabled: isEnabled);
      final model = ScheduleModel.fromEntity(toggled);
      final updated = List<ScheduleModel>.from(list)..[index] = model;
      await _persistSchedules(updated);
      return model;
    } catch (e) {
      throw ScheduleLocalDataSourceException('Failed to toggle schedule: $e');
    }
  }

  Future<void> _persistSchedules(List<ScheduleModel> schedules) async {
    final encoded = jsonEncode(schedules.map((s) => s.toJson()).toList());
    final success = await _prefs.setString(_storageKey, encoded);
    if (!success) {
      throw const ScheduleLocalDataSourceException(
        'Failed to save schedules to SharedPreferences',
      );
    }
  }
}
