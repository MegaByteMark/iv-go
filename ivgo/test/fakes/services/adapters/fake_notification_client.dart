import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ivgo/services/adapters/notification_client.dart';
import 'package:ivgo/services/notification_permission_status.dart';
import 'package:timezone/timezone.dart' as tz;

class FakeNotificationClient implements NotificationClient {
  final List<ShownNotification> shownNotifications = <ShownNotification>[];
  final List<ScheduledNotification> scheduledNotifications = <ScheduledNotification>[];
  final List<int> cancelledIds = <int>[];
  List<PendingNotificationRequest> pendingNotifications = <PendingNotificationRequest>[];
  NotificationPermissionStatus permissionStatus = NotificationPermissionStatus.notDetermined;
  bool permissionRequestResult = true;
  int getPermissionStatusCallCount = 0;
  int requestPermissionsCallCount = 0;

  @override
  Future<NotificationPermissionStatus> getPermissionStatus({
    required bool hasRequestedPermission,
  }) async {
    getPermissionStatusCallCount += 1;

    if (permissionStatus == NotificationPermissionStatus.notDetermined && hasRequestedPermission) {
      return NotificationPermissionStatus.denied;
    }

    return permissionStatus;
  }

  @override
  Future<bool> requestPermissions() async {
    requestPermissionsCallCount += 1;
    permissionStatus = permissionRequestResult ? NotificationPermissionStatus.granted : NotificationPermissionStatus.denied;
    return permissionRequestResult;
  }

  @override
  Future<void> cancel({required int id}) async {
    cancelledIds.add(id);
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return pendingNotifications;
  }

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    required NotificationDetails notificationDetails,
    String? payload,
  }) async {
    shownNotifications.add(
      ShownNotification(
        title: title,
        body: body,
        notificationDetails: notificationDetails,
      ),
    );
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
  }) async {
    scheduledNotifications.add(
      ScheduledNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        payload: payload,
      ),
    );
  }
}

class ShownNotification {
  const ShownNotification({
    required this.title,
    required this.body,
    required this.notificationDetails,
  });

  final String? title;
  final String? body;
  final NotificationDetails notificationDetails;
}

class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.notificationDetails,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final tz.TZDateTime scheduledDate;
  final NotificationDetails notificationDetails;
  final String? payload;
}
