import 'package:flutter_test/flutter_test.dart';
import 'package:ivgo/domain/infusion_characteristics.dart';
import 'package:ivgo/domain/infusion_timer.dart';
import 'package:ivgo/domain/infusion_timer_status.dart';
import 'package:ivgo/repositories/infusion_timer_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('InfusionTimerRepository', () {
    late InfusionTimerRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = InfusionTimerRepository();
    });

    test('returns an empty list when nothing is stored', () async {
      final List<InfusionTimer> timers = await repository.loadTimers();

      expect(timers, isEmpty);
    });

    test('returns an empty list when shared preferences loading fails', () async {
      repository = InfusionTimerRepository(
        sharedPreferencesFactory: () async {
          throw Exception('Shared preferences unavailable');
        },
      );

      final List<InfusionTimer> timers = await repository.loadTimers();

      expect(timers, isEmpty);
    });

    test('returns an empty list when stored timer JSON is invalid', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'infusionTimers': <String>['not valid json'],
      });
      repository = InfusionTimerRepository();

      final List<InfusionTimer> timers = await repository.loadTimers();

      expect(timers, isEmpty);
    });

    test('saves and restores timers through shared preferences', () async {
      final InfusionTimer timer = InfusionTimer(
        1,
        'Saline',
        InfusionCharacteristics(volume: 6, dropFactor: 20, flowRate: 60),
      );

      timer.start();
      timer.stop();

      await repository.saveTimers(<InfusionTimer>[timer]);
      final List<InfusionTimer> restoredTimers = await repository.loadTimers();

      expect(restoredTimers, hasLength(1));
      expect(restoredTimers.single.title, 'Saline');
      expect(restoredTimers.single.characteristics.volume, 6);
      expect(restoredTimers.single.status, InfusionTimerStatus.paused);
    });
  });
}
