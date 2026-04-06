# TODO List - iv-go Application

Based on review of `copilot-requirements.md` vs current codebase implementation in `ivgo/`.

---

## Critical: Timer Lifecycle, Persistence, And Restore

### Timer State Model
- [x] Replace the current simple running/stopped model with explicit timer states such as running, paused, and ended
- [x] Separate pause/resume semantics from completion semantics so a finished infusion is not treated the same as a manually paused infusion
- [x] Fix the timer lifecycle so pausing, resuming, resetting, and completion all work reliably after a timer has been cancelled once
- [ ] Add explicit recovered-overdue state and UI behavior for timers discovered as completed after app/device downtime

### Persistence Reliability
- [x] Redesign persisted infusion history into a JSON-safe structure
- [x] Save timer state after every meaningful mutation, including add, edit, pause, resume, reset, and remove
- [x] Persist and restore enough lifecycle metadata to correctly distinguish paused, running, and completed timers
- [x] Ensure async restore triggers a UI rebuild and reinitializes any required refresh behavior after load completes

### Restore And Reconciliation
- [x] Rework restore logic so paused timers do not auto-resume when the app is reopened
- [x] Rework restore logic so elapsed real time is only applied to periods when the timer was actually running
- [x] If a timer should have finished while the app was closed or the device was unavailable, restore it as ended rather than continuing it
- [ ] Clearly highlight timers that completed while the device was unavailable so the user can review them on next launch
- [ ] Decide and implement how overdue recovered timers are acknowledged or cleared from the highlighted state

---

## Critical: Notifications

### Required Notifications
- [ ] Implement last 10 minutes milestone notification
- [ ] Implement last 1 minute milestone notification
- [ ] Implement "ended and stopped for more than 10 minutes" notification that fires once per timer lifecycle
- [ ] Track which milestone notifications have already fired for the current timer lifecycle
- [ ] If a timer resumes or restores inside a milestone window, issue the milestone notification unless it already fired in that lifecycle

### Notification Cancellation And Recovery
- [ ] Cancel or clear notifications when the user pauses, edits, resets, or removes a timer
- [ ] Ensure duplicate notifications are prevented within a single timer lifecycle
- [ ] Define and implement notification behavior for timers recovered as already ended after app relaunch

### Notification Permissions And Platform Work
- [ ] Request notification permissions at the appropriate point in the app flow
- [ ] Handle denied or unavailable permissions clearly without blocking core timer use
- [ ] Show a persistent warning in the main timer list view while notification permissions remain denied
- [ ] Implement Android notification behavior
- [ ] Implement iOS notification behavior

---

## Critical: Safety Positioning And Onboarding

### Disclaimer
- [ ] Add first-launch onboarding or disclaimer flow explaining that the app is a job aid and not an automated infusion controller
- [ ] Make clear that the user remains responsible for clinical decisions, equipment checks, and active monitoring
- [ ] Record disclaimer acceptance locally
- [ ] Do not show the disclaimer again unless app data is cleared

### Safety Warnings
- [ ] If notifications are denied or unavailable, clearly warn that background alerting will not function and timers must be monitored in-app
- [ ] Keep that warning persistently visible in the main timer list until permissions are enabled

---

## High Priority: Input Validation And Editing Flows

### Numeric Validation
- [x] Validate all numeric inputs before creating or editing a timer
- [x] Reject empty, zero, negative, and non-numeric values
- [x] Show clear corrective error messages instead of silently coercing invalid input to `0.0`
- [x] Prevent invalid edits from overwriting an existing valid timer configuration

### Form Behavior
- [x] Decide whether timer title is required and enforce that decision consistently in the form
- [ ] Improve data-entry UX for mobile numeric input and validation feedback

---

## High Priority: Timer Semantics And Domain Correctness

### Reconfiguration Behavior
- [x] Verify and test that re-configuring a running timer preserves previously infused volume and recalculates only the remaining portion
- [ ] Verify and test that re-configuring a paused timer preserves current progress and does not introduce elapsed-time drift

### Reset, Pause, Resume
- [x] Ensure pause freezes infusion progress until resumed
- [x] Ensure resume restarts from the current infused amount without losing progress
- [x] Ensure reset returns the timer to its initial state for that infusion lifecycle and clears accumulated progress
- [x] Add explicit tests for pause/resume/reset/edit sequences

---

## High Priority: Testing And Acceptance Coverage

### Automated Tests
- [x] Replace the default Flutter template widget test with tests that reflect the actual app behavior
- [ ] Add unit tests for infusion duration and infused-volume calculations
- [x] Add unit tests for timer lifecycle transitions: start, pause, resume, reset, end, and restore
- [x] Add tests for persistence round-tripping and restore reconciliation
- [ ] Add widget tests for add, edit, remove, validation errors, and empty-state behavior
- [ ] Add tests covering notification milestone state once notifications are implemented

### Acceptance Checks
- [x] Ensure `flutter analyze` passes in `ivgo/`
- [x] Ensure `flutter test` passes in `ivgo/`

---

## Medium Priority: UI, Accessibility, And Product Fit

### Main List UX
- [ ] Expand the empty state to guide the user to create their first infusion timer
- [ ] Improve at-a-glance status presentation for running, paused, ended, and recovered-overdue timers
- [ ] Add explicit visual treatment for timers that completed while the app was not actively notifying the user

### Accessibility
- [ ] Verify text contrast and progress-indicator contrast
- [ ] Ensure controls have sufficiently large touch targets for quick clinical use
- [ ] Verify support for larger text sizes and layout resilience

### Scope And Platform Fit
- [ ] Treat Android and iOS as the delivered product scope and avoid prioritizing unsupported desktop or web targets unless explicitly requested

---

## Medium Priority: Targeted Technical Debt

### Service Boundaries
- [ ] Extract persistence logic out of the page widget into a small repository or storage service around `shared_preferences`
- [ ] Introduce a notification service rather than coupling notification behavior directly into UI code
- [ ] Introduce a small lifecycle coordinator or equivalent to own restore, reconciliation, and notification rescheduling behavior

### Domain Model Cleanup
- [ ] Reduce reliance on `late` and nullable timer fields where clearer defaults or explicit state would make behavior safer
- [ ] Make persisted timer data structures easier to reason about and version if the model evolves
- [ ] Keep flow-calculation rules documented close to the domain logic and covered by tests rather than comments alone

---

## Summary Of Gaps

| Category | Status | Priority |
|----------|--------|----------|
| Timer lifecycle and restore | Core lifecycle fixed; recovered-overdue UX still pending | Critical |
| Persistence reliability | Core persistence and restore flow implemented; notification-related recovery still pending | Critical |
| Notifications | Not implemented | Critical |
| Disclaimer and safety warnings | Not implemented | Critical |
| Validation | Basic create/edit validation implemented; mobile UX polish still pending | High |
| Testing | Core timer and validation coverage added; broader UI coverage still pending | High |
| UI and accessibility refinements | Partially implemented | Medium |
| Technical debt and service boundaries | Growing and worth addressing before notifications land | Medium |

---

*Updated after code review and follow-up implementation work on timer lifecycle, persistence, restore, and validation.*
