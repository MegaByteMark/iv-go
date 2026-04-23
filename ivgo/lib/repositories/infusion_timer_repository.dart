import 'dart:convert';

import 'package:ivgo/domain/infusion_timer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InfusionTimerRepository {
  InfusionTimerRepository({
    Future<SharedPreferences> Function()? sharedPreferencesFactory,
  }) : _sharedPreferencesFactory = sharedPreferencesFactory ?? SharedPreferences.getInstance;

  static const String _storageKey = 'infusionTimers';

  final Future<SharedPreferences> Function() _sharedPreferencesFactory;

  Future<List<InfusionTimer>> loadTimers() async {
    try {
      final SharedPreferences prefs = await _sharedPreferencesFactory();
      final List<String>? timersJson = prefs.getStringList(_storageKey);

      if (timersJson == null) {
        return <InfusionTimer>[];
      }

      return timersJson
          .map(
            (String json) => InfusionTimer.fromJson(jsonDecode(json) as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return <InfusionTimer>[];
    }
  }

  Future<void> saveTimers(List<InfusionTimer> timers) async {
    for (final InfusionTimer timer in timers) {
      timer.reconcile();
    }

    final SharedPreferences prefs = await _sharedPreferencesFactory();
    final List<String> timersJson = timers.map((InfusionTimer timer) => jsonEncode(timer.toJson())).toList();
    await prefs.setStringList(_storageKey, timersJson);
  }
}
