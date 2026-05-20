import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ivgo/domain/infusion_characteristics.dart';
import 'package:ivgo/domain/infusion_notification_milestone.dart';
import 'package:ivgo/domain/infusion_notification_trigger.dart';
import 'package:ivgo/domain/infusion_timer.dart';
import 'package:ivgo/domain/infusion_timer_status.dart';

void main() {
  group('InfusionTimer', () {
    late DateTime now;

    InfusionTimer createTimer({
      required double volume,
      double dropFactor = 20,
      double flowRate = 60,
    }) {
      return InfusionTimer(
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

    InfusionNotificationMilestone createMilestone({
      required String key,
      required Duration offset,
      required InfusionNotificationTrigger trigger,
    }) {
      return InfusionNotificationMilestone(
        key: key,
        title: key,
        body: '',
        offset: offset,
        trigger: trigger,
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

    test('completed timers show the full target volume after a paused rate change', () {
      final timer = createTimer(volume: 10);

      timer.start();
      now = now.add(const Duration(seconds: 99));
      timer.reconcile();
      timer.stop();

      timer.changeCharacteristics(
        InfusionCharacteristics(volume: 10, dropFactor: 20, flowRate: 80),
      );
      timer.start();

      now = now.add(const Duration(seconds: 76));
      timer.reconcile();

      expect(timer.isEnded, isTrue);
      expect(timer.remainingSeconds, Duration.zero);
      expect(timer.infusedVolume, closeTo(10, 0.0001));
    });

    test('reset clears progress and keeps the latest edited configuration', () {
      final timer = createTimer(volume: 10);

      timer.start();
      now = now.add(const Duration(seconds: 40));
      timer.reconcile();
      timer.stop();
      timer.changeCharacteristics(
        InfusionCharacteristics(volume: 10, dropFactor: 20, flowRate: 120),
      );

      timer.reset();

      expect(timer.isPaused, isTrue);
      expect(timer.infusedVolume, 0);
      expect(timer.remainingSeconds.inSeconds, 100);
      expect(timer.characteristics.volume, 10);
      expect(timer.characteristics.dropFactor, 20);
      expect(timer.characteristics.flowRate, 120);
    });

    test('reset clears progress for completed timers and keeps edited settings', () {
      final timer = createTimer(volume: 10);

      timer.start();
      now = now.add(const Duration(seconds: 220));
      timer.reconcile();

      expect(timer.isEnded, isTrue);

      timer.changeCharacteristics(
        InfusionCharacteristics(volume: 10, dropFactor: 20, flowRate: 120),
      );

      timer.reset();

      expect(timer.isPaused, isTrue);
      expect(timer.isEnded, isFalse);
      expect(timer.infusedVolume, 0);
      expect(timer.remainingSeconds.inSeconds, 100);
      expect(timer.characteristics.volume, 10);
      expect(timer.characteristics.dropFactor, 20);
      expect(timer.characteristics.flowRate, 120);
    });

    test('re-configuring a paused timer preserves progress without elapsed-time drift', () {
      final timer = createTimer(volume: 10);

      timer.start();
      now = now.add(const Duration(seconds: 40));
      timer.reconcile();

      expect(timer.infusedVolume, closeTo(2, 0.0001));
      expect(timer.remainingSeconds.inSeconds, 160);

      timer.stop();
      expect(timer.isPaused, isTrue);
      final infusedAtPause = timer.infusedVolume;

      now = now.add(const Duration(seconds: 60));
      timer.reconcile();

      expect(timer.infusedVolume, infusedAtPause);

      timer.changeCharacteristics(
        InfusionCharacteristics(volume: 8, dropFactor: 20, flowRate: 120),
      );

      expect(timer.isPaused, isTrue);
      expect(timer.infusedVolume, infusedAtPause);

      now = now.add(const Duration(seconds: 120));
      timer.reconcile();

      expect(timer.infusedVolume, infusedAtPause);
      expect(timer.remainingSeconds.inSeconds, 60);
    });

    test('running timers restore elapsed real time from persisted state', () {
      final timer = createTimer(volume: 6);

      timer.start();
      now = now.add(const Duration(seconds: 30));
      final encoded = jsonEncode(timer.toJson());

      now = now.add(const Duration(seconds: 60));
      final restored = InfusionTimer.fromJson(
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
      final restored = InfusionTimer.fromJson(
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
      final restored = InfusionTimer.fromJson(
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
      final restored = InfusionTimer.fromJson(
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

    test('handled milestones survive JSON restore and do not re-fire in the same lifecycle', () {
      final timer = createTimer(volume: 6);
      final milestone = createMilestone(
        key: 'one_minute_remaining',
        offset: const Duration(minutes: 1),
        trigger: InfusionNotificationTrigger.beforeEnd,
      );

      timer.start();
      now = now.add(const Duration(seconds: 61));

      expect(timer.dueNotificationMilestones(milestones: <InfusionNotificationMilestone>[milestone], now: now), [milestone]);

      timer.markMilestoneHandled(milestone);

      expect(timer.dueNotificationMilestones(milestones: <InfusionNotificationMilestone>[milestone], now: now), isEmpty);

      final encoded = jsonEncode(timer.toJson());
      final restored = InfusionTimer.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
        nowProvider: () => now,
      );

      expect(restored.dueNotificationMilestones(milestones: <InfusionNotificationMilestone>[milestone], now: now), isEmpty);
    });

    test('before-end milestones are not due for infusions that never exceed the milestone offset', () {
      final oneMinuteMilestone = createMilestone(
        key: 'one_minute_remaining',
        offset: const Duration(minutes: 1),
        trigger: InfusionNotificationTrigger.beforeEnd,
      );
      final tenMinuteMilestone = createMilestone(
        key: 'ten_minutes_remaining',
        offset: const Duration(minutes: 10),
        trigger: InfusionNotificationTrigger.beforeEnd,
      );
      final twoMinuteTimer = createTimer(volume: 6);
      final tenSecondTimer = createTimer(volume: 0.5);

      twoMinuteTimer.start();
      tenSecondTimer.start();

      expect(
        twoMinuteTimer.dueNotificationMilestones(
          milestones: <InfusionNotificationMilestone>[tenMinuteMilestone],
          now: now,
        ),
        isEmpty,
      );
      expect(
        tenSecondTimer.dueNotificationMilestones(
          milestones: <InfusionNotificationMilestone>[oneMinuteMilestone],
          now: now,
        ),
        isEmpty,
      );
    });

    test('acknowledged recovered overdue timers keep after-end suppression after JSON restore', () {
      final timer = createTimer(volume: 6);
      final milestone = createMilestone(
        key: 'ended_plus_ten_minutes',
        offset: const Duration(minutes: 10),
        trigger: InfusionNotificationTrigger.afterEnd,
      );

      timer.start();
      now = now.add(const Duration(seconds: 30));
      final encodedRunning = jsonEncode(timer.toJson());

      now = now.add(const Duration(minutes: 5));
      final recovered = InfusionTimer.fromJson(
        jsonDecode(encodedRunning) as Map<String, dynamic>,
        nowProvider: () => now,
      );
      recovered.onRestore();
      recovered.acknowledgeRecoveredOverdue();

      final encodedAcknowledged = jsonEncode(recovered.toJson());

      now = now.add(const Duration(minutes: 15));
      final restored = InfusionTimer.fromJson(
        jsonDecode(encodedAcknowledged) as Map<String, dynamic>,
        nowProvider: () => now,
      );

      expect(restored.status, InfusionTimerStatus.ended);
      expect(restored.isRecoveredOverdue, isFalse);
      expect(restored.suppressAfterEndMilestones, isTrue);
      expect(restored.dueNotificationMilestones(milestones: <InfusionNotificationMilestone>[milestone], now: now), isEmpty);
    });

    test('serializes to valid JSON', () {
      final timer = createTimer(volume: 6);

      timer.start();
      now = now.add(const Duration(seconds: 15));

      expect(() => jsonEncode(timer.toJson()), returnsNormally);
    });

    group('infusion duration and infused-volume calculations', () {
      test('duration calculation: 100ml at 20gtts/ml and 60gtts/min equals 2000 seconds', () {
        final timer = createTimer(volume: 100);
        expect(timer.durationInSeconds.inSeconds, 2000);
      });

      test('duration calculation: 50ml at 20gtts/ml and 100gtts/min equals 600 seconds', () {
        final timer = createTimer(volume: 50, flowRate: 100);
        expect(timer.durationInSeconds.inSeconds, 600);
      });

      test('duration calculation: 10ml at 15gtts/ml and 45gtts/min equals 200 seconds', () {
        final timer = createTimer(volume: 10, dropFactor: 15, flowRate: 45);
        expect(timer.durationInSeconds.inSeconds, 200);
      });

      test('duration calculation: zero volume equals zero duration', () {
        final timer = createTimer(volume: 0);
        expect(timer.durationInSeconds, Duration.zero);
      });

      test('infused volume calculation: 60 seconds at 60gtts/min and 20gtts/ml equals 3ml', () {
        final timer = createTimer(volume: 100, flowRate: 60, dropFactor: 20);
        timer.start();
        now = now.add(const Duration(seconds: 60));
        timer.reconcile();
        expect(timer.infusedVolume, closeTo(3, 0.0001));
      });

      test('infused volume calculation: 120 seconds at 120gtts/min and 20gtts/ml equals 12ml', () {
        final timer = createTimer(volume: 100, flowRate: 120, dropFactor: 20);
        timer.start();
        now = now.add(const Duration(seconds: 120));
        timer.reconcile();
        expect(timer.infusedVolume, closeTo(12, 0.0001));
      });

      test('infused volume calculation: 180 seconds at 45gtts/min and 15gtts/ml equals 9ml', () {
        final timer = createTimer(volume: 100, flowRate: 45, dropFactor: 15);
        timer.start();
        now = now.add(const Duration(seconds: 180));
        timer.reconcile();
        expect(timer.infusedVolume, closeTo(9, 0.0001));
      });

      test('remaining seconds calculation: after 50 seconds of a 200 second infusion, 150 seconds remain', () {
        final timer = createTimer(volume: 100);
        timer.start();
        now = now.add(const Duration(seconds: 50));
        timer.reconcile();
        expect(timer.remainingSeconds.inSeconds, 1950);
      });

      test('volume and duration are inversely correct: doubling flow rate halves duration', () {
        final slowTimer = createTimer(volume: 60, flowRate: 60);
        final fastTimer = createTimer(volume: 60, flowRate: 120);
        expect(fastTimer.durationInSeconds.inSeconds, slowTimer.durationInSeconds.inSeconds ~/ 2);
      });

      test('volume and duration are inversely correct: doubling drop factor doubles duration', () {
        final smallDrops = createTimer(volume: 60, dropFactor: 20, flowRate: 60);
        final largeDrops = createTimer(volume: 60, dropFactor: 40, flowRate: 60);
        expect(largeDrops.durationInSeconds.inSeconds, smallDrops.durationInSeconds.inSeconds * 2);
      });

      test('infused volume caps at target volume when duration exceeds total infusion time', () {
        final timer = createTimer(volume: 6);
        timer.start();
        now = now.add(const Duration(minutes: 5));
        timer.reconcile();
        expect(timer.infusedVolume, closeTo(6, 0.0001));
        expect(timer.isEnded, isTrue);
      });
    });
  });
}
