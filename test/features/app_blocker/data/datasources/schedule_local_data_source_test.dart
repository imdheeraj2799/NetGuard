import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/features/app_blocker/data/datasources/local_storage_data_source.dart';
import 'package:net_guard/features/app_blocker/data/datasources/schedule_local_data_source.dart';
import 'package:net_guard/features/app_blocker/data/models/block_schedule_model.dart';
import 'package:net_guard/features/app_blocker/domain/entities/block_schedule_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockBox<T> extends Mock implements Box<T> {}

void main() {
  late MockBox<Map> mockBox;
  late SharedPreferences prefs;
  late ScheduleLocalDataSourceImpl dataSource;

  final schedule1 = BlockScheduleModel(
    id: 's-1',
    name: 'Work',
    packageNames: const ['com.work.app'],
    recurrence: ScheduleRecurrence.weekdays,
    startHour: 9,
    startMinute: 0,
    endHour: 17,
    endMinute: 0,
    isEnabled: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final schedule2 = BlockScheduleModel(
    id: 's-2',
    name: 'Sleep',
    packageNames: const ['com.social.app'],
    recurrence: ScheduleRecurrence.daily,
    startHour: 23,
    startMinute: 0,
    endHour: 6,
    endMinute: 0,
    isEnabled: false,
    createdAt: DateTime(2026, 1, 2),
    updatedAt: DateTime(2026, 1, 2),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockBox = MockBox<Map>();
    dataSource = ScheduleLocalDataSourceImpl(
      schedulesBox: mockBox,
      preferences: prefs,
    );
  });

  group('ScheduleLocalDataSourceImpl - getSchedules', () {
    test('returns empty list when box is empty', () async {
      when(() => mockBox.values).thenReturn([]);

      final result = await dataSource.getSchedules();

      expect(result, isEmpty);
    });

    test('returns schedules sorted descending by createdAt', () async {
      when(() => mockBox.values).thenReturn([schedule1.toMap(), schedule2.toMap()]);

      final result = await dataSource.getSchedules();

      expect(result.length, 2);
      expect(result.first.id, 's-2'); // created Jan 2
      expect(result.last.id, 's-1'); // created Jan 1
    });

    test('throws LocalStorageException if box throws', () async {
      when(() => mockBox.values).thenThrow(Exception('Disk read failure'));

      expect(() => dataSource.getSchedules(), throwsA(isA<LocalStorageException>()));
    });
  });

  group('ScheduleLocalDataSourceImpl - saveSchedule', () {
    test('puts schedule into box and syncs JSON to SharedPreferences', () async {
      when(() => mockBox.put('s-1', any())).thenAnswer((_) async {});
      when(() => mockBox.values).thenReturn([schedule1.toMap()]);

      await dataSource.saveSchedule(schedule1);

      verify(() => mockBox.put('s-1', schedule1.toMap())).called(1);

      final syncedJson = prefs.getString(ScheduleLocalDataSourceImpl.schedulesSharedPrefsKey);
      expect(syncedJson, isNotNull);
      final decoded = jsonDecode(syncedJson!) as List;
      expect(decoded.length, 1);
      expect(decoded.first['id'], 's-1');
    });

    test('throws LocalStorageException if put fails', () async {
      when(() => mockBox.put(any(), any())).thenThrow(Exception('Hive write lock'));

      expect(() => dataSource.saveSchedule(schedule1), throwsA(isA<LocalStorageException>()));
    });
  });

  group('ScheduleLocalDataSourceImpl - deleteSchedule', () {
    test('deletes schedule from box and updates SharedPreferences sync', () async {
      when(() => mockBox.delete('s-1')).thenAnswer((_) async {});
      when(() => mockBox.values).thenReturn([]);

      await dataSource.deleteSchedule('s-1');

      verify(() => mockBox.delete('s-1')).called(1);

      final syncedJson = prefs.getString(ScheduleLocalDataSourceImpl.schedulesSharedPrefsKey);
      expect(syncedJson, '[]');
    });

    test('throws LocalStorageException on delete failure', () async {
      when(() => mockBox.delete(any())).thenThrow(Exception('Delete failed'));

      expect(() => dataSource.deleteSchedule('s-1'), throwsA(isA<LocalStorageException>()));
    });
  });

  group('ScheduleLocalDataSourceImpl - toggleSchedule', () {
    test('updates isEnabled and updatedAt when schedule exists in box', () async {
      when(() => mockBox.get('s-1')).thenReturn(schedule1.toMap());
      when(() => mockBox.put('s-1', any())).thenAnswer((_) async {});
      when(() => mockBox.values).thenReturn([
        schedule1.copyWith(isEnabled: false).toMap(),
      ]);

      await dataSource.toggleSchedule(id: 's-1', isEnabled: false);

      verify(() => mockBox.put('s-1', any())).called(1);
    });

    test('does nothing if schedule id is not in box', () async {
      when(() => mockBox.get('s-missing')).thenReturn(null);

      await dataSource.toggleSchedule(id: 's-missing', isEnabled: true);

      verifyNever(() => mockBox.put(any(), any()));
    });
  });

  group('ScheduleLocalDataSourceImpl - clearAllSchedules', () {
    test('clears Hive box and removes key from SharedPreferences', () async {
      when(() => mockBox.clear()).thenAnswer((_) async => 0);
      await prefs.setString(ScheduleLocalDataSourceImpl.schedulesSharedPrefsKey, '["data"]');

      await dataSource.clearAllSchedules();

      verify(() => mockBox.clear()).called(1);
      expect(prefs.containsKey(ScheduleLocalDataSourceImpl.schedulesSharedPrefsKey), isFalse);
    });
  });
}
