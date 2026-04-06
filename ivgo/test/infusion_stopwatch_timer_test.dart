import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ivgo/models/infusion_characteristics.dart';
import 'package:ivgo/utils/infusion_stopwatch_timer.dart';

void main() {
  group('InfusionStopwatchTimer', () {
    late DateTime now;

    InfusionStopwatchTimer createTimer({
      required double volume,
      double dropFactor = 20,
      double flowRate = 60,
    }) {
      return InfusionStopwatchTimer(
        1,
        'Infusion',
        InfusionCharacteristics(
          volume: volume,
          dropFactor: dropFactor,
          flowRate: flowRate,
        ),
        nowProvider: () => now,
      );
    }

    setUp(() {
      now = DateTime.utc(2026, 4, 6, 12);
    });

    test('pause and resume preserve progress until completion', () {
      final timer = createTimer(volume: 6);

      timer.start();
      now = now.add(const Duration(seconds: 30));
      timer.reconcile();

      expect(timer.infusedVolume, closeTo(1.5, 0.0001));
      expect(timer.remainingSeconds.inSeconds, 90);

      timer.stop();
      now = now.add(const Duration(seconds: 60));
      timer.reconcile();

      expect(timer.isPaused, isTrue);
      expect(timer.infusedVolume, closeTo(1.5, 0.0001));
      expect(timer.remainingSeconds.inSeconds, 90);

      timer.start();
      now = now.add(const Duration(seconds: 90));
      timer.reconcile();

      expect(timer.isEnded, isTrue);
      expect(timer.isRunning, isFalse);
      expect(timer.infusedVolume, closeTo(6, 0.0001));
      expect(timer.remainingSeconds, Duration.zero);
    });

    test('changing characteristics preserves infused volume and updates remaining time', () {
      final timer = createTimer(volume: 10);

      timer.start();
      now = now.add(const Duration(seconds: 40));
      timer.reconcile();
      timer.changeCharacteristics(
        InfusionCharacteristics(volume: 10, dropFactor: 20, flowRate: 120),
      );

      expect(timer.isRunning, isTrue);
      expect(timer.infusedVolume, closeTo(2, 0.0001));
      expect(timer.remainingSeconds.inSeconds, 80);

      now = now.add(const Duration(seconds: 10));
      timer.reconcile();

      expect(timer.infusedVolume, closeTo(3, 0.0001));
      expect(timer.remainingSeconds.inSeconds, 70);
    });

    test('reset clears progress and restores the initial configuration', () {
      final timer = createTimer(volume: 10);

      timer.start();
      now = now.add(const Duration(seconds: 40));
      timer.reconcile();
      timer.changeCharacteristics(
        InfusionCharacteristics(volume: 10, dropFactor: 20, flowRate: 120),
      );

      timer.reset();

      expect(timer.isPaused, isTrue);
      expect(timer.infusedVolume, 0);
      expect(timer.remainingSeconds.inSeconds, 200);
      expect(timer.characteristics.volume, 10);
      expect(timer.characteristics.dropFactor, 20);
      expect(timer.characteristics.flowRate, 60);
    });

    test('running timers restore elapsed real time from persisted state', () {
      final timer = createTimer(volume: 6);

      timer.start();
      now = now.add(const Duration(seconds: 30));
      final encoded = jsonEncode(timer.toJson());

      now = now.add(const Duration(seconds: 60));
      final restored = InfusionStopwatchTimer.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
        nowProvider: () => now,
      );
      restored.onRestore();

      expect(restored.isRunning, isTrue);
      expect(restored.infusedVolume, closeTo(4.5, 0.0001));
      expect(restored.remainingSeconds.inSeconds, 30);
    });

    test('paused timers restore without auto-resuming', () {
      final timer = createTimer(volume: 6);

      timer.start();
      now = now.add(const Duration(seconds: 30));
      timer.stop();
      final encoded = jsonEncode(timer.toJson());

      now = now.add(const Duration(seconds: 90));
      final restored = InfusionStopwatchTimer.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
        nowProvider: () => now,
      );
      restored.onRestore();

      expect(restored.isPaused, isTrue);
      expect(restored.isRunning, isFalse);
      expect(restored.infusedVolume, closeTo(1.5, 0.0001));
      expect(restored.remainingSeconds.inSeconds, 90);
    });

    test('timers that complete during restore are marked recovered overdue', () {
      final timer = createTimer(volume: 6);

      timer.start();
      now = now.add(const Duration(seconds: 30));
      final encoded = jsonEncode(timer.toJson());

      now = now.add(const Duration(minutes: 5));
      final restored = InfusionStopwatchTimer.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
        nowProvider: () => now,
      );
      restored.onRestore();

      expect(restored.isRecoveredOverdue, isTrue);
      expect(restored.isEnded, isTrue);
      expect(restored.isRunning, isFalse);
      expect(restored.remainingSeconds, Duration.zero);
      expect(restored.infusedVolume, closeTo(6, 0.0001));
    });

    test('acknowledging a recovered overdue timer clears only the warning state', () {
      final timer = createTimer(volume: 6);

      timer.start();
      now = now.add(const Duration(seconds: 30));
      final encoded = jsonEncode(timer.toJson());

      now = now.add(const Duration(minutes: 5));
      final restored = InfusionStopwatchTimer.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
        nowProvider: () => now,
      );
      restored.onRestore();
      restored.acknowledgeRecoveredOverdue();

      expect(restored.isRecoveredOverdue, isFalse);
      expect(restored.status, InfusionTimerStatus.ended);
      expect(restored.isEnded, isTrue);
      expect(restored.remainingSeconds, Duration.zero);
      expect(restored.infusedVolume, closeTo(6, 0.0001));
    });

    test('serializes to valid JSON', () {
      final timer = createTimer(volume: 6);

      timer.start();
      now = now.add(const Duration(seconds: 15));

      expect(() => jsonEncode(timer.toJson()), returnsNormally);
    });
  });
}
