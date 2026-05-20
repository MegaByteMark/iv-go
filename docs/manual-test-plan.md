# Manual Test Plan — iv-go

## Instructions

- For each test, mark `P` (pass), `F` (fail), or `N/A` in the relevant platform column.
- Use a **stopwatch** for any step that involves timing.
- Attach a screenshot for any `F` and file an issue.
- Build variant: `___`

---

## 1. First Launch & Disclaimer

| # | Step | Expected | iOS | Android | Windows | macOS |
|---|------|----------|----|---------|---------|-------|
| 1.1 | Launch app for the first time (fresh install, no data) | Disclaimer page appears with app name, safety warning, and an accept button | | | | |
| 1.2 | Tap "Accept" | Disclaimer is dismissed, onboarding wizard begins | | | | |
| 1.3 | Force-kill app and relaunch | Disclaimer is **not** shown again | | | | |
| 1.4 | Clear app data / reinstall, launch again | Disclaimer appears again | | | | |

---

## 2. Onboarding Wizard

| # | Step | Expected | iOS | Android | Windows | macOS |
|---|------|----------|----|---------|---------|-------|
| 2.1 | After accepting disclaimer, the 7-page wizard starts | Welcome page (step 1) is shown with app icon and greeting | | | | |
| 2.2 | Tap "Next" | Step 2 (Name Your Infusion) — title field with placeholder | | | | |
| 2.3 | Enter a title, tap "Next" | Step 3 (Set Your Target) — volume input (ml) | | | | |
| 2.4 | Enter 500, tap "Next" | Step 4 (Configure Flow Rate) — drop factor + flow rate fields | | | | |
| 2.5 | Set drop factor 20, flow rate 60, tap "Next" | Step 5 (Stay Notified) — permission status shown | | | | |
| 2.6 | Tap "Enable Notifications" (if not determined) | System permission dialog appears | | | | |
| 2.7 | Grant or deny permission | Step updates accordingly, tap "Next" | | | | |
| 2.8 | Step 6 (That's it!) — live preview card reflects entered data | Preview shows title, volume (500ml), drop factor (20 gtts/ml), flow rate (60 gtts/min), duration (2000s = 33:20) | | | | |
| 2.9 | Tap "Next" | Step 7 (You're All Set!) — menu options listed | | | | |
| 2.10 | Tap "Create Infusion Timer" | Timer created, navigated to main list showing the timer | | | | |
| 2.11 | Full reset: Settings → Replay Walkthrough, restart app | Wizard shows again on next launch | | | | |

### Navigation

| # | Step | Expected | iOS | Android | Windows | macOS |
|---|------|----------|----|---------|---------|-------|
| 2.12 | On any step except first, tap "Back" | Returns to previous step, data preserved | | | | |
| 2.13 | On any step, tap "Skip" (top-right) | Wizard dismissed, main list shown (empty state) | | | | |
| 2.14 | "Back" is disabled on step 1 | Button is greyed out or hidden | | | | |

### Validation

| # | Step | Expected | iOS | Android | Windows | macOS |
|---|------|----------|----|---------|---------|-------|
| 2.15 | Leave title empty on step 2, tap "Next" | Allowed (title is optional) | | | | |
| 2.16 | Leave volume empty / enter "0" / enter "-5" on step 3 | Error message, cannot proceed | | | | |
| 2.17 | Leave drop factor or flow rate empty / zero / negative on step 4 | Error message, cannot proceed | | | | |

---

## 3. Timer Management — List & Actions

### Empty State

| # | Step | Expected | iOS | Android | Windows | macOS |
|---|------|----------|----|---------|---------|-------|
| 3.1 | Fresh install with no timers | Empty state message + "Get Started" button shown | | | | |
| 3.2 | Tap "Get Started" | Wizard reopens | | | | |

### Create Timer (manual add) — Calculation Verification

**Formula:** duration (seconds) = (volume_ml × drop_factor_gtts_per_ml) / (flow_rate_gtts_per_min / 60)

| # | Step | Expected | iOS | Android | Windows | macOS |
|---|------|----------|----|---------|---------|-------|
| 3.3 | Tap **+** FAB | Bottom sheet opens with title, volume, drop factor, flow rate fields | | | | |
| 3.4a | Create: **100ml, 20 gtts/ml, 60 gtts/min** | Duration = (100×20)/(60/60) = **2000s (33:20)**. Timer shows 33:20 countdown | | | | |
| 3.4b | Create: **50ml, 20 gtts/ml, 100 gtts/min** | Duration = (50×20)/(100/60) = **600s (10:00)**. Timer shows 10:00 | | | | |
| 3.4c | Create: **10ml, 15 gtts/ml, 45 gtts/min** | Duration = (10×15)/(45/60) = **200s (3:20)**. Timer shows 3:20 | | | | |
| 3.4d | Create: **0ml, any rate** | Duration = **0s (0:00)**. Timer immediately shows "Completed" | | | | |

### Validation (create/edit form)

| # | Step | Expected | iOS | Android | Windows | macOS |
|---|------|----------|----|---------|---------|-------|
| 3.5 | Tap Create with empty title | Allowed | | | | |
| 3.6 | Tap Create with empty volume | Error: "Volume is required" | | | | |
| 3.7 | Tap Create with volume "0" | Error: "Volume must be greater than 0" | | | | |
| 3.8 | Tap Create with negative volume | Error | | | | |
| 3.9 | Tap Create with non-numeric volume ("abc") | Filtered or rejected | | | | |
| 3.10 | Same validation for drop factor and flow rate | Equivalent errors | | | | |

### Running Timer Display & Live Countdown

Baseline test: **100ml, 20 gtts/ml, 60 gtts/min** → 2000s (33:20), 1 gtts/min = 1ml/min.

| # | Step | Expected | iOS | Android | Windows | macOS |
|---|------|----------|----|---------|---------|-------|
| 3.11a | Create the baseline timer | Shows green "Running" badge, countdown at **33:20** | | | | |
| 3.11b | Wait **60s** with stopwatch | Countdown reads **32:20**, infused volume = (60s×60 gtts/min)/(20 gtts/ml×60) = **3.0ml** | | | | |
| 3.11c | Wait another **60s** (120s total) | Countdown reads **31:20**, infused volume = (120×60)/(20×60) = **6.0ml** | | | | |
| 3.11d | After **2000s** total | Countdown reaches **0:00**, badge shows "Completed", infused = **100ml** | | | | |

### Pause/Resume — Timing Verification

| # | Step | Expected | iOS | Android | Windows | macOS |
|---|------|----------|----|---------|---------|-------|
| 3.12a | Run baseline timer **60s**, then tap Pause (⋮) | Badge → yellow "Paused". Countdown frozen at **32:20**. Infused = **3.0ml** | | | | |
| 3.12b | Wait **30s** with stopwatch | Countdown still **32:20**, volume still **3.0ml** (no drift) | | | | |
| 3.12c | Tap Resume, wait **60s** | Countdown at **31:20**, infused = (120s run×60)/(20×60) = **6.0ml** | | | | |
| 3.12d | Pause → 30s → resume → 30s → pause → 30s → resume (3 cycles) | Each resume picks up exactly where pause left off, no cumulative drift | | | | |
| 3.12e | Overflow menu on completed timer | Shows "Reset" and "Remove" (not Pause/Resume) | | | | |
| 3.12f | Overflow menu on paused timer | Shows "Resume", "Edit", "Remove" | | | | |

### Edit Timer — Calculation Verification

| # | Step | Expected | iOS | Android | Windows | macOS |
|---|------|----------|----|---------|---------|-------|
| 3.13a | Create: **100ml, 20 gtts/ml, 60 gtts/min** → run **500s** | At 500s: infused = **25ml**, remaining = 2000−500 = **1500s (25:00)** | | | | |
| 3.13b | Edit **while running**: change volume 100→**80ml** | Infused **25ml** preserved. New duration = (80×20)/(60/60) = **1600s**. Remaining = 1600−500 = **1100s (18:20)** | | | | |
| 3.13c | Create: **100ml, 20 gtts/ml, 60 gtts/min** → run **300s** → pause | At pause: infused = **15ml**, remaining = **1700s (28:20)** | | | | |
| 3.13d | Edit **while paused**: drop factor 20→**15 gtts/ml** | Infused **15ml** preserved. New duration = (100×15)/(60/60) = **1500s**. Remaining = 1500−300 = **1200s (20:00)**. Timer still paused at **20:00** | | | | |
| 3.13e | Edit — provide invalid values, tap Save | Form shows error, timer unchanged | | | | |
| 3.13f | Edit — change title only | Title updates, timer state unchanged | | | | |

### Reset — Verification

| # | Step | Expected | iOS | Android | Windows | macOS |
|---|------|----------|----|---------|---------|-------|
| 3.14a | Timer at 15ml infused → tap Reset | Infused = **0.0ml**, countdown back to full **33:20** | | | | |
| 3.14b | Completed timer → Reset | Same as above — starts fresh | | | | |

### Remove Timer

| # | Step | Expected | iOS | Android | Windows | macOS |
|---|------|----------|----|---------|---------|-------|
| 3.15 | Remove a single timer — confirm | Timer disappears from list | | | | |
| 3.16 | Remove the last timer | Empty state appears | | | | |

### Clear Completed

| # | Step | Expected | iOS | Android | Windows | macOS |
|---|------|----------|----|---------|---------|-------|
| 3.17 | Have 3 timers: 2 completed, 1 running | App bar shows "Clear Completed" action | | | | |
| 3.18 | Tap "Clear Completed" | Confirmation dialog appears | | | | |
| 3.19 | Confirm | Completed timers removed, running timer remains | | | | |
| 3.20 | No completed timers exist | "Clear Completed" action hidden from app bar | | | | |

---

## 4. Timer Lifecycle — State Transitions

All tests use baseline: **100ml, 20 gtts/ml, 60 gtts/min** (33:20).

| # | Step | Expected | iOS | Android | Windows | macOS |
|---|------|----------|----|---------|---------|-------|
| 4.1 | Create timer → runs automatically | Countdown decrements every second. After 10s: **33:10** | | | | |
| 4.2 | Pause at **33:00** (200s elapsed) | Freezes at **33:00**. After 60s paused → still **33:00** | | | | |
| 4.3 | Resume at **33:00**, run 100s | Countdown = **31:20** (200+100=300s elapsed, 2000−300=1700s=28:20... wait: 33:00 = 1980s remaining → 2000−1980=20s elapsed at pause. Resume 100s → 120s total. 2000−120=1880s = **31:20**) | | | | |
| 4.4 | Pause → 30s → resume → repeat 3× | Each resume picks up exactly where pause left off. No drift | | | | |
| 4.5 | Reset running timer at 15ml | Volume → **0.0ml**, countdown → full **33:20** | | | | |
| 4.6 | Reset paused timer | Same as 4.5 | | | | |
| 4.7 | Reset completed timer | Timer restarts from beginning | | | | |
| 4.8 | Let timer reach 0:00 | Badge → "Completed", timer stops at **0:00**, infused = **100ml** | | | | |

---

## 5. Notifications

### Permission Flow

| # | Step | Expected | iOS | Android | Windows | macOS |
|---|------|----------|----|---------|---------|-------|
| 5.1 | App bar → request notification permission | System prompt appears | | | | |
| 5.2 | Grant permission | Snackbar confirms, banner hidden | | | | |
| 5.3 | Deny permission | Snackbar shows denied message, warning banner appears in main list | | | | |
| 5.4 | After denial, banner remains visible | Persistent warning that background alerts won't work | | | | |
| 5.5 | Banner does not block timer actions | Can still create, pause, resume, remove timers | | | | |

### Milestone Scheduling — Timing Verification

Test timer: **500ml, 20 gtts/ml, 60 gtts/min** → duration = (500×20)/(60/60) = **10000s (2h 46m 40s)**

| # | Step | Expected | iOS | Android | Windows | macOS |
|---|------|----------|----|---------|---------|-------|
| 5.6 | Create the 10000s timer | "Last 10 minutes" milestone scheduled at 10000−600 = **9400s** into the timer (2h 36m 40s) | | | | |
| 5.7 | "Last 1 minute" milestone scheduled at 10000−60 = **9940s** (2h 45m 40s) | | | | | |
| 5.8 | "Ended +10 minutes" milestone scheduled at 10000+600 = **10600s** (2h 56m 40s) | | | | | |
| 5.9 | Fast-forward / wait until timer reaches the 10-min window (600s remaining) | "Last 10 minutes" notification fires. Body includes timer name and "10 minutes remaining" | | | | |
| 5.10 | Wait until timer reaches the 1-min window (60s remaining) | "Last 1 minute" notification fires | | | | |
| 5.11 | Timer reaches 0:00, wait 10min | "Ended 10+ minutes ago" notification fires (once per lifecycle) | | | | |
| 5.12 | Pause the timer at 500s remaining | Pending milestone notifications for that timer **cancelled** | | | | |
| 5.13 | Resume at 500s remaining | Milestones rescheduled: last-10min already passed → **skipped**, last-1min re-fires | | | | |
| 5.14 | Edit running timer (change volume) | Notifications rescheduled with new timing | | | | |
| 5.15 | Remove a timer | All pending notifications for that timer cancelled | | | | |
| 5.16 | Reset a timer | Notifications rescheduled for new lifecycle | | | | |

### Duplicate Prevention

| # | Step | Expected | iOS | Android | Windows | macOS |
|---|------|----------|----|---------|---------|-------|
| 5.17 | Let "last 1 minute" fire → timer completes → reset → let it reach last-1-min again | Fires again **because it's a new lifecycle** | | | | |
| 5.18 | Let "last 10 minute" fire, pause, then resume before 10-min window in same lifecycle | Does **NOT** re-fire (already handled this lifecycle) | | | | |
| 5.19 | Kill app after "last 1 minute" fired → reopen | Milestone not re-shown (persisted `handledMilestones` prevents it) | | | | |

---

## 6. Persistence & Restore — Timing Verification

Baseline: **100ml, 20 gtts/ml, 60 gtts/min** (33:20). 1s run = 0.05ml infused.

| # | Step | Expected | iOS | Android | Windows | macOS |
|---|------|----------|----|---------|---------|-------|
| 6.1 | Create timer → kill app → reopen | Timer persists with same values and state | | | | |
| 6.2 | Run **120s** (to **31:20**, **6ml**) → pause → kill → reopen after **60s** | Still **paused** at **31:20**, **6ml**. Does NOT auto-resume. No time added | | | | |
| 6.3 | Run **120s** (to **31:20**, **6ml**) → keep running → kill → reopen after **exactly 60s** | Timer reads **30:20**, infused = (180s×60)/(20×60) = **9ml** | | | | |
| 6.4 | Complete timer (0:00) → kill → reopen | Shows "Completed" at **0:00**, **100ml** infused | | | | |
| 6.5 | Remove all timers → kill → reopen | Empty state shown | | | | |
| 6.6 | Run **500s** → kill for **2000s** (past end) → reopen | Shows **"Recovered Overdue"** with warning styling. Infused = **100ml** (capped). Overdue by time_since_end | | | | |
| 6.7 | Tap acknowledge on recovered-overdue | Warning cleared, becomes normal "Completed" | | | | |
| 6.8 | Ack'ed timer → kill → reopen | Stays normal "Completed" (ack persists) | | | | |

---

## 7. Settings

| # | Step | Expected | iOS | Android | Windows | macOS |
|---|------|----------|----|---------|---------|-------|
| 7.1 | Tap gear icon in app bar | Settings page opens | | | | |
| 7.2 | "Replay Walkthrough" visible | Tap → onboarding state reset | | | | |
| 7.3 | "Reset Disclaimer" visible | Tap → disclaimer acceptance reset | | | | |
| 7.4 | Theme mode: Light / Dark / System | Theme changes immediately | | | | |
| 7.5 | Change theme → kill → reopen | Theme preference persists | | | | |
| 7.6 | "Replay Walkthrough" → restart app | Wizard shows before main list | | | | |
| 7.7 | "Reset Disclaimer" → restart app | Disclaimer appears again | | | | |

---

## 8. Dark Mode

| # | Step | Expected | iOS | Android | Windows | macOS |
|---|------|----------|----|---------|---------|-------|
| 8.1 | Settings → set theme to Dark | All screens use dark palette, text readable | | | | |
| 8.2 | Timer card text, badges, progress indicators visible | Sufficient contrast | | | | |
| 8.3 | Settings → set theme to Light | Returns to light palette | | | | |
| 8.4 | Settings → set theme to System | Follows OS dark/light setting | | | | |
| 8.5 | Change OS dark mode while app is running | Theme updates live (System mode only) | | | | |

---

## 9. Accessibility

| # | Step | Expected | iOS | Android | Windows | macOS |
|---|------|----------|----|---------|---------|-------|
| 9.1 | Increase system font size to largest | App layout adapts, no truncated text | | | | |
| 9.2 | All touch targets ≥ 48×48dp | Buttons, menu items, FAB are tappable | | | | |
| 9.3 | Text contrast ratio ≥ 4.5:1 for normal text | Badges, body text, labels are readable | | | | |

---

## 10. Platform-Specific Checks

### Android

| # | Step | Expected | Android |
|---|------|----------|---------|
| 10.1 | Build: `flutter build apk --debug` | Builds without errors | |
| 10.2 | Install APK on device/emulator (API 33+) | App launches | |
| 10.3 | Request exact alarm permission from app bar | System settings or snackbar shown | |
| 10.4 | Run timer in background → milestone fires | Notification in drawer, tap opens app | |

### iOS

| # | Step | Expected | iOS |
|---|------|----------|-----|
| 10.5 | Build & run on simulator or device | App launches | |
| 10.6 | Notification permission request | System prompt | |
| 10.7 | Schedule notification → background → wait | Milestone alert arrives | |
| 10.8 | Milestone fires while app is foreground | Alert presented via UNDelegate | |
| 10.9 | Tap notification | App opens to main list | |

### Windows

| # | Step | Expected | Windows |
|---|------|----------|---------|
| 10.10 | Build: `flutter build windows` | Builds without errors | |
| 10.11 | Run packaged app (MSIX) | App launches | |
| 10.12 | Milestone toasts appear | Marked urgent | |

### macOS

| # | Step | Expected | macOS |
|---|------|----------|-------|
| 10.13 | Build & run | App launches | |
| 10.14 | Notification permission request | System prompt | |
| 10.15 | Foreground notifications | Alerts display correctly | |

---

## 11. Edge Cases & Error Handling

| # | Step | Expected | iOS | Android | Windows | macOS |
|---|------|----------|----|---------|---------|-------|
| 11.1 | Create: **1ml, 60 gtts/ml, 120 gtts/min** | Duration = (1×60)/(120/60) = **30s (0:30)** | | | | |
| 11.2 | Create: **10000ml, 10 gtts/ml, 10 gtts/min** | Duration = (10000×10)/(10/60) = **600000s (166h 40m)**. Countdown shows correct value | | | | |
| 11.3 | Rapidly pause/resume 10× in a row | No crash, state consistent after each toggle | | | | |
| 11.4 | Create 20 timers with various durations | All render in scrollable list. Tap each overflow — no lag | | | | |
| 11.5 | Edit timer with 3s remaining | Edit applies cleanly or form accepts — either is acceptable | | | | |
| 11.6 | Deny notifications → create/run/pause/resume/remove 5 timers | No crashes. Core timer works without permissions | | | | |
| 11.7 | Clear app data while timers exist | Next launch: disclaimer → empty state | | | | |
| 11.8 | Complete → clear completed → verify no re-fire | After-end milestone does not re-fire for cleared timers | | | | |

---

## Summary

| Section | iOS Pass | iOS Fail | Android Pass | Android Fail | Windows Pass | Windows Fail | macOS Pass | macOS Fail |
|---------|----------|----------|--------------|--------------|--------------|--------------|------------|------------|
| 1. First Launch & Disclaimer | | | | | | | | |
| 2. Onboarding Wizard | | | | | | | | |
| 3. Timer Management | | | | | | | | |
| 4. Timer Lifecycle | | | | | | | | |
| 5. Notifications | | | | | | | | |
| 6. Persistence & Restore | | | | | | | | |
| 7. Settings | | | | | | | | |
| 8. Dark Mode | | | | | | | | |
| 9. Accessibility | | | | | | | | |
| 10. Platform-Specific | | | | | | | | |
| 11. Edge Cases | | | | | | | | |
| **Total** | | | | | | | | |

---

*Build version: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_*
*Date: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_*
*Tester: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_*
