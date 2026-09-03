import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:net_guard/core/di/injection_container.dart';
import 'package:net_guard/features/security/presentation/widgets/security_lock_dialog.dart';
import 'package:net_guard/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final methodCalls = <String, List<MethodCall>>{
    'com.app.net_guard/traffic': [],
    'com.app.net_guard/dns_filter': [],
    'com.app.net_guard/analytics': [],
  };

  setUp(() async {
    methodCalls.forEach((_, list) => list.clear());
    SharedPreferences.setMockInitialValues({});

    // Register mock handlers for native channels
    for (final channelName in methodCalls.keys) {
      final channel = MethodChannel(channelName);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        methodCalls[channelName]!.add(call);

        if (call.method == 'checkUsagePermission') {
          return true;
        }
        if (call.method == 'getAppUsageAnalytics') {
          return {
            'apps': [
              {
                'packageName': 'com.instagram.android',
                'appName': 'Instagram',
                'screenTimeSeconds': 3600,
                'wifiDataBytes': 1048576,
                'mobileDataBytes': 524288,
                'timestampRange': 'week',
              },
            ],
            'dailyScreenTime': [100, 200, 300, 400, 500, 600, 700],
            'dailyLabels': ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
            'totalScreenTimeSeconds': 3600,
            'totalDataBytes': 1572864,
            'averageDailySeconds': 514,
          };
        }
        return null;
      });
    }

    await serviceLocator.reset();
    await initializeDependencies();
  });

  tearDown(() async {
    for (final channelName in methodCalls.keys) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channelName), null);
    }
  });

  testWidgets(
    'E2E System Flow: Launch App -> Biometric Auth -> Open Analytics -> Create Time Schedule -> Toggle Custom DNS',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 1. Launch App
      await tester.pumpWidget(const NetGuardApp());
      await tester.pumpAndSettle();

      expect(find.text('NETGATE // SHIELD'), findsOneWidget);
      expect(find.text('Access Control'), findsOneWidget);

      // 2. Open Security Lock Dialog / Biometric Setup
      final pageContext = tester.element(find.byType(Scaffold).first);
      SecurityLockDialog.show(pageContext, isSetupMode: true);
      await tester.pumpAndSettle();

      expect(find.text('SETUP MASTER PASSCODE'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '1234');
      await tester.enterText(find.byType(TextField).last, '1234');
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      // 3. Open Analytics Page
      await tester.tap(find.byIcon(Icons.bar_chart_rounded));
      await tester.pumpAndSettle();

      expect(find.text('NETGATE // ANALYTICS'), findsOneWidget);
      expect(find.text('Usage Statistics'), findsOneWidget);
      expect(find.text('TOTAL TIME'), findsOneWidget);

      // Go back to Access Control
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      // 4. Create Time-Based Schedule
      await tester.tap(find.text('WEAVE NEW RULE'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Time-Based Schedule'));
      await tester.pumpAndSettle();

      expect(find.text('NEW RESTRICTION WINDOW'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'e.g. Focus Hours'),
        'Deep Work',
      );
      await tester.tap(find.text('SAVE SCHEDULE'));
      await tester.pumpAndSettle();

      expect(find.text('Deep Work'), findsOneWidget);

      // 5. Navigate to Shield Settings & Toggle Custom DNS
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.text('NETGATE // SECURITY'), findsOneWidget);
      expect(find.text('Shield Settings'), findsOneWidget);

      // Tap Custom DNS tile to open selection dialog
      await tester.tap(find.text('Custom DNS'));
      await tester.pumpAndSettle();

      expect(find.text('SELECT DNS RESOLVER'), findsOneWidget);
      await tester.tap(find.text('Google Public DNS'));
      await tester.pump();
      await tester.tap(find.text('APPLY'));
      await tester.pumpAndSettle();

      // Verify MethodChannel calls
      final dnsCalls = methodCalls['com.app.net_guard/dns_filter']!;
      expect(
        dnsCalls.any(
          (c) =>
              c.method == 'setCustomDnsResolver' &&
              c.arguments['dnsServer'] == '8.8.8.8',
        ),
        isTrue,
      );
    },
  );
}
