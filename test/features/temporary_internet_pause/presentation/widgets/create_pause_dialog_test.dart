import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:net_guard/features/app_blocker/domain/entities/app_info_entity.dart';
import 'package:net_guard/features/temporary_internet_pause/domain/entities/pause_duration_preset.dart';
import 'package:net_guard/features/temporary_internet_pause/presentation/widgets/create_pause_dialog.dart';

void main() {
  const sampleApps = [
    AppInfoEntity(
      appName: 'Instagram',
      packageName: 'com.instagram.android',
      isBlocked: false,
    ),
    AppInfoEntity(
      appName: 'YouTube',
      packageName: 'com.google.android.youtube',
      isBlocked: false,
    ),
  ];

  Widget buildDialog({
    List<AppInfoEntity> apps = sampleApps,
    AppInfoEntity? preselectedApp,
    void Function(AppInfoEntity, Duration, bool)? onCreated,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CreatePauseDialog(
          installedApps: apps,
          preselectedApp: preselectedApp,
          onPauseCreated: onCreated ?? (app, duration, isCustom) {},
        ),
      ),
    );
  }

  testWidgets('renders CreatePauseDialog without ListTile assertion errors',
      (tester) async {
    await tester.pumpWidget(buildDialog());

    expect(find.text('Temporary Internet Pause'), findsOneWidget);
    expect(find.text('PAUSE DURATION'), findsOneWidget);
    expect(find.text('SELECT APPLICATION'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting an app updates selected application view',
      (tester) async {
    AppInfoEntity? createdApp;
    Duration? createdDuration;

    await tester.pumpWidget(
      buildDialog(
        onCreated: (app, dur, isCustom) {
          createdApp = app;
          createdDuration = dur;
        },
      ),
    );

    // Tap on Instagram ListTile
    await tester.tap(find.text('Instagram'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Change'), findsOneWidget);

    // Tap Start Temporary Pause button
    final startButton = find.byKey(const Key('start_pause_button'));
    await tester.tap(startButton);
    await tester.pump();

    expect(createdApp?.packageName, equals('com.instagram.android'));
    expect(createdDuration, equals(PauseDurationPreset.fifteenMinutes.duration));
  });
}
