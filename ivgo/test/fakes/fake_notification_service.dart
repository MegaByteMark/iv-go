import 'package:ivgo/services/notification_service.dart';
import 'package:ivgo/services/notification_permission_status.dart';
import 'package:ivgo/domain/infusion_timer.dart';

class FakeNotificationService extends NotificationService {
  FakeNotificationService({
    this.permissionResult = true,
    this.exactAlarmPermissionResult = true,
    NotificationPermissionStatus initialPermissionStatus = NotificationPermissionStatus.notDetermined,
  }) {
    setPermissionStatus(initialPermissionStatus);
  }

  final bool permissionResult;
  final bool exactAlarmPermissionResult;
  int scheduledMilestoneCalls = 0;
  int cancelledMilestoneCalls = 0;
  final List<int> scheduledTimerIds = <int>[];
  final List<int> cancelledTimerIds = <int>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermissions() async {
    setPermissionStatus(
      permissionResult ? NotificationPermissionStatus.granted : NotificationPermissionStatus.denied,
    );
    return permissionResult;
  }

  @override
  Future<bool> requestExactAlarmPermission() async => exactAlarmPermissionResult;

  @override
  Future<void> scheduleMilestonesForTimer(
    InfusionTimer timer, {
    bool suppressAlreadyDeliveredBeforeEndMilestones = false,
  }) async {
    scheduledMilestoneCalls += 1;
    scheduledTimerIds.add(timer.id);
  }

  @override
  Future<void> cancelMilestonesForTimer(InfusionTimer timer) async {
    cancelledMilestoneCalls += 1;
    cancelledTimerIds.add(timer.id);
  }
}
