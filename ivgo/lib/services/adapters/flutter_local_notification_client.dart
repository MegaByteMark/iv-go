import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ivgo/services/adapters/notification_client.dart';
import 'package:timezone/timezone.dart' as tz;

class FlutterLocalNotificationClient implements NotificationClient {
  FlutterLocalNotificationClient(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> cancel({required int id}) {
    return _plugin.cancel(id: id);
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() {
    return _plugin.pendingNotificationRequests();
  }

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    required NotificationDetails notificationDetails,
    String? payload,
  }) {
    return _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
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
  }) {
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: androidScheduleMode,
      payload: payload,
    );
  }
}
