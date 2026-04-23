import 'package:ivgo/repositories/disclaimer_acceptance_repository.dart';

class FakeDisclaimerAcceptanceRepository extends DisclaimerAcceptanceRepository {
  FakeDisclaimerAcceptanceRepository({
    bool initialAccepted = false,
  }) : _hasAcceptedDisclaimer = initialAccepted;

  bool _hasAcceptedDisclaimer;

  @override
  Future<bool> hasAcceptedDisclaimer() async {
    return _hasAcceptedDisclaimer;
  }

  @override
  Future<void> recordAcceptedDisclaimer() async {
    _hasAcceptedDisclaimer = true;
  }
}
