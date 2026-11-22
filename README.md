# Flutter Harness Lab

Public integration-test project for [Flutter Harness](https://github.com/halsab/flutter-harness),
generated using the official Flutter SDK.

## Branch contract

- `main` — unmodified SDK-generated default counter application for Android,
  iOS and Web. **Keep this branch clean** for reproducible fresh-start checks.
- `app` — the same initial counter application, plus Flutter Harness integration:
  OpenCode V2 model routing, Superpowers, MCP definitions, project instructions
  and 24 official Flutter/Dart skills. Future app features arrive through
  feature branches and human-reviewed PRs into `app`.

The installer and baseline are documented in
[flutter-harness/scripts/bootstrap-lab.sh](https://github.com/halsab/flutter-harness/blob/main/scripts/bootstrap-lab.sh)
and [the harness README](https://github.com/halsab/flutter-harness).
Bootstrap has already been completed; **do not rerun it to reset `app`**.

## Local verification

The owner has launched the default counter application on Android Emulator,
iOS Simulator and Chrome and checked the local Flutter toolchain. Basic
Dart, Maestro, Playwright, Chrome DevTools and Xcode MCP calls have been
confirmed. Sol/Luna model availability was confirmed using explicit CLI
model selections. Real subagent handoffs, repeatable Maestro/Playwright E2E
flows and a complete agent-authored feature PR are still to be tested.

GitHub Actions tests formatting, Flutter analysis, widget tests and Web
builds on pull requests. It also validates project OpenCode model routing,
MCP definitions and permission guardrails. Hosted CI **does not** run iOS
simulators or validate personal ChatGPT authentication.

## Workflow

1. Update `app`, verify a clean worktree and create a feature branch from it.
2. Use Luna for coding and targeted Sol medium subagents for planning/review.
3. Test the code; run Android/iOS/Web UI checks when relevant and record
   PASS, FAIL, BLOCKED or SKIPPED with actual evidence.
4. Commit to the feature branch and open a PR targeting `app`.
5. **The owner reviews and merges**. The agent never merges or approves
   golden baseline changes.

OpenCode `permissions` require approval for external paths and Git pushes,
while denying common merges, force pushes and publishing operations.
These are *not a sandbox*; configure repository-side branch protection too.
See [model routing and safety](https://github.com/halsab/flutter-harness/blob/main/docs/model-routing.md).

Installing into existing or legacy Flutter projects remains out of scope for v0.
