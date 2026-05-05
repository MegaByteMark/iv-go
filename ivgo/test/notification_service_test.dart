import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivgo/domain/infusion_characteristics.dart';
import 'package:ivgo/domain/infusion_notification_milestone.dart';
import 'package:ivgo/domain/infusion_notification_trigger.dart';
import 'package:ivgo/domain/infusion_timer.dart';
import 'package:ivgo/repositories/infusion_notification_settings_repository.dart';
import 'package:ivgo/services/notification_permission_status.dart';
import 'package:ivgo/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'fakes/services/adapters/fake_notification_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService', () {
    late DateTime now;
    late FakeNotificationClient fakeNotificationClient;

    InfusionTimer createTimer({
      required double volume,
      double dropFactor = 20,
      double flowRate = 60,
    }) {
      return InfusionTimer(
        1,
        'Saline',
        InfusionCharacteristics(
          volume: volume,
          dropFactor: dropFactor,
          flowRate: flowRate,
        ),
        nowProvider: () => now,
      );
    }

    InfusionNotificationMilestone createMilestone({
      required String key,
      required String title,
      required String body,
      required Duration offset,
      required InfusionNotificationTrigger trigger,
    }) {
      return InfusionNotificationMilestone(
        key: key,
        title: title,
        body: body,
        offset: offset,
        trigger: trigger,
      );
    }

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));

      now = DateTime.utc(2026, 4, 9, 12);
      fakeNotificationClient = FakeNotificationClient();
    });

    test('coalesces multiple due before-end milestones into the most urgent notification', () async {
      final NotificationService service = NotificationService(
        nowProvider: () => now,
        notificationClient: fakeNotificationClient,
        settingsRepository: _FakeNotificationSettingsRepository(
          <InfusionNotificationMilestone>[
            createMilestone(
              key: 'ten_minutes_remaining',
              title: '10 minutes remaining',
              body: '{timer_title} has entered the last 10 minutes.',
              offset: const Duration(minutes: 10),
              trigger: InfusionNotificationTrigger.beforeEnd,
            ),
            createMilestone(
              key: 'one_minute_remaining',
              title: '1 minute remaining',
              body: '{timer_title} is nearly complete.',
              offset: const Duration(minutes: 1),
              trigger: InfusionNotificationTrigger.beforeEnd,
            ),
          ],
        ),
      );
      final InfusionTimer timer = createTimer(volume: 31);
      final InfusionNotificationMilestone tenMinuteMilestone = createMilestone(
        key: 'ten_minutes_remaining',
        title: '10 minutes remaining',
        body: '{timer_title} has entered the last 10 minutes.',
        offset: const Duration(minutes: 10),
        trigger: InfusionNotificationTrigger.beforeEnd,
      );
      final InfusionNotificationMilestone oneMinuteMilestone = createMilestone(
        key: 'one_minute_remaining',
        title: '1 minute remaining',
        body: '{timer_title} is nearly complete.',
        offset: const Duration(minutes: 1),
        trigger: InfusionNotificationTrigger.beforeEnd,
      );

      timer.start();
      now = now.add(const Duration(seconds: 570));

      await service.scheduleMilestonesForTimer(timer);

      expect(fakeNotificationClient.shownNotifications, hasLength(1));
      expect(fakeNotificationClient.scheduledNotifications, isEmpty);
      expect(fakeNotificationClient.shownNotifications.single.title, '1 minute remaining');
      expect(fakeNotificationClient.shownNotifications.single.body, 'Saline is nearly complete.');
      expect(timer.hasHandledMilestone(tenMinuteMilestone), isTrue);
      expect(timer.hasHandledMilestone(oneMinuteMilestone), isTrue);
    });

    test('schedules upcoming milestones for running timers', () async {
      final InfusionNotificationMilestone milestone = createMilestone(
        key: 'one_minute_remaining',
        title: '1 minute remaining',
        body: '{timer_title} is nearly complete.',
        offset: const Duration(minutes: 1),
        trigger: InfusionNotificationTrigger.beforeEnd,
      );
      final NotificationService service = NotificationService(
        nowProvider: () => now,
        notificationClient: fakeNotificationClient,
        settingsRepository: _FakeNotificationSettingsRepository(
          <InfusionNotificationMilestone>[milestone],
        ),
      );
      final InfusionTimer timer = createTimer(volume: 6);

      timer.start();

      await service.scheduleMilestonesForTimer(timer);

      expect(fakeNotificationClient.shownNotifications, isEmpty);
      expect(fakeNotificationClient.scheduledNotifications, hasLength(1));
      expect(fakeNotificationClient.scheduledNotifications.single.title, '1 minute remaining');
      expect(fakeNotificationClient.scheduledNotifications.single.body, 'Saline is nearly complete.');
    });

    test('skips before-end milestones whose offset is not shorter than the infusion duration', () async {
      final NotificationService service = NotificationService(
        nowProvider: () => now,
        notificationClient: fakeNotificationClient,
        settingsRepository: _FakeNotificationSettingsRepository(
          <InfusionNotificationMilestone>[
            createMilestone(
              key: 'ten_minutes_remaining',
              title: '10 minutes remaining',
              body: '{timer_title} has entered the last 10 minutes.',
              offset: const Duration(minutes: 10),
              trigger: InfusionNotificationTrigger.beforeEnd,
            ),
            createMilestone(
              key: 'one_minute_remaining',
              title: '1 minute remaining',
              body: '{timer_title} is nearly complete.',
              offset: const Duration(minutes: 1),
              trigger: InfusionNotificationTrigger.beforeEnd,
            ),
          ],
        ),
      );
      final InfusionTimer timer = createTimer(volume: 6);

      timer.start();

      await service.scheduleMilestonesForTimer(timer);

      expect(fakeNotificationClient.shownNotifications, isEmpty);
      expect(fakeNotificationClient.scheduledNotifications, hasLength(1));
      expect(fakeNotificationClient.scheduledNotifications.single.title, '1 minute remaining');
    });

    test('does not re-show a before-end milestone during lifecycle resync after its scheduled notification has fired', () async {
      final InfusionNotificationMilestone milestone = createMilestone(
        key: 'one_minute_remaining',
        title: '1 minute remaining',
        body: '{timer_title} is nearly complete.',
        offset: const Duration(minutes: 1),
        trigger: InfusionNotificationTrigger.beforeEnd,
      );
      final NotificationService service = NotificationService(
        nowProvider: () => now,
        notificationClient: fakeNotificationClient,
        settingsRepository: _FakeNotificationSettingsRepository(
          <InfusionNotificationMilestone>[milestone],
        ),
      );
      final InfusionTimer timer = createTimer(volume: 6);

      timer.start();

      await service.scheduleMilestonesForTimer(timer);

      final ScheduledNotification scheduledNotification = fakeNotificationClient.scheduledNotifications.single;

      fakeNotificationClient.pendingNotifications = <PendingNotificationRequest>[
        PendingNotificationRequest(
          scheduledNotification.id,
          scheduledNotification.title,
          scheduledNotification.body,
          scheduledNotification.payload,
        ),
      ];
      fakeNotificationClient.scheduledNotifications.clear();

      now = now.add(const Duration(seconds: 70));
      fakeNotificationClient.pendingNotifications = <PendingNotificationRequest>[];

      await service.scheduleMilestonesForTimer(
        timer,
        suppressAlreadyDeliveredBeforeEndMilestones: true,
      );

      expect(fakeNotificationClient.shownNotifications, isEmpty);
      expect(fakeNotificationClient.scheduledNotifications, isEmpty);
      expect(timer.hasHandledMilestone(milestone), isTrue);
    });

    test('replaces dot-notation placeholders in notification templates', () async {
      final InfusionNotificationMilestone milestone = createMilestone(
        key: 'one_minute_remaining',
        title: '1 minute remaining',
        body: 'Infusion {timer.title} is nearly complete for {milestone.title}.',
        offset: const Duration(minutes: 1),
        trigger: InfusionNotificationTrigger.beforeEnd,
      );
      final NotificationService service = NotificationService(
        nowProvider: () => now,
        notificationClient: fakeNotificationClient,
        settingsRepository: _FakeNotificationSettingsRepository(
          <InfusionNotificationMilestone>[milestone],
        ),
      );
      final InfusionTimer timer = createTimer(volume: 6);

      timer.start();

      await service.scheduleMilestonesForTimer(timer);

      expect(fakeNotificationClient.scheduledNotifications, hasLength(1));
      expect(
        fakeNotificationClient.scheduledNotifications.single.body,
        'Infusion Saline is nearly complete for 1 minute remaining.',
      );
    });

    test('uses time-sensitive iOS details for milestone notifications', () async {
      final InfusionNotificationMilestone milestone = createMilestone(
        key: 'one_minute_remaining',
        title: '1 minute remaining',
        body: '{timer_title} is nearly complete.',
        offset: const Duration(minutes: 1),
        trigger: InfusionNotificationTrigger.beforeEnd,
      );

      final NotificationService service = NotificationService(
        nowProvider: () => now,
        notificationClient: fakeNotificationClient,
        settingsRepository: _FakeNotificationSettingsRepository(
          <InfusionNotificationMilestone>[milestone],
        ),
      );

      final InfusionTimer timer = createTimer(volume: 6);

      timer.start();

      await service.scheduleMilestonesForTimer(timer);

      final DarwinNotificationDetails? iosDetails = fakeNotificationClient.scheduledNotifications.single.notificationDetails.iOS;

      expect(iosDetails, isNotNull);
      expect(iosDetails?.interruptionLevel, InterruptionLevel.timeSensitive);
      expect(iosDetails?.presentBanner, isTrue);
      expect(iosDetails?.presentList, isTrue);
      expect(iosDetails?.presentSound, isTrue);
    });

    test('uses urgent Windows details for milestone notifications', () async {
      final InfusionNotificationMilestone milestone = createMilestone(
        key: 'one_minute_remaining',
        title: '1 minute remaining',
        body: '{timer_title} is nearly complete.',
        offset: const Duration(minutes: 1),
        trigger: InfusionNotificationTrigger.beforeEnd,
      );
      final NotificationService service = NotificationService(
        nowProvider: () => now,
        notificationClient: fakeNotificationClient,
        settingsRepository: _FakeNotificationSettingsRepository(
          <InfusionNotificationMilestone>[milestone],
        ),
      );
      final InfusionTimer timer = createTimer(volume: 6);

      timer.start();

      await service.scheduleMilestonesForTimer(timer);

      final WindowsNotificationDetails? windowsDetails = fakeNotificationClient.scheduledNotifications.single.notificationDetails.windows;

      expect(windowsDetails, isNotNull);
      expect(windowsDetails?.duration, WindowsNotificationDuration.long);
      expect(windowsDetails?.scenario, WindowsNotificationScenario.urgent);
    });

    test('uses foreground-presenting macOS details for milestone notifications', () async {
      final InfusionNotificationMilestone milestone = createMilestone(
        key: 'one_minute_remaining',
        title: '1 minute remaining',
        body: '{timer_title} is nearly complete.',
        offset: const Duration(minutes: 1),
        trigger: InfusionNotificationTrigger.beforeEnd,
      );
      final NotificationService service = NotificationService(
        nowProvider: () => now,
        notificationClient: fakeNotificationClient,
        settingsRepository: _FakeNotificationSettingsRepository(
          <InfusionNotificationMilestone>[milestone],
        ),
      );
      final InfusionTimer timer = createTimer(volume: 6);

      timer.start();

      await service.scheduleMilestonesForTimer(timer);

      final DarwinNotificationDetails? macosDetails = fakeNotificationClient.scheduledNotifications.single.notificationDetails.macOS;

      expect(macosDetails, isNotNull);
      expect(macosDetails?.presentAlert, isTrue);
      expect(macosDetails?.presentBadge, isTrue);
      expect(macosDetails?.presentSound, isTrue);
      expect(macosDetails?.presentBanner, isTrue);
      expect(macosDetails?.presentList, isTrue);
      expect(macosDetails?.interruptionLevel, isNull);
    });

    test('requestPermissions uses the macOS notification client flow', () async {
      final NotificationService service = NotificationService(
        nowProvider: () => now,
        notificationClient: fakeNotificationClient,
        settingsRepository: _FakeNotificationSettingsRepository(
          const <InfusionNotificationMilestone>[],
        ),
        targetPlatform: TargetPlatform.macOS,
      );

      final bool granted = await service.requestPermissions();

      expect(granted, isTrue);
      expect(service.permissionStatus.value, NotificationPermissionStatus.granted);
      expect(fakeNotificationClient.requestPermissionsCallCount, 1);
    });

    test('cancels only pending notifications for the specified timer id', () async {
      final NotificationService service = NotificationService(
        nowProvider: () => now,
        notificationClient: fakeNotificationClient,
        settingsRepository: _FakeNotificationSettingsRepository(
          const <InfusionNotificationMilestone>[],
        ),
      );
      final InfusionTimer timer = createTimer(volume: 6);

      fakeNotificationClient.pendingNotifications = <PendingNotificationRequest>[
        const PendingNotificationRequest(101, 'A', 'B', '1:ten_minutes_remaining'),
        const PendingNotificationRequest(102, 'C', 'D', '1:one_minute_remaining'),
        const PendingNotificationRequest(201, 'E', 'F', '2:one_minute_remaining'),
      ];

      await service.cancelMilestonesForTimer(timer);

      expect(fakeNotificationClient.cancelledIds, <int>[101, 102]);
    });

    test('refreshPermissionStatus stays notDetermined before any permission prompt', () async {
      final NotificationService service = NotificationService(
        nowProvider: () => now,
        notificationClient: fakeNotificationClient,
        settingsRepository: _FakeNotificationSettingsRepository(
          const <InfusionNotificationMilestone>[],
        ),
      );

      final NotificationPermissionStatus status = await service.refreshPermissionStatus();

      expect(status, NotificationPermissionStatus.notDetermined);
      expect(
        service.permissionStatus.value,
        NotificationPermissionStatus.notDetermined,
      );
    });

    test('requestPermissions persists denied status after a rejection', () async {
      fakeNotificationClient.permissionRequestResult = false;

      final NotificationService service = NotificationService(
        nowProvider: () => now,
        notificationClient: fakeNotificationClient,
        settingsRepository: _FakeNotificationSettingsRepository(
          const <InfusionNotificationMilestone>[],
        ),
      );

      final bool granted = await service.requestPermissions();
      fakeNotificationClient.permissionStatus = NotificationPermissionStatus.notDetermined;

      final NotificationPermissionStatus refreshedStatus = await service.refreshPermissionStatus();

      expect(granted, isFalse);
      expect(
        service.permissionStatus.value,
        NotificationPermissionStatus.denied,
      );
      expect(refreshedStatus, NotificationPermissionStatus.denied);
    });

    test('requestPermissions updates status to granted when accepted', () async {
      final NotificationService service = NotificationService(
        nowProvider: () => now,
        notificationClient: fakeNotificationClient,
        settingsRepository: _FakeNotificationSettingsRepository(
          const <InfusionNotificationMilestone>[],
        ),
      );

      final bool granted = await service.requestPermissions();

      expect(granted, isTrue);
      expect(
        service.permissionStatus.value,
        NotificationPermissionStatus.granted,
      );
    });

    test('requestPermissions updates status to unavailable when platform support is not available', () async {
      final NotificationService service = NotificationService(
        nowProvider: () => now,
        notificationClient: fakeNotificationClient,
        settingsRepository: _FakeNotificationSettingsRepository(
          const <InfusionNotificationMilestone>[],
        ),
        targetPlatform: TargetPlatform.linux,
      );

      final bool granted = await service.requestPermissions();

      expect(granted, isFalse);
      expect(
        service.permissionStatus.value,
        NotificationPermissionStatus.unavailable,
      );
    });

    test('refreshPermissionStatus treats windows as granted without a prompt', () async {
      final NotificationService service = NotificationService(
        nowProvider: () => now,
        notificationClient: fakeNotificationClient,
        settingsRepository: _FakeNotificationSettingsRepository(
          const <InfusionNotificationMilestone>[],
        ),
        targetPlatform: TargetPlatform.windows,
      );

      final NotificationPermissionStatus status = await service.refreshPermissionStatus();

      expect(status, NotificationPermissionStatus.granted);
      expect(service.permissionStatus.value, NotificationPermissionStatus.granted);
      expect(fakeNotificationClient.getPermissionStatusCallCount, 0);
    });

    test('requestPermissions returns granted on windows without prompting the client', () async {
      fakeNotificationClient.permissionRequestResult = false;

      final NotificationService service = NotificationService(
        nowProvider: () => now,
        notificationClient: fakeNotificationClient,
        settingsRepository: _FakeNotificationSettingsRepository(
          const <InfusionNotificationMilestone>[],
        ),
        targetPlatform: TargetPlatform.windows,
      );

      final bool granted = await service.requestPermissions();

      expect(granted, isTrue);
      expect(service.permissionStatus.value, NotificationPermissionStatus.granted);
      expect(fakeNotificationClient.requestPermissionsCallCount, 0);
    });
  });
}

class _FakeNotificationSettingsRepository extends InfusionNotificationSettingsRepository {
  _FakeNotificationSettingsRepository(this._milestones);

  final List<InfusionNotificationMilestone> _milestones;

  @override
  Future<List<InfusionNotificationMilestone>> loadMilestones() async {
    return List<InfusionNotificationMilestone>.of(_milestones);
  }
}
