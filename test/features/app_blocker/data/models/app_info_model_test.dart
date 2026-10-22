import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:net_guard/features/app_blocker/data/models/app_info_model.dart';
import 'package:net_guard/features/app_blocker/domain/entities/app_info_entity.dart';

void main() {
  test('serializes and deserializes app information including schedule restrictions', () {
    final model = AppInfoModel(
      appName: 'Mail',
      packageName: 'com.example.mail',
      isBlocked: true,
      iconBytes: Uint8List.fromList([1, 2]),
      iconPath: '/icons/mail.png',
      isSchedulePart: true,
      whichSchedule: 'Night Restrict',
    );

    final restored = AppInfoModel.fromMap(model.toMap());

    expect(restored.appName, model.appName);
    expect(restored.packageName, model.packageName);
    expect(restored.isBlocked, isTrue);
    expect(restored.iconBytes, Uint8List.fromList([1, 2]));
    expect(restored.iconPath, model.iconPath);
    expect(restored.isSchedulePart, isTrue);
    expect(restored.whichSchedule, 'Night Restrict');
  });

  test('maps an entity with schedule restrictions to and from a model', () {
    const entity = AppInfoEntity(
      appName: 'Mail',
      packageName: 'mail',
      isBlocked: false,
      isSchedulePart: true,
      whichSchedule: 'Study Schedule',
    );

    final model = AppInfoModel.fromEntity(entity);

    expect(model.isSchedulePart, isTrue);
    expect(model.whichSchedule, 'Study Schedule');
    expect(model.toEntity(), entity);
  });

  test('copyWith supports modifying and clearing schedule restrictions', () {
    final model = AppInfoModel(
      appName: 'Mail',
      packageName: 'com.example.mail',
      isBlocked: false,
      isSchedulePart: true,
      whichSchedule: 'Work Schedule',
    );

    final updated = model.copyWith(
      isSchedulePart: false,
      clearWhichSchedule: true,
    );

    expect(updated.isSchedulePart, isFalse);
    expect(updated.whichSchedule, isNull);
  });
}
