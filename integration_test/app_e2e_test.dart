import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:installed_apps/app_category.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/platform_type.dart';
import 'package:net_guard/core/di/injection_container.dart';
import 'package:net_guard/features/app_blocker/data/datasources/installed_apps_data_source.dart';
import 'package:net_guard/features/app_blocker/presentation/widgets/app_card.dart';
import 'package:net_guard/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockTestInstalledAppsGateway implements InstalledAppsGateway {
  @override
  Future<List<AppInfo>> getUserLaunchableApps() async {
    return [
      AppInfo(
        name: 'Browser App',
        icon: Uint8List.fromList([1, 2, 3]),
        packageName: 'com.test.browser',
        versionName: '1.0',
        versionCode: 1,
        platformType: PlatformType.nativeOrOthers,
        installedTimestamp: 0,
        isSystemApp: false,
        isLaunchableApp: true,
        category: AppCategory.undefined,
      ),
      AppInfo(
        name: 'Chat App',
        icon: Uint8List.fromList([1, 2, 3]),
        packageName: 'com.test.chat',
        versionName: '1.0',
        versionCode: 1,
        platformType: PlatformType.nativeOrOthers,
        installedTimestamp: 0,
        isSystemApp: false,
        isLaunchableApp: true,
        category: AppCategory.undefined,
      ),
    ];
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final trafficCalls = <MethodCall>[];

  setUp(() async {
    trafficCalls.clear();
    SharedPreferences.setMockInitialValues({});

    const channel = MethodChannel('com.example.blocker/traffic');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      trafficCalls.add(call);
      return null;
    });

    await serviceLocator.reset();
    await Hive.initFlutter();
    await initializeDependencies();

    // Override the gateway with test launchable apps
    if (serviceLocator.isRegistered<InstalledAppsGateway>()) {
      serviceLocator.unregister<InstalledAppsGateway>();
    }
    serviceLocator.registerLazySingleton<InstalledAppsGateway>(
      MockTestInstalledAppsGateway.new,
    );
    if (serviceLocator.isRegistered<InstalledAppsDataSource>()) {
      serviceLocator.unregister<InstalledAppsDataSource>();
    }
    serviceLocator.registerLazySingleton<InstalledAppsDataSource>(
      () => InstalledAppsDataSourceImpl(serviceLocator()),
    );
  });

  tearDown(() async {
    const channel = MethodChannel('com.example.blocker/traffic');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets(
    'E2E Flow: Launch App -> Verify Dashboard -> Toggle Internet Off -> Toggle Internet On -> Search App',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 1. Launch App
      await tester.pumpWidget(const NetGuardApp());
      await tester.pumpAndSettle();

      // Verify single Dashboard page renders
      expect(find.text('NETGUARD'), findsOneWidget);
      expect(find.text('Firewall Dashboard'), findsOneWidget);
      expect(find.text('All Allowed'), findsOneWidget);

      // Verify apps loaded
      expect(find.byType(AppCard), findsNWidgets(2));
      expect(find.text('Browser App'), findsOneWidget);
      expect(find.text('Chat App'), findsOneWidget);
      expect(find.text('Internet Allowed'), findsNWidgets(2));

      // 2. Disable internet for Browser App (Toggle OFF -> Blocked)
      final switches = find.byType(Switch);
      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      expect(find.text('1 Blocked'), findsOneWidget);
      expect(find.text('Internet Blocked'), findsOneWidget);
      expect(
        trafficCalls.any(
          (c) =>
              c.method == 'updateBlockedList' &&
              (c.arguments['blockedPackages'] as List).contains('com.test.browser'),
        ),
        isTrue,
      );

      // 3. Re-enable internet for Browser App (Toggle ON -> Allowed)
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(find.text('All Allowed'), findsOneWidget);
      expect(find.text('Internet Allowed'), findsNWidgets(2));
      expect(trafficCalls.any((c) => c.method == 'stopVpnService'), isTrue);

      // 4. Search for specific app
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Chat');
      await tester.pumpAndSettle();

      expect(find.text('Chat App'), findsOneWidget);
      expect(find.text('Browser App'), findsNothing);
    },
  );
}
