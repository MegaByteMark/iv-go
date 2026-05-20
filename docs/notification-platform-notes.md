# Notification Platform Notes

## iOS Timed Notifications

- `ivgo/ios/Runner/AppDelegate.swift` assigns `UNUserNotificationCenter.current().delegate` so locally scheduled alerts can still present correctly while the app is in the foreground.
- `ivgo/ios/Runner/Runner.entitlements` enables the Time Sensitive Notifications capability needed for `InterruptionLevel.timeSensitive` on iOS 15+.
- `ivgo/lib/services/notification_service.dart` marks milestone alerts as time-sensitive on iOS so the platform can treat them as higher-priority reminder notifications when the capability and device settings allow it.

### Manual Validation Checklist

1. Build and run the app on an iPhone or iOS 15+ simulator.
2. Grant notification permission from the in-app request flow.
3. In iOS Settings, confirm IVGo notifications are enabled and Time Sensitive Notifications remains enabled for the app.
4. Start a timer that will cross the 10-minute, 1-minute, and ended-plus-10-minute milestones.
5. Confirm the milestone alerts appear while the app is foregrounded and again when the app is backgrounded or the device is locked.
6. Pause, edit, reset, or remove the timer and confirm stale future alerts are no longer delivered.

## Windows Workstation Deployment

- `ivgo/lib/services/notification_service.dart` initializes Windows notifications with a stable `appName`, `appUserModelId`, and `guid`. Keep those values stable across releases so packaged installs preserve a consistent toast identity.
- Windows milestone notifications use an urgent toast scenario and long duration so workstation alerts are harder to miss.
- The `flutter_local_notifications` plugin documents an important limitation on Windows: cancellation and active-notification APIs require package identity. In practice that means lifecycle-correct notification validation must be done from an installed MSIX build, not from an unpackaged `flutter run -d windows` session.

### Packaging Notes

1. Package desktop releases as MSIX before relying on Windows notification lifecycle behaviour in production.
2. Keep the Windows App User Model ID and GUID stable between packaged releases.
3. Validate notification delivery from the installed MSIX build on the target workstation image rather than from a development shell.
4. If an MSIX workflow is introduced for release automation, `package:msix` is the packaging path recommended by the plugin documentation.

### Runtime Validation Checklist

1. Install the packaged MSIX build on a Windows 10 or Windows 11 workstation.
2. Launch IVGo once and confirm toast notifications are allowed for the installed app identity.
3. Create a timer and verify the 10-minute and 1-minute milestone notifications arrive while the app is backgrounded.
4. Pause, edit, reset, and remove timers, then confirm stale notifications are not still delivered afterwards.
5. Let a timer finish and confirm the ended-plus-10-minute alert fires only once for that lifecycle.
6. Reopen the app after downtime and confirm recovered-overdue timers and any follow-up notification behaviour remain consistent.
7. Repeat the checks with Focus Assist or workstation notification policies enabled so deployment-specific suppression rules are understood before rollout.

## macOS Support

- `ivgo/lib/services/notification_service.dart` now initializes macOS explicitly with `DarwinInitializationSettings` that defer the permission prompt until the in-app request flow while keeping foreground banner, list, badge, and sound presentation enabled for milestone alerts.
- `ivgo/lib/services/notification_service.dart` keeps macOS milestone notifications on the standard Darwin presentation path rather than the iOS-only time-sensitive interruption level.
- `ivgo/macos/Runner/DebugProfile.entitlements` and `ivgo/macos/Runner/Release.entitlements` already keep the sandbox entitlements required by the Flutter desktop runner. No additional native AppDelegate notification delegate setup was needed because the plugin example uses the same `FlutterAppDelegate` structure already present in `ivgo/macos/Runner/AppDelegate.swift`.
- The plugin documents two practical macOS caveats to keep in mind during rollout: `getNotificationAppLaunchDetails` is unreliable before macOS 10.14, and notification-action callbacks run on the main isolate only on macOS.

### Runtime Validation Checklist

1. Build and run the macOS app on a supported workstation using `flutter run -d macos` or a locally built `.app` bundle.
2. Use the in-app notification permission action and confirm macOS shows the system permission prompt the first time.
3. In System Settings, confirm IVGo notifications are allowed for alerts, sounds, and Notification Center delivery.
4. Start a timer and verify the 10-minute and 1-minute milestone notifications appear while the app is foregrounded.
5. Background the app and verify the same milestone notifications still arrive in Notification Center.
6. Pause, edit, reset, and remove timers, then confirm stale future notifications are not still delivered.
7. Let a timer finish and confirm the ended-plus-10-minute alert fires once for that lifecycle.
8. Reopen the app after downtime and confirm restored overdue timers still reconcile correctly even though macOS app-launch details are not relied on for pre-10.14 systems.