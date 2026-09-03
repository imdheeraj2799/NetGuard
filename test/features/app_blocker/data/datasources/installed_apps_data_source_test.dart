import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:installed_apps/app_category.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/platform_type.dart';
import 'package:mocktail/mocktail.dart';
import 'package:net_guard/features/app_blocker/data/datasources/installed_apps_data_source.dart';

class MockInstalledAppsGateway extends Mock implements InstalledAppsGateway {}

void main() {
  late MockInstalledAppsGateway gateway;
  late InstalledAppsDataSourceImpl dataSource;

  setUp(() {
    gateway = MockInstalledAppsGateway();
    dataSource = InstalledAppsDataSourceImpl(gateway);
  });

  test('maps user-installed launchable apps from installed_apps', () async {
    final icon = Uint8List.fromList([1, 2, 3]);
    when(() => gateway.getUserLaunchableApps()).thenAnswer(
      (_) async => [
        AppInfo(
          name: 'Mail',
          icon: icon,
          packageName: 'com.example.mail',
          versionName: '1.0.0',
          versionCode: 1,
          platformType: PlatformType.nativeOrOthers,
          installedTimestamp: 0,
          isSystemApp: false,
          isLaunchableApp: true,
          category: AppCategory.undefined,
        ),
      ],
    );

    final apps = await dataSource.getInstalledApps();

    expect(apps, hasLength(1));
    expect(apps.single.appName, 'Mail');
    expect(apps.single.packageName, 'com.example.mail');
    expect(apps.single.iconBytes, icon);
  });

  test('wraps gateway errors as an installed-apps exception', () async {
    when(() => gateway.getUserLaunchableApps()).thenThrow(Exception('failed'));

    expect(
      dataSource.getInstalledApps(),
      throwsA(isA<InstalledAppsException>()),
    );
  });
}
