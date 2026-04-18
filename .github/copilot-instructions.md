# Project Guidelines

## Scope

- The Flutter app lives under `ivgo/`.
- App code is mainly in `ivgo/lib/` and tests are in `ivgo/test/`.
- Platform folders under `ivgo/android/`, `ivgo/ios/`, `ivgo/macos/`, and `ivgo/windows/` should only be changed when the task requires platform-specific work.

## Code Style

- Follow the Dart and Flutter lint rules in `ivgo/analysis_options.yaml`.
- Prefer minimal, targeted changes over architectural rewrites.
- Keep naming and file organization consistent with the current layout; use the `Project Structure And Naming` section in `docs/copilot-requirements.md` for shared conventions.

## Architecture

- `ivgo/lib/main.dart` wires the app shell and theme.
- `ivgo/lib/pages/infusion_list_page.dart` owns the main infusion list UI and dialog flow.
- Timer behavior is encapsulated in `ivgo/lib/domain/infusion_timer.dart`.
- Persistence currently uses `shared_preferences` via `ivgo/lib/repositories/infusion_timer_repository.dart`; changes to timer data should preserve save and restore behavior.

## Build And Test

- Run Flutter commands from the `ivgo/` directory.
- Preferred validation steps are `flutter pub get`, `flutter analyze`, and `flutter test`.
- In VS Code, the workspace task `Pub: Clean, Get, Analyse and Test` can be used for a full validation pass.

## Conventions

- When changing timer or infusion data structures, keep serialization and restoration paths aligned.
- When changing the main list page, preserve refresh timer lifecycle behavior and avoid leaving background timers running.
- Avoid adding dependencies unless they are clearly justified by the task.

## Requirements

- Keep this file short and focused on repo-wide guidance.
- Put longer-lived product requirements, domain rules, structure conventions, and acceptance criteria in `docs/copilot-requirements.md`.