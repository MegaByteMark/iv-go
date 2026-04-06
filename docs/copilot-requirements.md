# Copilot Requirements

Use this file for longer requirements that should guide Copilot agents working in this repo.

Keep `.github/copilot-instructions.md` short and stable. Put detailed constraints here.

## Product Requirements

The purpose of this project is to provide a manual fallback and job aid for healthcare professionals or care workers who need to track infusion progress when automated infusion systems are unavailable or unsuitable.

The application targets mobile devices specifically so the user can keep the device on their person and access timer, notification, and acknowledgement features at all times during care delivery.

The app is a dashboard of infusion timers displayed in a list. Each timer represents a single infusion and uses standard flow calculations based on:

- the target volume to infuse
- the drop factor of the giving set or infusion device
- the configured flow rate

These values are used to calculate the approximate infused volume and the remaining time until the target infusion volume has been delivered.

During an infusion the user must be able to:

- create a timer
- pause a timer
- resume a paused timer
- reset a timer
- restart a paused timer
- re-configure an existing timer
- remove a timer

### Timer Semantics

- Timer calculations must not reset to zero when an infusion is re-configured.
- A re-configuration only affects the remaining portion of the infusion from the next elapsed second onward.
- Previously infused volume must be preserved and must continue to contribute to the total infused amount.
- Example: if the target is `100 mL`, the infusion has already delivered `10 mL`, and the flow settings change, the timer must continue from `10 mL infused` and recalculate the remaining `90 mL` using the new settings.
- Pausing a timer freezes elapsed time and infusion progress until the timer is resumed.
- Restart means resuming a previously paused timer from its current infused amount and remaining time.
- Reset means returning the timer to its initial state for that infusion and clearing previously accumulated progress.

### Validation

- User inputs must be valid positive numbers.
- The app must reject empty, zero, negative, or otherwise invalid numeric inputs for infusion calculations.
- Validation errors must be presented clearly enough that a user can correct them without training.

### Persistence And Background Behavior

- Timers must persist if the app is closed and reopened.
- Restored timers must continue from the correct state based on elapsed real time and prior infusion history.
- Notification behavior must continue to function when the app is not in the foreground, including when the device is asleep or the user is in another app.
- Notification delivery is not required to survive a full device reboot.
- If the device restarts and the app later restores timers that should already have ended, the app must show those timers as ended and clearly highlight that those timers completed while the device was not notifying the user.
- When overdue timers are discovered after device restart, the app may also issue a notification prompting the user to reopen the app and review those timers.

### Notifications

- The app must notify the user using on-device notifications.
- Notifications are safety-relevant and should be treated as time-sensitive where the platform supports this capability.
- The app must notify the user when an infusion enters its last `10 minutes`.
- The app must notify the user when an infusion enters its last `1 minute`.
- The app must notify the user when an infusion has ended and the timer has remained stopped for more than `10 minutes`.
- The `ended and stopped for more than 10 minutes` alert should fire once per timer lifecycle rather than repeating indefinitely.
- If a timer resumes or is restored after already entering a notification window, the relevant milestone notification should be issued at that point unless that milestone has already been issued for the current timer lifecycle.
- The app should track which milestone notifications have already been issued for each timer so the same milestone is not repeatedly re-notified unless the timer has been deliberately reset into a new lifecycle.
- Notifications associated with a timer must be cleared or cancelled if the user pauses, edits, resets, or removes that timer because the user has actively interacted with it.

### Safety Positioning

- The app is a job aid and not a replacement for clinical judgement or appropriate infusion equipment.
- The product must not present itself as an automated infusion controller.
- The product should include an explicit disclaimer explaining that the timer is an aid to monitoring and that the user remains responsible for clinical decisions and equipment checks.
- The disclaimer should be presented as part of first-launch onboarding, recorded as accepted on-device, and not shown again unless the app data is cleared.
- If notification permissions are unavailable or denied, the app should warn the user clearly that background alerts will not function and that timers must then be monitored actively within the app.
- If notification permissions are denied, the warning should remain persistently visible in the main timer list view until permissions are enabled.

### Accessibility And Usability

- The app must be simple enough to use with minimal training.
- The app must remain easy to read and operate in a mobile clinical workflow.
- The interface should prioritize at-a-glance readability, clear status, and interactions that are easy to perform quickly.
- Accessibility considerations such as readable text, clear contrast, and sufficiently large touch targets should be treated as core product requirements rather than polish.

## Engineering Constraints

- The app is for mobile devices only, specifically Android and iOS devices.
- Non-mobile targets in the Flutter project are unsupported and should not be treated as part of the delivered product scope.
- Following Material on Android and Cupertino on iOS is desirable, but a consistent cross-platform interface is acceptable.

- The app needs to be simple enough to use and understand that it needs minimal training of end users, other than potentially short in app training tips for advanced usage.

- There is no requirement for AI agents as part of the app.

- There is no requirement to store user personally identifiable information in the app.

- There is no requirement for authentication such as user login.
- Timer data is specific to a certain user on a certain device and is intended to be short-lived operational data rather than a persistent clinical record.

- Do not replace `shared_preferences` as the persistent store unless explicitly requested.

- Keep the app compatible with the current Flutter SDK declared in `ivgo/pubspec.yaml`.

- Platform-specific notification implementation details for Android and iOS will be defined separately when implementation work begins.

## Acceptance Criteria

- `flutter analyze` passes in `ivgo/`.
- `flutter test` passes in `ivgo/`.
- The user can create new infusion timers.
- The user can edit existing infusion timers.
- The user can re-configure a running infusion timer.
- The user can pause and resume an infusion timer.
- The user can restart a paused infusion timer without losing progress.
- The user can reset an infusion timer back to its initial state.
- The user can remove infusion timers.
- Re-configuring a running infusion timer does not reset the already infused amount.
- After re-configuration, the remaining duration is recalculated using the new flow settings from the next elapsed second onward.
- The app rejects invalid, zero, negative, or empty numeric inputs.
- Timers persist across app close and reopen.
- Restored timers resume with the correct infused amount and remaining duration.
- The user is notified when infusion timers reach required milestones.
- Notification milestones continue to work while the app is not in the foreground.
- If a timer resumes or is restored after entering a notification window, the relevant milestone notification is issued unless that milestone was already issued for the current timer lifecycle.
- Notifications for a timer are cleared or cancelled when the user pauses, edits, resets, or removes that timer.
- Duplicate notifications for the same milestone are prevented within a single timer lifecycle.
- The `ended and stopped for more than 10 minutes` alert fires once per timer lifecycle.
- After device restart and next app launch, timers that should have finished while the device was unavailable are shown as ended and highlighted for review.
- The app can optionally issue a follow-up notification telling the user to open the app and review overdue timers found after restart.
- If notification permissions are denied, the app remains usable but clearly warns the user that background alerting is unavailable.
- If notification permissions are denied, a persistent warning remains visible in the main timer list view until permissions are enabled.
- The app presents a disclaimer that makes clear the app is a job aid rather than an automated infusion controller.
- The first-launch disclaimer is shown once, recorded as accepted locally, and not shown again unless app data is cleared.
- The infusion timers behave according to the calculation defined in infusion rate specifications. For calculating the duration:

```dart
  ((targetVolume * dropFactor) / flowRate) //= time from full volume to empty in minutes
```

for calculating the amount infused:

```dart
  ((secondsAtRategttsPerMin / 60) * (rateIngttsPerMin / gttsPermL)) //= infused volume in mL
```

## Open Questions

- Exact platform-specific implementation details for time-sensitive notifications, permission flows, and background execution on Android and iOS will need to be defined during implementation.
