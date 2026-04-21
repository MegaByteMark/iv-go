import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ivgo/services/adapters/notification_client.dart';
import 'package:ivgo/services/notification_permission_status.dart';
import 'package:timezone/timezone.dart' as tz;

class FlutterLocalNotificationClient implements NotificationClient {
  FlutterLocalNotificationClient(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<NotificationPermissionStatus> getPermissionStatus({
    required bool hasRequestedPermission,
  }) async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final bool notificationsEnabled = await androidPlugin.areNotificationsEnabled() ?? false;

      if (notificationsEnabled) {
        return NotificationPermissionStatus.granted;
      }

      return hasRequestedPermission ? NotificationPermissionStatus.denied : NotificationPermissionStatus.notDetermined;
    }

    final IOSFlutterLocalNotificationsPlugin? iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      final NotificationsEnabledOptions? permissions = await iosPlugin.checkPermissions();
      final bool notificationsEnabled = (permissions?.isEnabled ?? false) || (permissions?.isProvisionalEnabled ?? false);

      if (notificationsEnabled) {
        return NotificationPermissionStatus.granted;
      }

      return hasRequestedPermission ? NotificationPermissionStatus.denied : NotificationPermissionStatus.notDetermined;
    }

    final MacOSFlutterLocalNotificationsPlugin? macosPlugin = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();

    if (macosPlugin != null) {
      final NotificationsEnabledOptions? permissions = await macosPlugin.checkPermissions();
      final bool notificationsEnabled = (permissions?.isEnabled ?? false) || (permissions?.isProvisionalEnabled ?? false);

      if (notificationsEnabled) {
        return NotificationPermissionStatus.granted;
      }

      return hasRequestedPermission ? NotificationPermissionStatus.denied : NotificationPermissionStatus.notDetermined;
    }

    return NotificationPermissionStatus.unavailable;
  }

  @override
  Future<bool> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission() ?? false;
    }

    final IOSFlutterLocalNotificationsPlugin? iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    final MacOSFlutterLocalNotificationsPlugin? macosPlugin = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();

    if (macosPlugin != null) {
      return await macosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return false;
  }

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
