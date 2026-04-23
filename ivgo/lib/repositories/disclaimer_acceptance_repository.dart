import 'package:shared_preferences/shared_preferences.dart';

class DisclaimerAcceptanceRepository {
  DisclaimerAcceptanceRepository({
    Future<SharedPreferences> Function()? sharedPreferencesFactory,
  }) : _sharedPreferencesFactory = sharedPreferencesFactory ?? SharedPreferences.getInstance;

  static const String _storageKey = 'hasAcceptedDisclaimer';

  final Future<SharedPreferences> Function() _sharedPreferencesFactory;

  Future<bool> hasAcceptedDisclaimer() async {
    final SharedPreferences sharedPreferences = await _sharedPreferencesFactory();

    return sharedPreferences.getBool(_storageKey) ?? false;
  }

  Future<void> recordAcceptedDisclaimer() async {
    final SharedPreferences sharedPreferences = await _sharedPreferencesFactory();

    await sharedPreferences.setBool(_storageKey, true);
  }
}
