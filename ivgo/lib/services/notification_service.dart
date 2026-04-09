import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ivgo/domain/infusion_notification_milestone.dart';
import 'package:ivgo/domain/infusion_notification_trigger.dart';
import 'package:ivgo/domain/infusion_timer.dart';
import 'package:ivgo/repositories/infusion_notification_settings_repository.dart';
import 'package:ivgo/services/adapters/flutter_local_notification_client.dart';
import 'package:ivgo/services/adapters/notification_client.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService({
    InfusionNotificationSettingsRepository? settingsRepository,
    FlutterLocalNotificationsPlugin? plugin,
    NotificationClient? notificationClient,
    DateTime Function()? nowProvider,
  })  : _settingsRepository = settingsRepository ?? InfusionNotificationSettingsRepository(),
        _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _notificationClient = notificationClient ?? FlutterLocalNotificationClient(plugin ?? FlutterLocalNotificationsPlugin()),
        _nowProvider = nowProvider ?? DateTime.now;

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationClient _notificationClient;
  final InfusionNotificationSettingsRepository _settingsRepository;
  final DateTime Function() _nowProvider;

  static const String _milestoneChannelId = 'ivgo_milestones';
  static const String _milestoneChannelName = 'IVGo Milestones';
  static const String _milestoneChannelDescription = 'Notifications for infusion milestones';

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

  Future<void> scheduleMilestonesForTimer(InfusionTimer timer) async {
    final DateTime effectiveNow = _nowProvider();
    final List<InfusionNotificationMilestone> milestones = await _settingsRepository.loadMilestones();

    await cancelMilestonesForTimer(timer);

    final List<InfusionNotificationMilestone> dueMilestones = timer.dueNotificationMilestones(
      now: effectiveNow,
      milestones: milestones,
    );

    // There is a chance that we may have multiple notifications that will be due at the same time e.g. 10 minutes before and 1 minute before
    // if the app was restored whilst the timer was running and the 10 minute had passed but not the 1 minute window.
    // In that case, we want to coalesce those notifications into a single notification for the most urgent milestone (e.g. 1 minute before)
    // to avoid spamming the user with multiple notifications at once when they open the app after a while.
    // However, we need to ensure all notifications are marked as handled to avoid the less urgent ones from being scheduled immediately after handling the most urgent one.
    final _CoalescedDueMilestones coalescedDueMilestones = _coalesceDueMilestones(dueMilestones);

    // Handle those which need scheduling immediately (e.g. after end milestones for already ended timers) before scheduling to ensure correct ordering
    for (final milestone in coalescedDueMilestones.deliverNow) {
      await _showMilestoneNotification(timer, milestone);
      timer.markMilestoneHandled(milestone);
    }

    // Mark the less urgent milestones as handled without delivery to avoid them being scheduled immediately after handling the most urgent one,
    //but only after the most urgent one has been delivered to ensure correct ordering of notifications.
    for (final milestone in coalescedDueMilestones.markHandledWithoutDelivery) {
      timer.markMilestoneHandled(milestone);
    }

    // Now schedule any not-yet-handled milestones that are still upcoming. This includes any before end milestones for running timers, and any after end milestones for ended timers that aren't yet due.
    for (final milestone in milestones) {
      if (timer.hasHandledMilestone(milestone)) {
        continue;
      }

      final tz.TZDateTime? scheduledAt = _scheduledTimeForMilestone(timer, milestone, now: effectiveNow);

      if (scheduledAt == null) {
        continue;
      }

      await _scheduleNotificationForMilestone(timer, milestone, scheduledAt: scheduledAt);
    }
  }

  Future<void> cancelMilestonesForTimer(InfusionTimer timer) async {
    final List<PendingNotificationRequest> pendingNotifications = await _notificationClient.pendingNotificationRequests();

    for (final pendingNotification in pendingNotifications) {
      if (pendingNotification.payload?.startsWith('${timer.id}:') ?? false) {
        await _notificationClient.cancel(id: pendingNotification.id);
      }
    }
  }

  _CoalescedDueMilestones _coalesceDueMilestones(
    List<InfusionNotificationMilestone> dueMilestones,
  ) {
    final List<InfusionNotificationMilestone> beforeEndMilestones = dueMilestones.where((milestone) => milestone.trigger == InfusionNotificationTrigger.beforeEnd).toList();
    final List<InfusionNotificationMilestone> afterEndMilestones = dueMilestones.where((milestone) => milestone.trigger == InfusionNotificationTrigger.afterEnd).toList();
    final List<InfusionNotificationMilestone> deliverNow = <InfusionNotificationMilestone>[];
    final List<InfusionNotificationMilestone> markHandledWithoutDelivery = <InfusionNotificationMilestone>[];

    if (beforeEndMilestones.isNotEmpty) {
      beforeEndMilestones.sort(
        (a, b) => a.offset.compareTo(b.offset),
      );

      final InfusionNotificationMilestone mostUrgent = beforeEndMilestones.first;
      deliverNow.add(mostUrgent);

      // Mark the less urgent milestones as handled only after the chosen notification has been delivered.
      for (final milestone in beforeEndMilestones.skip(1)) {
        markHandledWithoutDelivery.add(milestone);
      }
    }

    deliverNow.addAll(afterEndMilestones);

    return _CoalescedDueMilestones(
      deliverNow: deliverNow,
      markHandledWithoutDelivery: markHandledWithoutDelivery,
    );
  }

  Future<void> _showMilestoneNotification(InfusionTimer timer, InfusionNotificationMilestone milestone) async {
    NotificationDetails notificationDetails = _milestoneNotificationDetails();

    await _notificationClient.show(
      id: _generateMilestoneNotificationId(timer, milestone),
      title: milestone.title,
      body: _replacePlaceholders(milestone.body, timer, milestone),
      notificationDetails: notificationDetails,
      payload: _payloadFor(timer, milestone),
    );
  }

  Future<void> _scheduleNotificationForMilestone(
    InfusionTimer timer,
    InfusionNotificationMilestone milestone, {
    required tz.TZDateTime scheduledAt,
  }) async {
    NotificationDetails notificationDetails = _milestoneNotificationDetails();

    await _notificationClient.zonedSchedule(
      id: _generateMilestoneNotificationId(timer, milestone),
      title: milestone.title,
      body: _replacePlaceholders(milestone.body, timer, milestone),
      scheduledDate: scheduledAt,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: _payloadFor(timer, milestone),
    );
  }

  String _replacePlaceholders(String template, InfusionTimer timer, InfusionNotificationMilestone milestone) {
    return template.replaceAll('{timer_title}', timer.title).replaceAll('{milestone_title}', milestone.title);
  }

  tz.TZDateTime? _scheduledTimeForMilestone(InfusionTimer timer, InfusionNotificationMilestone milestone, {required DateTime now}) {
    if (timer.hasHandledMilestone(milestone)) {
      return null;
    }

    if (milestone.trigger == InfusionNotificationTrigger.beforeEnd) {
      // Timer is not running, so theres no reason to notify about an upcoming milestone, but we also shouldn't schedule it in the past, so return null in that case.
      if (!timer.isRunning) {
        return null;
      }

      // Not enough time left to schedule the notification before the end, so return null instead of a past scheduled time
      if (timer.remainingSeconds <= milestone.offset) {
        return null;
      }

      final DateTime scheduledAt = now.add(timer.remainingSeconds - milestone.offset);

      return tz.TZDateTime.from(scheduledAt, tz.local);
    }

    // We should only get here for the afterEnd triggers. Make sure theres a valid timer to notify for.
    if (!timer.isEnded || timer.isRecoveredOverdue || timer.completedAt == null || timer.suppressAfterEndMilestones) {
      return null;
    }

    final DateTime scheduledAt = timer.completedAt!.add(milestone.offset);

    // Don't schedule notifications in the past - if the scheduled time is already passed, return null to indicate it shouldn't be scheduled
    if (!scheduledAt.isAfter(now)) {
      return null;
    }

    return tz.TZDateTime.from(scheduledAt, tz.local);
  }

  int _generateMilestoneNotificationId(
    InfusionTimer timer,
    InfusionNotificationMilestone milestone,
  ) {
    final int milestoneHash = _stableKeyHash(milestone.key) % 10000;

    return (timer.id * 10000) + milestoneHash;
  }

  int _stableKeyHash(String value) {
    return value.codeUnits.fold<int>(
      0,
      (current, unit) => ((current * 31) + unit) & 0x3fffffff,
    );
  }

  String _payloadFor(
    InfusionTimer timer,
    InfusionNotificationMilestone milestone,
  ) {
    return '${timer.id}:${milestone.key}';
  }

  NotificationDetails _milestoneNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _milestoneChannelId,
        _milestoneChannelName,
        channelDescription: _milestoneChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }
}

class _CoalescedDueMilestones {
  const _CoalescedDueMilestones({
    required this.deliverNow,
    required this.markHandledWithoutDelivery,
  });

  final List<InfusionNotificationMilestone> deliverNow;
  final List<InfusionNotificationMilestone> markHandledWithoutDelivery;
}
