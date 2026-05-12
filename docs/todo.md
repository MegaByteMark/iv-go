# TODO List - iv-go Application

Based on review of `copilot-requirements.md` vs current codebase implementation in `ivgo/`.

---

## Critical: Timer Lifecycle, Persistence, And Restore

### Timer State Model
- [x] Replace the current simple running/stopped model with explicit timer states such as running, paused, and ended
- [x] Separate pause/resume semantics from completion semantics so a finished infusion is not treated the same as a manually paused infusion
- [x] Fix the timer lifecycle so pausing, resuming, resetting, and completion all work reliably after a timer has been cancelled once
- [x] Add explicit recovered-overdue state and UI behavior for timers discovered as completed after app/device downtime

### Persistence Reliability
- [x] Redesign persisted infusion history into a JSON-safe structure
- [x] Save timer state after every meaningful mutation, including add, edit, pause, resume, reset, and remove
- [x] Persist and restore enough lifecycle metadata to correctly distinguish paused, running, and completed timers
- [x] Ensure async restore triggers a UI rebuild and reinitializes any required refresh behavior after load completes

### Restore And Reconciliation
- [x] Rework restore logic so paused timers do not auto-resume when the app is reopened
- [x] Rework restore logic so elapsed real time is only applied to periods when the timer was actually running
- [x] If a timer should have finished while the app was closed or the device was unavailable, restore it as ended rather than continuing it
- [x] Clearly highlight timers that completed while the device was unavailable so the user can review them on next launch
- [x] Decide and implement how overdue recovered timers are acknowledged or cleared from the highlighted state

---

## Critical: Notifications

### Notification Setup Progress
- [x] Add `flutter_local_notifications` dependency using the latest SDK-compatible major version
- [x] Introduce `NotificationService` in `ivgo/lib/services/notification_service.dart`
- [x] Initialize the notification plugin during app startup
- [x] Add an explicit permission request flow instead of prompting at app startup
- [x] Add a temporary app-bar action to request notification permissions and confirm the result with a snackbar
- [x] Add a temporary app-bar action to fire an immediate local test notification and verify end-to-end delivery
- [x] Add explicit scheduled-notification support using timezone-aware scheduling
- [x] Add a temporary scheduled test notification to prove delayed delivery before wiring milestone logic
- [x] Remove temporary notification test UI once milestone notifications are implemented
- [x] Implement the first real timer milestone notification using the current notification service

### Required Notifications
- [x] Implement last 10 minutes milestone notification
- [x] Implement last 1 minute milestone notification
- [x] Implement "ended and stopped for more than 10 minutes" notification that fires once per timer lifecycle
- [x] Track which milestone notifications have already fired for the current timer lifecycle
- [x] If a timer resumes or restores inside a milestone window, issue the milestone notification unless it already fired in that lifecycle

### Notification Cancellation And Recovery
- [x] Cancel or clear notifications when the user pauses, edits, resets, or removes a timer
- [x] Ensure duplicate notifications are prevented within a single timer lifecycle
- [x] Define and implement notification behavior for timers recovered as already ended after app relaunch

### Notification Permissions And Platform Work
- [x] Request notification permissions at the appropriate point in the app flow
- [x] Handle denied or unavailable permissions clearly without blocking core timer use
  - [x] Replace the generic permission-request feedback with explicit denied-state guidance and the in-app monitoring fallback
  - [x] Decide whether denied notifications should offer a recovery path such as opening system settings or explicit re-enable instructions
  - [x] Add a widget test proving the denied-permission warning does not block creating a timer
  - [x] Add a widget test proving the denied-permission warning does not block core timer actions such as pause, resume, and remove
  - [x] Add a widget test proving the unavailable-permission warning does not block core timer use
- [x] Show a persistent warning in the main timer list view while notification permissions remain denied
- [x] Implement baseline Android local notification plumbing and manual verification
- [x] Implement baseline iOS local notification plumbing and manual verification
- [x] Add scheduling-specific Android setup required for timed notifications
- [x] Add any additional iOS setup required for timed notifications beyond the current baseline flow
  - [x] Assign the iOS notification-center delegate so scheduled alerts can still present correctly while the app is in the foreground
  - [x] Enable the Time Sensitive Notifications capability and mark milestone alerts as time-sensitive on iOS
- [x] Add Windows notification initialization settings, runtime validation, and packaging notes for desktop workstation deployment
  - [x] Keep stable Windows notification identity settings for the packaged app name, App User Model ID, and GUID
  - [x] Mark Windows milestone toasts as urgent and document the MSIX packaging requirement for lifecycle-correct notification behaviour
  - [x] Add a packaged-build runtime validation checklist for Windows workstation deployment
- [x] Add macOS notification initialization settings and runtime validation if macOS support is pursued
  - [x] Make the macOS notification initialization settings explicit in the notification service rather than relying on shared Darwin defaults implicitly
  - [x] Document the macOS runtime validation checklist and rollout caveats for supported desktop builds
- [x] Keep Linux and web out of the delivered notification scope because scheduled local notifications are not reliable enough there

---

## Critical: Safety Positioning And Onboarding

### Disclaimer
- [x] Add first-launch onboarding or disclaimer flow explaining that the app is a job aid and not an automated infusion controller
- [x] Make clear that the user remains responsible for clinical decisions, equipment checks, and active monitoring
- [x] Record disclaimer acceptance locally
- [x] Do not show the disclaimer again unless app data is cleared

### Safety Warnings
- [x] If notifications are denied or unavailable, clearly warn that background alerting will not function and timers must be monitored in-app
- [x] Keep that warning persistently visible in the main timer list until permissions are enabled

---

## High Priority: Input Validation And Editing Flows

### Numeric Validation
- [x] Validate all numeric inputs before creating or editing a timer
- [x] Reject empty, zero, negative, and non-numeric values
- [x] Show clear corrective error messages instead of silently coercing invalid input to `0.0`
- [x] Prevent invalid edits from overwriting an existing valid timer configuration

### Form Behavior
- [x] Decide whether timer title is required and enforce that decision consistently in the form
- [x] Use a modal bottom-sheet overlay for the add/edit infusion form instead of a centered dialog
- [x] Improve data-entry UX for mobile numeric input and validation feedback

---

## High Priority: Timer Semantics And Domain Correctness

### Reconfiguration Behavior
- [x] Verify and test that re-configuring a running timer preserves previously infused volume and recalculates only the remaining portion
- [x] Verify and test that re-configuring a paused timer preserves current progress and does not introduce elapsed-time drift

### Reset, Pause, Resume
- [x] Ensure pause freezes infusion progress until resumed
- [x] Ensure resume restarts from the current infused amount without losing progress
- [x] Ensure reset returns the timer to its initial state for that infusion lifecycle and clears accumulated progress
- [x] Add explicit tests for pause/resume/reset/edit sequences

---

## High Priority: Testing And Acceptance Coverage

### Automated Tests
- [x] Replace the default Flutter template widget test with tests that reflect the actual app behavior
- [x] Add unit tests for infusion duration and infused-volume calculations
- [x] Add unit tests for timer lifecycle transitions: start, pause, resume, reset, end, and restore
- [x] Add tests for persistence round-tripping and restore reconciliation
- [x] Add widget tests for add, edit, remove, validation errors, and empty-state behavior
- [x] Add widget tests for notification permission states and actions
- [x] Add tests covering notification milestone state once notifications are implemented

### Acceptance Checks
- [x] Ensure `flutter analyze` passes in `ivgo/`
- [x] Ensure `flutter test` passes in `ivgo/`

---

## Medium Priority: UI, Accessibility, And Product Fit

### Main List UX
- [x] Create visual on-boarding flow to guide the user to create and manage their first infusion timer
  - 7-page wizard with animated form fields, live preview, and notification permission request

#### Onboarding Wizard Implementation Plan

##### Phase 1: Extract `TimerCardBase` Shared Component
- [x] Create `lib/widgets/timer_card_base.dart` as shared visual foundation
  - Status badge styling (Running/Paused/Completed/Review) with colors and typography
  - Metric card design (volume, drop rate, time remaining)
  - Layout structure: badge row, metrics row, info row
  - Accepts `InfusionTimer` OR form data as input
  - No business logic, pure visual component
- [x] Refactor `lib/widgets/infusion_row.dart` to use `TimerCardBase`
  - Inherit from `TimerCardBase` for visual styling
  - Add action menu button and context menu logic on top

##### Phase 2: Create `FirstLaunchRepository`
- [x] Create `lib/repositories/first_launch_repository.dart`
  - Track whether onboarding wizard has been shown
  - Interface: `hasSeenOnboarding()` → bool, `setHasSeenOnboarding(bool)` → Future<void>
  - Use SharedPreferences, same pattern as `DisclaimerAcceptanceRepository`

##### Phase 3: Create `OnboardingWizard` Page
- [x] Create `lib/pages/onboarding_wizard.dart`
  - `PageView` with 5 pages + dot indicators
  - "Skip" button (top-right) dismisses to main list
  - "Back" / "Next" navigation (bottom)
  - Animated field focus on steps 2-4 (field pulses/glows briefly on enter)
  - Live preview card on step 5

##### Onboarding Wizard Pages

| # | Title | Content |
|---|-------|---------|
| 1 | Welcome | App icon, greeting, "Let's set up your first infusion" |
| 2 | Name Your Infusion | Title field with example, explanation text |
| 3 | Set Your Target | Volume input (ml), typical range guidance |
| 4 | Configure Flow Rate | Drop factor + flow rate fields, visual explanation |
| 5 | Stay Notified | Notification permission request, explains alerts work without if denied |
| 6 | That's it! | Live preview card with menu hint + "Next" |
| 7 | You're All Set! | "Create Infusion Timer" button to finish |

- [x] Implement welcome page (step 1)
  - Large app icon (120px)
  - Warm greeting text
  - "Next" button to proceed
- [x] Implement name step (step 2)
  - Title text field with placeholder example ("IV Infusion #1")
  - Explanation that title is optional but helpful
  - Field animation: brief pulse/glow on entry
- [x] Implement target volume step (step 3)
  - Volume input field (ml) with numeric keyboard
  - Guidance text showing typical volume ranges (e.g., 100-1000ml)
  - Field animation: brief pulse/glow on entry
- [x] Implement flow rate step (step 4)
  - Drop factor field (gtts/ml)
  - Flow rate field (gtts/min)
  - Visual explanation of gtts/min concept
  - Field animation: brief pulse/glow on entry
- [x] Implement notifications step (step 5)
  - Shows current notification permission status (granted/denied/not determined)
  - Icon changes based on status (notifications_active vs notifications_off_outlined)
  - Green confirmation message if granted
  - Red warning message if denied
  - "Enable Notifications" button if not yet determined, requests permissions on tap
  - Shows snackbar on successful permission grant
  - App works without permissions, just needs to stay open
- [x] Implement create step (step 6)
  - Live preview card using `TimerCardBase` that updates as user fills fields
  - Shows menu hint (⋮) on preview card
  - "Next" button to proceed
- [x] Implement menu options step (step 7)
  - Shows timer card with menu icon hint (⋮)
  - Lists available overflow menu options: Edit, Pause/Resume, Remove
  - "Create Infusion Timer" button that creates timer and navigates to main list
  - "Back" button to return to previous step

##### Phase 4: Update App Startup Gate
- [x] Modify `lib/main.dart` `_StartupGate` widget
  - Flow: disclaimer check → onboarding check → main list
  - New flow:
    1. Has user accepted disclaimer? → No: show `DisclaimerPage`
    2. Has seen onboarding? → Yes: show `InfusionListPage`
    3. Has timers? → Yes: show `InfusionListPage` (user is returning)
    4. Otherwise: show `OnboardingWizard`

##### Phase 5: Enhance Empty State
- [x] Modify empty state in `lib/pages/infusion_list_page.dart`
  - Add "Get Started" button that re-opens wizard
  - Add explanatory text: "Create your first infusion timer"
  - Only shown if user has already completed wizard (skipped or finished)
- [x] Add settings page accessible from app bar gear icon
  - Replay Walkthrough option to reset onboarding state
  - Dark Mode toggle (disabled with "coming soon" note)

##### Phase 6: Add Tests
- [x] Create `test/onboarding_wizard_test.dart`
  - Wizard renders all 6 pages
  - Skip dismisses to main list
  - Next/Back navigation works
  - Form validation prevents empty/invalid submissions
  - "Create Timer" button is present on final step
  - Live preview updates on step 5
  - Menu page shows overflow menu options
- [x] Ensure `flutter test` passes for onboarding tests

##### Phase 7: Verification
- [x] Run `flutter analyze` and address any issues
- [x] Run `flutter test` for onboarding wizard tests - all 7 tests pass
- [x] Improve at-a-glance status presentation for running, paused, ended, and recovered-overdue timers
- [x] Add explicit visual treatment for timers that completed while the app was not actively notifying the user

### Accessibility
- [ ] Verify text contrast and progress-indicator contrast
- [ ] Ensure controls have sufficiently large touch targets for quick clinical use
- [ ] Verify support for larger text sizes and layout resilience
- [ ] Support for Dark mode: fixed light, fixed dark or device default setting.

### Settings
- [x] Add settings page accessible from main list app bar
- [x] Replay Walkthrough option to reset onboarding state and show wizard on next launch
- [x] Dark Mode toggle (disabled with "coming soon" note until implemented)

### Scope And Platform Fit
- [x] Remove the Flutter web target from the project so unsupported browser deployment is not advertised by the scaffold
- [x] Treat Android, iOS, and Windows as the supported product scope, with macOS optional after notification validation
- [x] Remove Linux scaffolding from the Flutter project so unsupported desktop deployment is not advertised by the scaffold

---

## Medium Priority: Targeted Technical Debt

### Service Boundaries
- [x] Extract persistence logic out of the page widget into a small repository or storage service around `shared_preferences`
- [x] Introduce a notification service rather than coupling notification behavior directly into UI code
- [ ] Introduce a small lifecycle coordinator or equivalent to own restore, reconciliation, and notification rescheduling behavior

### Domain Model Cleanup
- [ ] Reduce reliance on `late` and nullable timer fields where clearer defaults or explicit state would make behavior safer
- [ ] Make persisted timer data structures easier to reason about and version if the model evolves
- [ ] Keep flow-calculation rules documented close to the domain logic and covered by tests rather than comments alone

---

## Low Priority
### UI Tweaks
- [ ] Fix up app icon
- [ ] Fix up app splash screen

### DevOps
- [ ] Implement basic CI/CD for this repository to validate quality of merges into develop and form the basis of good PR's.
- [ ] Create full manual test plan

---

## Summary Of Gaps

| Category | Status | Priority |
|----------|--------|----------|
| Timer lifecycle and restore | Core lifecycle, recovered-overdue highlighting, and acknowledgement flow implemented | Critical |
| Persistence reliability | Core persistence and restore flow implemented; notification-related recovery still pending | Critical |
| Notifications | Permission flow, milestone scheduling, lifecycle-aware cancellation, and recovered-timer handling implemented; cleanup and platform validation still pending | Critical |
| Disclaimer and safety warnings | Implemented | Critical |
| Validation | Basic create/edit validation implemented; mobile UX polish still pending | High |
| Testing | Core timer, notification milestone, and broad widget coverage added; some broader UI and accessibility coverage still pending | High |
| UI and accessibility refinements | Partially implemented | Medium |
| Technical debt and service boundaries | Growing and worth addressing before notifications land | Medium |

---

*Updated after code review and follow-up implementation work on timer lifecycle, persistence, restore, notification milestones, and the bottom-sheet form flow.*
