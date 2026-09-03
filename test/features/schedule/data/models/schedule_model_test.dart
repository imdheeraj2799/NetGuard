import 'package:flutter_test/flutter_test.dart';
import 'package:net_guard/features/schedule/data/models/schedule_model.dart';
import 'package:net_guard/features/schedule/domain/entities/schedule_entity.dart';

void main() {
  const testModel = ScheduleModel(
    id: 's_1',
    name: 'Night Restrictions',
    startTimeMinutes: 1320,
    endTimeMinutes: 420,
    activeDays: [1, 2, 3, 4, 5],
    targetPackages: ['com.instagram.android'],
    isEnabled: true,
  );

  final testJson = {
    'id': 's_1',
    'name': 'Night Restrictions',
    'startTimeMinutes': 1320,
    'endTimeMinutes': 420,
    'activeDays': [1, 2, 3, 4, 5],
    'targetPackages': ['com.instagram.android'],
    'isEnabled': true,
  };

  test('ScheduleModel serializes to JSON correctly', () {
    final result = testModel.toJson();
    expect(result, testJson);
  });

  test('ScheduleModel deserializes from JSON correctly', () {
    final result = ScheduleModel.fromJson(testJson);
    expect(result.id, 's_1');
    expect(result.name, 'Night Restrictions');
    expect(result.startTimeMinutes, 1320);
    expect(result.endTimeMinutes, 420);
    expect(result.activeDays, [1, 2, 3, 4, 5]);
    expect(result.targetPackages, ['com.instagram.android']);
    expect(result.isEnabled, isTrue);
  });

  test('converts to and from ScheduleEntity', () {
    const entity = ScheduleEntity(
      id: 's_2',
      name: 'Work',
      startTimeMinutes: 540,
      endTimeMinutes: 1020,
      activeDays: [1, 2, 3, 4, 5],
      targetPackages: ['com.discord'],
      isEnabled: true,
    );

    final model = ScheduleModel.fromEntity(entity);
    expect(model.id, entity.id);
    expect(model.toEntity(), entity);
  });
}
