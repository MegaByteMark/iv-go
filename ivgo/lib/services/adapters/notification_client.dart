import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ivgo/services/notification_permission_status.dart';
import 'package:timezone/timezone.dart' as tz;

abstract class NotificationClient {
  Future<NotificationPermissionStatus> getPermissionStatus({
    required bool hasRequestedPermission,
  });

  Future<bool> requestPermissions();

  Future<void> cancel({required int id});

  Future<List<PendingNotificationRequest>> pendingNotificationRequests();

  Future<void> show({
    required int id,
    String? title,
    String? body,
    required NotificationDetails notificationDetails,
    String? payload,
  });

  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
  });
}
