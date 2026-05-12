import 'package:ivgo/services/notification_service.dart';
import 'package:ivgo/services/notification_permission_status.dart';
import 'package:ivgo/domain/infusion_timer.dart';
import 'package:timezone/data/latest.dart' as tz_data;

class FakeNotificationService extends NotificationService {
  FakeNotificationService({
    this.permissionResult = true,
    this.exactAlarmPermissionResult = true,
    this.exactAlarmPermissionSupported = false,
    NotificationPermissionStatus initialPermissionStatus = NotificationPermissionStatus.notDetermined,
  }) {
    setPermissionStatus(initialPermissionStatus);
  }

  final bool permissionResult;
  final bool exactAlarmPermissionResult;
  final bool exactAlarmPermissionSupported;
  int scheduledMilestoneCalls = 0;
  int cancelledMilestoneCalls = 0;
  int exactAlarmPermissionCalls = 0;
  final List<int> scheduledTimerIds = <int>[];
  final List<int> cancelledTimerIds = <int>[];

  @override
  bool get supportsExactAlarmPermissionRequest {
    return exactAlarmPermissionSupported || super.supportsExactAlarmPermissionRequest;
  }

  @override
  Future<void> initialize() async {
    tz_data.initializeTimeZones();
  }

  @override
  Future<bool> requestPermissions() async {
    setPermissionStatus(
      permissionResult ? NotificationPermissionStatus.granted : NotificationPermissionStatus.denied,
    );
    return permissionResult;
  }

  @override
  Future<bool> requestExactAlarmPermission() async {
    exactAlarmPermissionCalls += 1;
    return exactAlarmPermissionResult;
  }

  @override
  Future<NotificationPermissionStatus> refreshPermissionStatus() async {
    return permissionStatus.value;
  }

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
