import 'package:flutter_test/flutter_test.dart';
import 'package:net_guard/features/app_blocker/data/models/block_schedule_model.dart';
import 'package:net_guard/features/app_blocker/domain/entities/block_schedule_entity.dart';

void main() {
  final fixedDate = DateTime(2026, 10, 21, 10, 0);

  final testEntity = BlockScheduleEntity(
    id: 'test-123',
    name: 'Evening Chill',
    packageNames: const ['com.instagram.android', 'com.tiktok'],
    recurrence: ScheduleRecurrence.customDays,
    customDaysOfWeek: const [1, 3, 5],
    targetDate: null,
    startHour: 20,
    startMinute: 30,
    endHour: 23,
    endMinute: 45,
    isEnabled: true,
    createdAt: fixedDate,
    updatedAt: fixedDate,
  );

  group('BlockScheduleModel', () {
    test('fromEntity converts entity to model correctly', () {
      final model = BlockScheduleModel.fromEntity(testEntity);

      expect(model.id, 'test-123');
      expect(model.name, 'Evening Chill');
      expect(model.packageNames, ['com.instagram.android', 'com.tiktok']);
      expect(model.recurrence, ScheduleRecurrence.customDays);
      expect(model.customDaysOfWeek, [1, 3, 5]);
      expect(model.startHour, 20);
      expect(model.startMinute, 30);
      expect(model.endHour, 23);
      expect(model.endMinute, 45);
      expect(model.isEnabled, isTrue);
      expect(model.createdAt, fixedDate);
      expect(model.updatedAt, fixedDate);
    });

    test('toMap converts model to Map with serializable primitives', () {
      final model = BlockScheduleModel.fromEntity(testEntity);
      final map = model.toMap();

      expect(map['id'], 'test-123');
      expect(map['name'], 'Evening Chill');
      expect(map['packageNames'], ['com.instagram.android', 'com.tiktok']);
      expect(map['recurrence'], 'customDays');
      expect(map['customDaysOfWeek'], [1, 3, 5]);
      expect(map['targetDate'], isNull);
      expect(map['startHour'], 20);
      expect(map['startMinute'], 30);
      expect(map['endHour'], 23);
      expect(map['endMinute'], 45);
      expect(map['isEnabled'], isTrue);
      expect(map['createdAt'], fixedDate.toIso8601String());
      expect(map['updatedAt'], fixedDate.toIso8601String());
    });

    test('fromMap restores model correctly with all fields and oneTime date', () {
      final targetDate = DateTime(2026, 12, 25);
      final map = {
        'id': 'holiday-1',
        'name': 'Christmas',
        'packageNames': ['com.slack'],
        'recurrence': 'oneTime',
        'customDaysOfWeek': <int>[],
        'targetDate': targetDate.toIso8601String(),
        'startHour': 9,
        'startMinute': 0,
        'endHour': 17,
        'endMinute': 0,
        'isEnabled': false,
        'createdAt': fixedDate.toIso8601String(),
        'updatedAt': fixedDate.toIso8601String(),
      };

      final model = BlockScheduleModel.fromMap(map);

      expect(model.id, 'holiday-1');
      expect(model.name, 'Christmas');
      expect(model.packageNames, ['com.slack']);
      expect(model.recurrence, ScheduleRecurrence.oneTime);
      expect(model.targetDate, targetDate);
      expect(model.startHour, 9);
      expect(model.endHour, 17);
      expect(model.isEnabled, isFalse);
    });

    test('fromMap provides safe fallbacks when optional/numeric fields are missing or dynamic', () {
      final minimalMap = <dynamic, dynamic>{
        'id': 'min-1',
      };

      final model = BlockScheduleModel.fromMap(minimalMap);

      expect(model.id, 'min-1');
      expect(model.name, '');
      expect(model.packageNames, isEmpty);
      expect(model.recurrence, ScheduleRecurrence.daily);
      expect(model.customDaysOfWeek, isEmpty);
      expect(model.targetDate, isNull);
      expect(model.startHour, 0);
      expect(model.startMinute, 0);
      expect(model.endHour, 0);
      expect(model.endMinute, 0);
      expect(model.isEnabled, isTrue);
      expect(model.createdAt, isNotNull);
      expect(model.updatedAt, isNotNull);
    });

    test('toEntity returns equal BlockScheduleEntity', () {
      final model = BlockScheduleModel.fromEntity(testEntity);
      final entity = model.toEntity();

      expect(entity, testEntity);
    });
  });
}
