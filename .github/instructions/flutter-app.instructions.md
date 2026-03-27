---
description: "Use when editing Dart or Flutter code in the IVGo app, including UI, timer logic, persistence, and tests. Covers app structure, validation, and timer-state expectations."
applyTo:
  - "ivgo/lib/**/*.dart"
  - "ivgo/test/**/*.dart"
---

# Flutter App Guidance

- Keep changes local to the affected widget, model, or utility unless a broader refactor is required.
- Prefer the existing simple StatefulWidget approach unless the task explicitly calls for a state-management change.
- When changing timer behavior, ensure save and restore flows remain compatible.
- When changing persistence, keep `toJson` and `fromJson` behavior symmetrical and verify restored timers still call any required rehydration logic.
- Run `flutter analyze` after Dart changes and run relevant tests when UI or timer behavior changes.
- Add or update tests when a user-visible workflow or timer calculation changes materially.