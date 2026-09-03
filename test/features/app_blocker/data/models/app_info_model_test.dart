import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:net_guard/features/app_blocker/data/models/app_info_model.dart';
import 'package:net_guard/features/app_blocker/domain/entities/app_info_entity.dart';

void main() {
  test('serializes and deserializes app information', () {
    final model = AppInfoModel(
      appName: 'Mail',
      packageName: 'com.example.mail',
      isBlocked: true,
      iconBytes: Uint8List.fromList([1, 2]),
      iconPath: '/icons/mail.png',
    );

    final restored = AppInfoModel.fromMap(model.toMap());

    expect(restored.appName, model.appName);
    expect(restored.packageName, model.packageName);
    expect(restored.isBlocked, isTrue);
    expect(restored.iconBytes, Uint8List.fromList([1, 2]));
    expect(restored.iconPath, model.iconPath);
  });

  test('maps an entity to and from a model', () {
    const entity = AppInfoEntity(
      appName: 'Mail',
      packageName: 'mail',
      isBlocked: false,
    );

    final model = AppInfoModel.fromEntity(entity);

    expect(model.toEntity(), entity);
  });
}
