# Flutter Harness Lab

Public integration-test project for [Flutter Harness](https://github.com/halsab/flutter-harness),
generated using the official Flutter SDK.

## Branch contract

- `main` — unmodified SDK-generated default counter application for Android,
  iOS and Web. **Keep this branch clean** for reproducible fresh-start checks.
- `app` — the same initial counter application, plus Flutter Harness integration:
  OpenCode V2 model routing, MCP definitions, project instructions
  and 24 official Flutter/Dart skills. The default profile uses a lean
  first-party autonomous agent workflow instead of Superpowers' mandatory
  interactive planning approvals. Future app features arrive through
  feature branches and human-reviewed PRs into `app`.

The installer and baseline are documented in
[flutter-harness/scripts/bootstrap-lab.sh](https://github.com/halsab/flutter-harness/blob/main/scripts/bootstrap-lab.sh)
and [the harness README](https://github.com/halsab/flutter-harness).
Bootstrap has already been completed; **do not rerun it to reset `app`**.

## Local verification

The owner has launched Flutter on Android Emulator, iOS Simulator and Chrome
and checked the local toolchain. Basic Dart, Maestro, Playwright, Chrome
DevTools and Xcode MCP connectivity is confirmed. The task-list PR (#5)
and autonomous title-edit PR (#6) reached GitHub; PR #6 had passing CI
and actual Android Maestro / Web Playwright tool calls. An audit of that
second run found no iOS Maestro invocation, three reviewer shell permission
denials, and a main-agent session using Luna High despite the project
default Medium. This project-sync PR applies the focused Harness fixes;
the next fresh OpenCode run must validate them at runtime.

GitHub Actions checks formatting, Flutter analysis and widget tests on PRs.
Web compilation can be requested locally via the Harness full check; Android,
iOS and Web UI tests remain the local agent's responsibility. CI also validates
OpenCode routing, installed Harness scripts and permission guardrails.
Hosted CI does not run device simulators or personal authentication.

## Workflow

1. Give the agent an outcome-focused request in interactive OpenCode. It asks
   only material product/architecture/security questions, requesting at most
   one short design signoff if necessary.
2. The agent chooses a feature branch in the current checkout from `app`,
   plans internally, and implements. No second plan approval, worktree choice
   or execution-mode question.
3. Luna medium is the configured implementation default; confirm the active
   variant in the new OpenCode session because a retained UI selection can
   override it. A fresh-context Luna medium reviewer checks the complete
   final task diff once using individual allowlisted read-only Git commands
   and file reads (OPEN if any task diff is inaccessible); consult Sol medium
   only for hard architecture or diagnosis.
4. Run Flutter tests/analyze, discover Android/iOS targets, and run Maestro
   on both when available, including a booted iOS Simulator. Compile-only iOS
   checks do not count as iOS UI tests. Use Playwright on Web and assert the
   exact intended result after actions and persistence. Report independent
   Android/iOS/Web PASS/FAIL/BLOCKED/SKIPPED results with evidence.
5. Automatically attempt push and a PR targeting `app`, honoring the
   separate tool permission prompt. **The owner reviews and merges**.
   No automatic PR merge or golden baseline acceptance.

OpenCode `permissions` require approval for external paths and Git pushes,
while denying common merges, force pushes and publishing operations.
These are *not a sandbox*; configure repository-side branch protection too.
Default profile disables Chrome DevTools MCP until needed to reduce the
regular tool surface. It does not uninstall tools or assert exact token
savings. Use the harness session-usage script to measure model/tool usage.
For an optional interactive design process, upstream Superpowers may still
be enabled separately.
See [model routing and safety](https://github.com/halsab/flutter-harness/blob/main/docs/model-routing.md).

The lab's existing Harness files are synchronized explicitly via small
integration PRs; the normal installer remains non-overwriting. To run the
next trial after merging the updated Harness and Lab configuration PRs:
update local `app`, select Luna **Medium** in a **new OpenCode session**
(not just `opencode debug config`), ensure `flutter devices` lists both
the Android emulator and an iOS Simulator, and give the agent only a short
feature request. Keep CI lightweight; Android/iOS Maestro and Web Playwright
remain local agent responsibilities. Do not merge a feature PR until its
verification evidence has been reviewed.

Installing into unrelated existing or legacy Flutter projects remains out
of scope for v0.
