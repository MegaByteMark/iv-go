# IVGo
Infusion timer job aid aimed at healthcare professionals who need to monitor manual IV dosages.

## Platform Scope

- Current implementation target: Android and iOS.
- Desktop rollout target: Windows first, with macOS as an optional follow-on once notification behavior is validated.
- Unsupported: web and Linux, because the required scheduled local-notification workflow is not reliable there.

## Copilot Agent Support

This repo now includes shared GitHub Copilot agent guidance.

- Project-wide instructions live in `.github/copilot-instructions.md`.
- Dart and Flutter-specific guidance lives in `.github/instructions/flutter-app.instructions.md`.
- Longer product or engineering requirements should go in `docs/copilot-requirements.md`.

Keep `.github/copilot-instructions.md` short and stable. Put detailed requirements, acceptance criteria, and domain notes into `docs/copilot-requirements.md`, then either link to that file from instructions or add it as chat context when you want the agent to follow task-specific constraints.
