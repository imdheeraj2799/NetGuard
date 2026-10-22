import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:net_guard/features/app_blocker/domain/entities/block_schedule_entity.dart';
import 'package:net_guard/features/app_blocker/presentation/widgets/schedule_card.dart';

void main() {
  final fixedDate = DateTime(2026, 10, 21, 10, 0);

  final testSchedule = BlockScheduleEntity(
    id: 's-1',
    name: 'Night Sleep',
    packageNames: const ['com.game.app', 'com.video.app'],
    recurrence: ScheduleRecurrence.daily,
    startHour: 23,
    startMinute: 0,
    endHour: 7,
    endMinute: 30,
    isEnabled: true,
    createdAt: fixedDate,
    updatedAt: fixedDate,
  );

  testWidgets('renders schedule details, overnight badge, and triggers callbacks', (tester) async {
    var toggledValue = false;
    var editCalled = false;
    var deleteCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleCard(
            schedule: testSchedule,
            isActiveNow: true,
            onToggle: (val) => toggledValue = val,
            onEdit: () => editCalled = true,
            onDelete: () => deleteCalled = true,
          ),
        ),
      ),
    );

    // Verify Title and Recurrence
    expect(find.text('Night Sleep'), findsOneWidget);
    expect(find.text('Every Day'), findsOneWidget);
    expect(find.text('Active Now'), findsOneWidget);

    // Verify formatted time and overnight indicator
    expect(find.text('11:00 PM – 7:30 AM'), findsOneWidget);
    expect(find.text('🌙 Overnight'), findsOneWidget);
    expect(find.text('2 Apps Blocked'), findsOneWidget);

    // Toggle switch
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    await tester.tap(switchFinder);
    await tester.pump();
    expect(toggledValue, isFalse);

    // Tap edit
    final editButton = find.byIcon(Icons.edit_outlined);
    await tester.tap(editButton);
    await tester.pump();
    expect(editCalled, isTrue);

    // Tap delete
    final deleteButton = find.byIcon(Icons.delete_outline_rounded);
    await tester.tap(deleteButton);
    await tester.pump();
    expect(deleteCalled, isTrue);
  });
}
