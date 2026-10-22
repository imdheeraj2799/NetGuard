import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:net_guard/features/app_blocker/domain/entities/app_info_entity.dart';
import 'package:net_guard/features/app_blocker/presentation/widgets/schedule_app_picker_dialog.dart';

void main() {
  const testApps = [
    AppInfoEntity(
      appName: 'Browser',
      packageName: 'com.browser.app',
      isBlocked: false,
    ),
    AppInfoEntity(
      appName: 'Messenger',
      packageName: 'com.msg.app',
      isBlocked: false,
    ),
    AppInfoEntity(
      appName: 'Notes',
      packageName: 'com.notes.app',
      isBlocked: false,
    ),
  ];

  testWidgets(
    'ScheduleAppPickerDialog marks assigned app as Restricted and shows warning when tapped',
    (tester) async {
      Set<String>? confirmedPackages;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final result = await ScheduleAppPickerDialog.show(
                    context: context,
                    allApps: testApps,
                    initialSelectedPackages: {'com.browser.app'},
                    assignedPackages: {'com.msg.app': 'Existing Sched'},
                  );
                  confirmedPackages = result;
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Verify Title and initial selected count
      expect(find.text('Select Applications'), findsOneWidget);
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('Browser'), findsOneWidget);
      expect(find.text('Messenger'), findsOneWidget);

      // Verify Restricted badge and schedule info on Messenger
      expect(find.text('Restricted'), findsOneWidget);
      expect(find.text('In schedule: "Existing Sched"'), findsOneWidget);

      // Tap the restricted app (Messenger)
      await tester.tap(find.text('Messenger'));
      await tester.pump();

      // Verify the warning message appears
      expect(find.text('This application is already restricted'), findsOneWidget);

      // Selection count should still be 1 (Messenger was not selected)
      expect(find.text('1 selected'), findsOneWidget);

      // Select Notes (unassigned app)
      await tester.tap(find.text('Notes'));
      await tester.pump();

      expect(find.text('2 selected'), findsOneWidget);

      // Tap confirm button
      await tester.tap(find.text('Confirm Selection (2)'));
      await tester.pumpAndSettle();

      expect(confirmedPackages, isNotNull);
      expect(confirmedPackages, containsAll(['com.browser.app', 'com.notes.app']));
      expect(confirmedPackages, isNot(contains('com.msg.app')));
    },
  );

  testWidgets(
    'ScheduleAppPickerDialog allows apps assigned to current schedule to remain selectable',
    (tester) async {
      Set<String>? confirmedPackages;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final result = await ScheduleAppPickerDialog.show(
                    context: context,
                    allApps: testApps,
                    initialSelectedPackages: {'com.msg.app'},
                    assignedPackages: {'com.msg.app': 'This Sched'},
                  );
                  confirmedPackages = result;
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Messenger is part of current schedule, so it should NOT be restricted
      expect(find.text('Restricted'), findsNothing);
      expect(find.text('1 selected'), findsOneWidget);

      // Deselect Messenger
      await tester.tap(find.text('Messenger'));
      await tester.pump();

      expect(find.text('0 selected'), findsOneWidget);

      await tester.tap(find.text('Confirm Selection (0)'));
      await tester.pumpAndSettle();

      expect(confirmedPackages, isEmpty);
    },
  );
}
