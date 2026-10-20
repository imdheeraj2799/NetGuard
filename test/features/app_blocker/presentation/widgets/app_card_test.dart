import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:net_guard/features/app_blocker/domain/entities/app_info_entity.dart';
import 'package:net_guard/features/app_blocker/presentation/widgets/app_card.dart';

void main() {
  testWidgets('renders app name and internet allowed state correctly', (tester) async {
    const app = AppInfoEntity(
      appName: 'Web Browser',
      packageName: 'com.example.browser',
      isBlocked: false,
    );

    bool? toggledValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCard(
            app: app,
            onInternetAccessChanged: (val) => toggledValue = val,
          ),
        ),
      ),
    );

    expect(find.text('Web Browser'), findsOneWidget);
    expect(find.text('Internet Allowed'), findsOneWidget);

    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    final Switch switchWidget = tester.widget(switchFinder);
    expect(switchWidget.value, isTrue);

    // Toggle off (block internet)
    await tester.tap(switchFinder);
    await tester.pump();
    expect(toggledValue, isFalse);
  });

  testWidgets('renders blocked state and toggles back to allowed', (tester) async {
    const app = AppInfoEntity(
      appName: 'Social App',
      packageName: 'com.example.social',
      isBlocked: true,
    );

    bool? toggledValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCard(
            app: app,
            onInternetAccessChanged: (val) => toggledValue = val,
          ),
        ),
      ),
    );

    expect(find.text('Social App'), findsOneWidget);
    expect(find.text('Internet Blocked'), findsOneWidget);

    final switchFinder = find.byType(Switch);
    final Switch switchWidget = tester.widget(switchFinder);
    expect(switchWidget.value, isFalse);

    // Toggle on (allow internet)
    await tester.tap(switchFinder);
    await tester.pump();
    expect(toggledValue, isTrue);
  });

  testWidgets('renders app icon from iconBytes or fallback when null', (tester) async {
    const appWithoutIcon = AppInfoEntity(
      appName: 'Game',
      packageName: 'com.example.game',
      isBlocked: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCard(
            app: appWithoutIcon,
            onInternetAccessChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.android_rounded), findsOneWidget);
  });
}
