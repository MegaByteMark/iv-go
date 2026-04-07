import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(settings: initializationSettings);
  }

  Future<void> scheduleTestNotification() async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'ivgo_test_channel',
        'IVGo Scheduled Test Notifications',
        channelDescription: 'Temporary channel for scheduled local notification testing',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));

    await _plugin.zonedSchedule(
      id: 1001,
      title: 'IVGo Scheduled Test Notification',
      body: 'This notification was scheduled 10 seconds ago.',
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'scheduled_test',
    );
  }

  Future<bool> requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission() ?? false;
    }

    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }

    throw UnsupportedError('Unsupported platform for requesting notification permissions');
  }

  Future<bool> requestExactAlarmPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      return true;
    }

    return await androidPlugin.requestExactAlarmsPermission() ?? false;
  }

  Future<void> showTestNotification() async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'ivgo_test_channel',
        'IVGo Test Notifications',
        channelDescription: 'Temporary channel for local notification testing',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: 1000,
      title: 'IVGo Test Notification',
      body: 'Local notifications are working.',
      notificationDetails: notificationDetails,
    );
  }
}
