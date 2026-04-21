import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ivgo/domain/infusion_notification_milestone.dart';
import 'package:ivgo/domain/infusion_notification_trigger.dart';
import 'package:ivgo/domain/infusion_timer.dart';
import 'package:ivgo/repositories/infusion_notification_settings_repository.dart';
import 'package:ivgo/services/adapters/flutter_local_notification_client.dart';
import 'package:ivgo/services/adapters/notification_client.dart';
import 'package:ivgo/services/notification_permission_status.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService({
    InfusionNotificationSettingsRepository? settingsRepository,
    FlutterLocalNotificationsPlugin? plugin,
    NotificationClient? notificationClient,
    DateTime Function()? nowProvider,
    Future<SharedPreferences> Function()? sharedPreferencesFactory,
    TargetPlatform? targetPlatform,
    bool? isWeb,
  }) : this._(
          settingsRepository: settingsRepository ?? InfusionNotificationSettingsRepository(),
          plugin: plugin ?? FlutterLocalNotificationsPlugin(),
          notificationClient: notificationClient,
          nowProvider: nowProvider ?? DateTime.now,
          sharedPreferencesFactory: sharedPreferencesFactory ?? SharedPreferences.getInstance,
          targetPlatform: targetPlatform ?? defaultTargetPlatform,
          isWeb: isWeb ?? kIsWeb,
        );

  NotificationService._({
    required InfusionNotificationSettingsRepository settingsRepository,
    required FlutterLocalNotificationsPlugin plugin,
    required NotificationClient? notificationClient,
    required DateTime Function() nowProvider,
    required Future<SharedPreferences> Function() sharedPreferencesFactory,
    required TargetPlatform targetPlatform,
    required bool isWeb,
  })  : _settingsRepository = settingsRepository,
        _plugin = plugin,
        _notificationClient = notificationClient ?? FlutterLocalNotificationClient(plugin),
        _nowProvider = nowProvider,
        _sharedPreferencesFactory = sharedPreferencesFactory,
        _targetPlatform = targetPlatform,
        _isWeb = isWeb;

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationClient _notificationClient;
  final InfusionNotificationSettingsRepository _settingsRepository;
  final DateTime Function() _nowProvider;
  final Future<SharedPreferences> Function() _sharedPreferencesFactory;
  final TargetPlatform _targetPlatform;
  final bool _isWeb;
  final _permissionStatus = signal(
    NotificationPermissionStatus.notDetermined,
    debugLabel: 'notificationPermissionStatus',
  );

  static const String _milestoneChannelId = 'ivgo_milestones';
  static const String _milestoneChannelName = 'IVGo Milestones';
  static const String _milestoneChannelDescription = 'Notifications for infusion milestones';
  static const String _permissionRequestedStorageKey = 'hasRequestedNotificationPermission';
  static const String _windowsAppUserModelId = 'MarkHart.IVGo.Desktop.1';
  static const String _windowsGuid = '7d9f4c3e-1f8f-4c6a-a2d2-4f0a8b2f6e31';

  ReadonlySignal<NotificationPermissionStatus> get permissionStatus => _permissionStatus;

  bool get supportsNotificationPermissionRequest {
    if (_isWeb) {
      return false;
    }

    return switch (_targetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };
  }

  bool get supportsExactAlarmPermissionRequest {
    return !_isWeb && _targetPlatform == TargetPlatform.android;
  }

  bool get _usesImplicitNotificationPermission {
    return !_isWeb && _targetPlatform == TargetPlatform.windows;
  }

  @protected
  void setPermissionStatus(NotificationPermissionStatus status) {
    _permissionStatus.value = status;
  }

  Future<void> initialize() async {
    tz.initializeTimeZones();

    await _plugin.initialize(settings: _initializationSettings());

    try {
      await refreshPermissionStatus();
    } catch (e) {
      debugPrint('Error checking notification permissions during initialization: $e');
    }
  }

  Future<NotificationPermissionStatus> refreshPermissionStatus() async {
    if (_usesImplicitNotificationPermission) {
      setPermissionStatus(NotificationPermissionStatus.granted);

      return NotificationPermissionStatus.granted;
    }

    final NotificationPermissionStatus status = await _notificationClient.getPermissionStatus(
      hasRequestedPermission: await _hasRequestedPermission(),
    );
    setPermissionStatus(status);

    return status;
  }

  Future<bool> requestPermissions() async {
    if (_usesImplicitNotificationPermission) {
      setPermissionStatus(NotificationPermissionStatus.granted);

      return true;
    }

    if (!supportsNotificationPermissionRequest) {
      setPermissionStatus(NotificationPermissionStatus.unavailable);

      return false;
    }

    final bool granted = await _notificationClient.requestPermissions();
    await _markPermissionRequested();
    await refreshPermissionStatus();

    return granted;
  }

  Future<bool> requestExactAlarmPermission() async {
    if (!supportsExactAlarmPermissionRequest) {
      return true;
    }

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      return true;
    }

    return await androidPlugin.requestExactAlarmsPermission() ?? false;
  }

  Future<bool> _hasRequestedPermission() async {
    final SharedPreferences sharedPreferences = await _sharedPreferencesFactory();

    return sharedPreferences.getBool(_permissionRequestedStorageKey) ?? false;
  }

  Future<void> _markPermissionRequested() async {
    final SharedPreferences sharedPreferences = await _sharedPreferencesFactory();

    await sharedPreferences.setBool(_permissionRequestedStorageKey, true);
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
      macOS: DarwinNotificationDetails(),
      windows: WindowsNotificationDetails(),
    );
  }

  InitializationSettings _initializationSettings() {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const WindowsInitializationSettings windowsSettings = WindowsInitializationSettings(
      appName: 'IVGo',
      appUserModelId: _windowsAppUserModelId,
      guid: _windowsGuid,
    );

    return const InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      windows: windowsSettings,
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
