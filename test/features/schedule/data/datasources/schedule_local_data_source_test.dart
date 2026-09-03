import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/features/schedule/data/datasources/schedule_local_data_source.dart';
import 'package:net_guard/features/schedule/data/models/schedule_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late MockSharedPreferences mockPrefs;
  late ScheduleLocalDataSourceImpl dataSource;

  const testModel = ScheduleModel(
    id: 's_test',
    name: 'Test Schedule',
    startTimeMinutes: 600,
    endTimeMinutes: 1200,
    activeDays: [1, 2, 3],
    targetPackages: ['com.test.app'],
    isEnabled: true,
  );

  setUp(() {
    mockPrefs = MockSharedPreferences();
    dataSource = ScheduleLocalDataSourceImpl(mockPrefs);
  });

  group('ScheduleLocalDataSource', () {
    test('returns empty list when SharedPreferences is empty', () async {
      when(() => mockPrefs.getString('net_guard_schedules')).thenReturn(null);

      final result = await dataSource.getSchedules();

      expect(result, isEmpty);
    });

    test('returns saved schedules when SharedPreferences has data', () async {
      final jsonList = [testModel.toJson()];
      when(() => mockPrefs.getString('net_guard_schedules'))
          .thenReturn(jsonEncode(jsonList));

      final result = await dataSource.getSchedules();

      expect(result.length, 1);
      expect(result.first.id, 's_test');
    });

    test('createSchedule appends and saves new schedule', () async {
      when(() => mockPrefs.getString('net_guard_schedules'))
          .thenReturn(jsonEncode([]));
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);

      final result = await dataSource.createSchedule(testModel);

      expect(result.id, 's_test');
      verify(() => mockPrefs.setString('net_guard_schedules', any())).called(1);
    });

    test('updateSchedule replaces matching schedule', () async {
      when(() => mockPrefs.getString('net_guard_schedules'))
          .thenReturn(jsonEncode([testModel.toJson()]));
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);

      final updated = testModel.copyWith(name: 'Updated Name');
      final model = ScheduleModel.fromEntity(updated);
      final result = await dataSource.updateSchedule(model);

      expect(result.name, 'Updated Name');
      verify(() => mockPrefs.setString('net_guard_schedules', any())).called(1);
    });

    test('deleteSchedule removes schedule by id', () async {
      when(() => mockPrefs.getString('net_guard_schedules'))
          .thenReturn(jsonEncode([testModel.toJson()]));
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);

      await dataSource.deleteSchedule('s_test');

      verify(() => mockPrefs.setString('net_guard_schedules', '[]')).called(1);
    });

    test('toggleSchedule modifies isEnabled property', () async {
      when(() => mockPrefs.getString('net_guard_schedules'))
          .thenReturn(jsonEncode([testModel.toJson()]));
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);

      final result = await dataSource.toggleSchedule('s_test', false);

      expect(result.isEnabled, isFalse);
      verify(() => mockPrefs.setString('net_guard_schedules', any())).called(1);
    });
  });
}
