import 'package:flutter_test/flutter_test.dart';
import 'package:net_guard/features/temporary_internet_pause/data/models/temporary_pause_model.dart';
import 'package:net_guard/features/temporary_internet_pause/domain/entities/temporary_pause_entity.dart';

void main() {
  group('TemporaryPauseModel', () {
    final startTime = DateTime(2026, 10, 23, 12, 0);
    final pauseUntil = DateTime(2026, 10, 23, 12, 45);

    final model = TemporaryPauseModel(
      id: 'p-1',
      packageName: 'com.chat.app',
      appName: 'Chat App',
      startTime: startTime,
      pauseUntil: pauseUntil,
      durationMillis: 45 * 60 * 1000,
      isCustom: true,
    );

    test('toEntity converts correctly', () {
      final entity = model.toEntity();
      expect(entity.id, 'p-1');
      expect(entity.packageName, 'com.chat.app');
      expect(entity.appName, 'Chat App');
      expect(entity.startTime, startTime);
      expect(entity.pauseUntil, pauseUntil);
      expect(entity.duration, const Duration(minutes: 45));
      expect(entity.isCustom, isTrue);
    });

    test('fromEntity converts correctly', () {
      final entity = TemporaryPauseEntity(
        id: 'p-2',
        packageName: 'com.game.app',
        appName: 'Game',
        startTime: startTime,
        pauseUntil: pauseUntil,
        duration: const Duration(minutes: 45),
        isCustom: false,
      );
      final from = TemporaryPauseModel.fromEntity(entity);
      expect(from.id, 'p-2');
      expect(from.packageName, 'com.game.app');
      expect(from.appName, 'Game');
      expect(from.durationMillis, 45 * 60 * 1000);
      expect(from.isCustom, isFalse);
    });

    test('toMap and fromMap serialize and deserialize accurately', () {
      final map = model.toMap();
      expect(map['id'], 'p-1');
      expect(map['packageName'], 'com.chat.app');
      expect(map['pauseUntilMillis'], pauseUntil.millisecondsSinceEpoch);

      final from = TemporaryPauseModel.fromMap(map);
      expect(from.id, model.id);
      expect(from.packageName, model.packageName);
      expect(from.durationMillis, model.durationMillis);
      expect(from.isCustom, model.isCustom);
    });

    test('toJson and fromJson serialize and deserialize accurately', () {
      final json = model.toJson();
      final from = TemporaryPauseModel.fromJson(json);
      expect(from.id, model.id);
      expect(from.packageName, model.packageName);
    });

    test('isExpired works correctly', () {
      expect(model.isExpired(DateTime(2026, 10, 23, 12, 30)), isFalse);
      expect(model.isExpired(DateTime(2026, 10, 23, 12, 45)), isTrue);
    });
  });
}
