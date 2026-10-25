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

  testWidgets('renders schedule badge and invokes onRestrictedTap instead of onInternetAccessChanged when app is part of schedule', (tester) async {
    const scheduledApp = AppInfoEntity(
      appName: 'YouTube',
      packageName: 'com.google.android.youtube',
      isBlocked: true,
      isSchedulePart: true,
      whichSchedule: 'Night Study',
    );

    bool toggled = false;
    int restrictedTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCard(
            app: scheduledApp,
            onInternetAccessChanged: (_) => toggled = true,
            onRestrictedTap: () => restrictedTaps++,
          ),
        ),
      ),
    );

    // Verify scheduled badge is visible
    expect(find.text('Night Study'), findsOneWidget);
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);

    // Tapping the switch must NOT toggle internet access, but call onRestrictedTap
    final switchFinder = find.byKey(const Key('app_card_toggle_com.google.android.youtube'));
    expect(switchFinder, findsOneWidget);
    await tester.tap(switchFinder);
    await tester.pump();

    expect(toggled, isFalse);
    expect(restrictedTaps, 1);

    // Tapping the card body also calls onRestrictedTap
    await tester.tap(find.text('YouTube'));
    await tester.pump();

    expect(toggled, isFalse);
    expect(restrictedTaps, 2);
  });

  testWidgets('renders temporary pause badge and invokes onRestrictedTap instead of onInternetAccessChanged when app is temporarily paused', (tester) async {
    const pausedApp = AppInfoEntity(
      appName: 'Netflix',
      packageName: 'com.netflix.mediaclient',
      isBlocked: false,
    );

    bool toggled = false;
    int restrictedTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCard(
            app: pausedApp,
            isTemporarilyPaused: true,
            pauseRemainingText: '14m',
            onInternetAccessChanged: (_) => toggled = true,
            onRestrictedTap: () => restrictedTaps++,
          ),
        ),
      ),
    );

    // Verify pause badge and status
    expect(find.text('14m'), findsOneWidget);
    expect(find.text('Temporarily Paused'), findsOneWidget);
    expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);

    // Tapping the switch must NOT toggle internet access, but call onRestrictedTap
    final switchFinder = find.byKey(const Key('app_card_toggle_com.netflix.mediaclient'));
    expect(switchFinder, findsOneWidget);
    await tester.tap(switchFinder);
    await tester.pump();

    expect(toggled, isFalse);
    expect(restrictedTaps, 1);

    // Tapping the card body also calls onRestrictedTap
    await tester.tap(find.text('Netflix'));
    await tester.pump();

    expect(toggled, isFalse);
    expect(restrictedTaps, 2);
  });
}
