import 'package:shared_preferences/shared_preferences.dart';

class FirstLaunchRepository {
  FirstLaunchRepository({
    Future<SharedPreferences> Function()? sharedPreferencesFactory,
  }) : _sharedPreferencesFactory = sharedPreferencesFactory ?? SharedPreferences.getInstance;

  static const String _storageKey = 'hasSeenOnboarding';

  final Future<SharedPreferences> Function() _sharedPreferencesFactory;

  Future<bool> hasSeenOnboarding() async {
    final SharedPreferences sharedPreferences = await _sharedPreferencesFactory();

    return sharedPreferences.getBool(_storageKey) ?? false;
  }

  Future<void> setHasSeenOnboarding(bool value) async {
    final SharedPreferences sharedPreferences = await _sharedPreferencesFactory();

    await sharedPreferences.setBool(_storageKey, value);
  }
}