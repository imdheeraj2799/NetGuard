import 'package:flutter_test/flutter_test.dart';
import 'package:net_guard/features/temporary_internet_pause/domain/entities/pause_duration_preset.dart';
import 'package:net_guard/features/temporary_internet_pause/domain/entities/temporary_pause_entity.dart';

void main() {
  group('TemporaryPauseEntity', () {
    final now = DateTime(2026, 10, 23, 12, 0);
    final pauseUntil = DateTime(2026, 10, 23, 12, 30);
    final pause = TemporaryPauseEntity(
      id: 'pause-1',
      packageName: 'com.example.app',
      appName: 'Example App',
      startTime: now,
      pauseUntil: pauseUntil,
      duration: const Duration(minutes: 30),
      isCustom: false,
    );

    test('isExpired returns false before pauseUntil and true after', () {
      expect(pause.isExpired(DateTime(2026, 10, 23, 12, 15)), isFalse);
      expect(pause.isExpired(DateTime(2026, 10, 23, 12, 30)), isTrue);
      expect(pause.isExpired(DateTime(2026, 10, 23, 12, 31)), isTrue);
    });

    test('remainingTime returns correct difference and clamps to zero', () {
      expect(
        pause.remainingTime(DateTime(2026, 10, 23, 12, 10)),
        const Duration(minutes: 20),
      );
      expect(
        pause.remainingTime(DateTime(2026, 10, 23, 12, 35)),
        Duration.zero,
      );
    });

    test('progressFraction calculates elapsed fraction accurately', () {
      expect(
        pause.progressFraction(DateTime(2026, 10, 23, 12, 0)),
        closeTo(0.0, 0.01),
      );
      expect(
        pause.progressFraction(DateTime(2026, 10, 23, 12, 15)),
        closeTo(0.5, 0.01),
      );
      expect(
        pause.progressFraction(DateTime(2026, 10, 23, 12, 30)),
        closeTo(1.0, 0.01),
      );
      expect(
        pause.progressFraction(DateTime(2026, 10, 23, 12, 45)),
        closeTo(1.0, 0.01),
      );
    });

    test('copyWith creates copy with updated fields', () {
      final updated = pause.copyWith(appName: 'Updated App', isCustom: true);
      expect(updated.appName, 'Updated App');
      expect(updated.isCustom, isTrue);
      expect(updated.packageName, 'com.example.app');
    });

    test('equality and hashCode work as expected', () {
      final same = TemporaryPauseEntity(
        id: 'pause-1',
        packageName: 'com.example.app',
        appName: 'Example App',
        startTime: now,
        pauseUntil: pauseUntil,
        duration: const Duration(minutes: 30),
        isCustom: false,
      );
      expect(pause, equals(same));
      expect(pause.hashCode, equals(same.hashCode));
    });
  });

  group('PauseDurationPreset', () {
    test('values and labels are correct', () {
      expect(PauseDurationPreset.fifteenMinutes.duration, const Duration(minutes: 15));
      expect(PauseDurationPreset.thirtyMinutes.duration, const Duration(minutes: 30));
      expect(PauseDurationPreset.oneHour.duration, const Duration(hours: 1));
      expect(PauseDurationPreset.twoHours.duration, const Duration(hours: 2));
      expect(PauseDurationPreset.custom.isCustom, isTrue);
    });
  });
}
