import 'package:ivgo/repositories/first_launch_repository.dart';

class FakeFirstLaunchRepository extends FirstLaunchRepository {
  FakeFirstLaunchRepository({
    bool initialSeen = false,
  }) : _hasSeenOnboarding = initialSeen;

  bool _hasSeenOnboarding;

  @override
  Future<bool> hasSeenOnboarding() async {
    return _hasSeenOnboarding;
  }

  @override
  Future<void> setHasSeenOnboarding(bool value) async {
    _hasSeenOnboarding = value;
  }
}