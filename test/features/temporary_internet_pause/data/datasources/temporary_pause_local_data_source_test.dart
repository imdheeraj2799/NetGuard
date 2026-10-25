import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/features/temporary_internet_pause/data/datasources/temporary_pause_local_data_source.dart';
import 'package:net_guard/features/temporary_internet_pause/data/models/temporary_pause_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockBox extends Mock implements Box<Map> {}
class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late MockBox mockBox;
  late MockSharedPreferences mockPrefs;
  late TemporaryPauseLocalDataSourceImpl dataSource;

  final now = DateTime(2026, 10, 23, 12, 0);
  final pauseModel = TemporaryPauseModel(
    id: 'p-1',
    packageName: 'com.test.app',
    appName: 'Test App',
    startTime: now,
    pauseUntil: now.add(const Duration(minutes: 15)),
    durationMillis: 15 * 60 * 1000,
    isCustom: false,
  );

  setUp(() {
    mockBox = MockBox();
    mockPrefs = MockSharedPreferences();
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
    dataSource = TemporaryPauseLocalDataSourceImpl(
      pausesBox: mockBox,
      preferences: mockPrefs,
    );
  });

  group('TemporaryPauseLocalDataSourceImpl', () {
    test('getPauses returns models from box values sorted by pauseUntil', () async {
      when(() => mockBox.values).thenReturn([pauseModel.toMap()]);

      final result = await dataSource.getPauses();

      expect(result.length, 1);
      expect(result.first.id, 'p-1');
      expect(result.first.packageName, 'com.test.app');
    });

    test('savePause stores map in box and mirrors to shared preferences', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
      when(() => mockBox.values).thenReturn([pauseModel.toMap()]);

      await dataSource.savePause(pauseModel);

      verify(() => mockBox.put('p-1', pauseModel.toMap())).called(1);
      verify(() => mockPrefs.setString(
            TemporaryPauseLocalDataSourceImpl.pausesSharedPrefsKey,
            any(),
          )).called(1);
    });

    test('deletePause removes item from box and syncs to shared preferences', () async {
      when(() => mockBox.delete(any())).thenAnswer((_) async {});
      when(() => mockBox.values).thenReturn([]);

      await dataSource.deletePause('p-1');

      verify(() => mockBox.delete('p-1')).called(1);
      verify(() => mockPrefs.setString(
            TemporaryPauseLocalDataSourceImpl.pausesSharedPrefsKey,
            any(),
          )).called(1);
    });

    test('clearExpiredPauses deletes expired entries and returns them', () async {
      final expired = TemporaryPauseModel(
        id: 'p-exp',
        packageName: 'com.expired.app',
        appName: 'Expired',
        startTime: now.subtract(const Duration(hours: 1)),
        pauseUntil: now.subtract(const Duration(minutes: 30)),
        durationMillis: 30 * 60 * 1000,
      );

      when(() => mockBox.values).thenReturn([expired.toMap(), pauseModel.toMap()]);
      when(() => mockBox.delete('p-exp')).thenAnswer((_) async {});

      final cleared = await dataSource.clearExpiredPauses(currentTime: now);

      expect(cleared.length, 1);
      expect(cleared.first.id, 'p-exp');
      verify(() => mockBox.delete('p-exp')).called(1);
      verify(() => mockPrefs.setString(any(), any())).called(1);
    });
  });
}
