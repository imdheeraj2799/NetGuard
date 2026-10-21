import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/features/app_blocker/data/datasources/app_local_data_source.dart';
import 'package:net_guard/features/app_blocker/data/datasources/local_storage_data_source.dart';
import 'package:net_guard/features/app_blocker/data/models/app_info_model.dart';

class MockAppsBox extends Mock implements Box<Map> {}

class MockSettingsBox extends Mock implements Box<dynamic> {}

void main() {
  late MockAppsBox appsBox;
  late MockSettingsBox settingsBox;
  late AppLocalDataSourceImpl dataSource;

  setUp(() {
    appsBox = MockAppsBox();
    settingsBox = MockSettingsBox();
    dataSource = AppLocalDataSourceImpl(
      appsBox: appsBox,
      settingsBox: settingsBox,
    );
  });

  group('isFirstLaunch', () {
    test('returns true when first launch flag has not been set', () async {
      when(() => settingsBox.get('is_first_launch_completed', defaultValue: false))
          .thenReturn(false);

      final result = await dataSource.isFirstLaunch();

      expect(result, isTrue);
    });

    test('returns false when first launch flag is already completed', () async {
      when(() => settingsBox.get('is_first_launch_completed', defaultValue: false))
          .thenReturn(true);

      final result = await dataSource.isFirstLaunch();

      expect(result, isFalse);
    });

    test('wraps errors in LocalStorageException', () async {
      when(() => settingsBox.get(any(), defaultValue: any(named: 'defaultValue')))
          .thenThrow(Exception('box corrupted'));

      expect(
        () => dataSource.isFirstLaunch(),
        throwsA(isA<LocalStorageException>()),
      );
    });
  });

  group('setFirstLaunchCompleted', () {
    test('writes true to settings box', () async {
      when(() => settingsBox.put('is_first_launch_completed', true))
          .thenAnswer((_) async {});

      await dataSource.setFirstLaunchCompleted();

      verify(() => settingsBox.put('is_first_launch_completed', true)).called(1);
    });
  });

  group('getCachedApps', () {
    test('reads and converts maps to AppInfoModel list', () async {
      final sampleBytes = Uint8List.fromList([1, 2, 3]);
      when(() => appsBox.values).thenReturn([
        {
          'appName': 'Browser',
          'packageName': 'com.browser',
          'isBlocked': true,
          'iconBytes': sampleBytes,
        },
      ]);

      final apps = await dataSource.getCachedApps();

      expect(apps.length, 1);
      expect(apps.first.appName, 'Browser');
      expect(apps.first.packageName, 'com.browser');
      expect(apps.first.isBlocked, isTrue);
      expect(apps.first.iconBytes, sampleBytes);
    });
  });

  group('cacheApps & saveApp & deleteApps', () {
    test('cacheApps stores all models mapped by packageName', () async {
      when(() => appsBox.putAll(any())).thenAnswer((_) async {});

      await dataSource.cacheApps([
        const AppInfoModel(
          appName: 'Chat',
          packageName: 'com.chat',
          isBlocked: false,
        ),
      ]);

      final captured = verify(() => appsBox.putAll(captureAny())).captured;
      final map = captured.single as Map<String, Map<String, dynamic>>;
      expect(map.containsKey('com.chat'), isTrue);
      expect(map['com.chat']?['appName'], 'Chat');
    });

    test('saveApp stores a single app model', () async {
      when(() => appsBox.put(any(), any())).thenAnswer((_) async {});

      await dataSource.saveApp(
        const AppInfoModel(
          appName: 'Chat',
          packageName: 'com.chat',
          isBlocked: true,
        ),
      );

      verify(() => appsBox.put('com.chat', any())).called(1);
    });

    test('deleteApps calls deleteAll on apps box', () async {
      when(() => appsBox.deleteAll(any())).thenAnswer((_) async {});

      await dataSource.deleteApps(['com.uninstalled']);

      verify(() => appsBox.deleteAll(['com.uninstalled'])).called(1);
    });

    test('clearAll clears both boxes', () async {
      when(() => appsBox.clear()).thenAnswer((_) async => 0);
      when(() => settingsBox.clear()).thenAnswer((_) async => 0);

      await dataSource.clearAll();

      verify(() => appsBox.clear()).called(1);
      verify(() => settingsBox.clear()).called(1);
    });
  });
}
