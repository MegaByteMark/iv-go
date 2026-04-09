import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ivgo/services/adapters/notification_client.dart';
import 'package:timezone/timezone.dart' as tz;

class FakeNotificationClient implements NotificationClient {
  final List<ShownNotification> shownNotifications = <ShownNotification>[];
  final List<ScheduledNotification> scheduledNotifications = <ScheduledNotification>[];
  final List<int> cancelledIds = <int>[];
  List<PendingNotificationRequest> pendingNotifications = <PendingNotificationRequest>[];

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
    shownNotifications.add(ShownNotification(title: title, body: body));
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
        payload: payload,
      ),
    );
  }
}

class ShownNotification {
  const ShownNotification({required this.title, required this.body});

  final String? title;
  final String? body;
}

class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final tz.TZDateTime scheduledDate;
  final String? payload;
}
