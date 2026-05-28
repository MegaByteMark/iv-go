# Filter Timers — Implementation TODOs

## Objective
Add a filter icon to the header bar that opens a bottom sheet with filtering options: status (All / Running / Paused / Completed) and name search, with explicit Apply / Clear buttons.

---

## Files to modify

- `ivgo/lib/pages/infusion_list_controller.dart`
- `ivgo/lib/pages/infusion_list_page.dart`
- `ivgo/lib/pages/onboarding_wizard.dart`

---

## Step 1 — Controller: Filter types and state

**File:** `ivgo/lib/pages/infusion_list_controller.dart`

- [x] Define `TimerStatusFilter` enum: `all`, `running`, `paused`, `completed`
- [x] Define `TimerFilter` data/record class with:
  - `TimerStatusFilter statusFilter` (default: `TimerStatusFilter.all`)
  - `String searchQuery` (default: `''`)
  - `get bool get isActive` that returns `true` when status filter is not "all" or search query is not empty
- [x] Add `Signal<TimerFilter> _activeFilter` with default value `TimerFilter()`
- [x] Add a `computed` signal `filteredTimers` derived from `_infusionTimers`:
  - If `statusFilter != all` → filter by the corresponding predicate (`isRunning`, `isPaused`, `isEnded`)
  - If `searchQuery.isNotEmpty` → filter by `title.toLowerCase().contains(searchQuery.toLowerCase())`
  - Both filters combine (AND logic)
  - Apply existing sort on the filtered result
- [ ] Expose:
  - `ReadonlySignal<List<InfusionTimer>> get filteredTimers`
  - `ReadonlySignal<TimerFilter> get activeFilter`
  - `void setFilter(TimerFilter filter)`
  - `void resetFilter()`
- [ ] Keep `infusionTimers` as the unfiltered master list (still used by clear-completed count and `saveState`)

---

## Step 2 — Page: Filter icon in AppBar

**File:** `ivgo/lib/pages/infusion_list_page.dart`

- [ ] Add a filter `IconButton` as the **first** item in `actions` (left of settings gear)
  - Icon: `Icons.filter_alt_outlined` when filter is inactive, `Icons.filter_alt` (filled) when active
  - Tooltip: "Filter Timers"
  - `onPressed` → `_showFilterSheet()`
- [ ] Use `Watch` to reactively switch the icon based on `_controller.activeFilter.value.isActive`

---

## Step 3 — Page: Filter bottom sheet

**File:** `ivgo/lib/pages/infusion_list_page.dart`

- [ ] Create `_showFilterSheet()` method using `showModalBottomSheet`:
  - `isScrollControlled: true`, `useSafeArea: true`, `showDragHandle: true`
  - Pre-populate from `_controller.activeFilter.value` on open
- [ ] **Title**: Text("Filter Timers") using headline style
- [ ] **Status filter chips**: Wrap row of `ChoiceChip` widgets:
  - Options: All, Running, Paused, Completed
  - Only one selected at a time (radio behavior)
- [ ] **Search text field**: `TextFormField` or `TextField` with:
  - `Icons.search` prefix icon
  - Label/hint: "Search by name"
  - Pre-populated with current `searchQuery`
  - `textInputAction: TextInputAction.done`
- [ ] **Two action buttons** at the bottom:
  - **"Clear Filters"** — `TextButton`, visible **only** when the current filter (pre-populated) is active. On tap: resets to `TimerFilter()`, calls `_controller.resetFilter()`, closes sheet.
  - **"Apply Filters"** — `FilledButton`. On tap: reads the selected chip + text field, calls `_controller.setFilter(...)`, closes sheet.
- [ ] Both buttons and the drag handle are the only ways to dismiss the sheet (no tap-outside-to-dismiss)

---

## Step 4 — Page: Consume filtered list

**File:** `ivgo/lib/pages/infusion_list_page.dart`

- [ ] In the body's `Watch`, change from `_controller.infusionTimers.value` to `_controller.filteredTimers.value` for the list rendering
- [ ] Keep `completedTimerCount` in the AppBar reading from the unfiltered `_controller.infusionTimers.value` (clear-completed should count all completed timers, not just visible ones)
- [ ] **Update empty states** in the body:
  - If `_controller.infusionTimers.value.isEmpty` → show existing "No active infusions" empty state (no timers exist at all)
  - Else if `_controller.filteredTimers.value.isEmpty` AND `_controller.infusionTimers.value.isNotEmpty` → new empty state:
    - Message: "No timers match your filter"
    - "Clear Filters" `TextButton` that calls `_controller.resetFilter()`
    - Existing empty state stays the same

---

## Step 5 — Onboarding: Mention filter feature

**File:** `ivgo/lib/pages/onboarding_wizard.dart`

- [ ] In `_buildMenuPage()` ("You're All Set!"), add a second `WizardInfoText` below the existing menu hint:
  - `WizardInfoText(label: 'Use the filter icon to narrow down your timer list by status or name')`
- [ ] No new page or structural changes needed

---

## Step 6 — Tests

### Controller unit tests (`ivgo/test/infusion_list_controller_test.dart`)
- [ ] Filter by "running" returns only running timers
- [ ] Filter by "paused" returns only paused timers
- [ ] Filter by "completed" returns only ended/recoveredOverdue timers
- [ ] Filter by "all" returns all timers (no-op)
- [ ] Search by name (case-insensitive) returns matching timers
- [ ] Combined status + name filter works (AND logic)
- [ ] Filtering does not mutate the unfiltered `infusionTimers` signal
- [ ] `resetFilter()` restores full unfiltered list

### Widget tests (`ivgo/test/infusion_list_page_test.dart`)
- [ ] Tapping filter icon opens the bottom sheet
- [ ] Selecting a status chip and tapping Apply updates the list
- [ ] Tapping Clear Filters resets the list
- [ ] Empty state shows "No timers match your filter" when filter active but no results
