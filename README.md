# Flutter Harness Lab

Public integration-test project for [Flutter Harness](https://github.com/halsab/flutter-harness),
generated using the official Flutter SDK.

## Branch contract

- `main` — unmodified SDK-generated default counter application for Android,
  iOS and Web. **Keep this branch clean** for reproducible fresh-start checks.
- `app` — the same initial counter application, plus Flutter Harness integration:
  OpenCode V2 model routing, Superpowers, MCP definitions, project instructions
  and 24 official Flutter/Dart skills. The default profile now uses a lean\nfirst-party autonomous agent workflow, rather than loading Superpowers'\nmandatory interactive planning approvals. Future app features arrive through
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

1. Give the agent an outcome-focused request in interactive OpenCode. It asks
   only material product/architecture/security questions, requesting at most
   one short design signoff if necessary.
2. The agent chooses a feature branch in the current checkout from `app`,
   plans internally, and implements. No second plan approval, worktree choice
   or execution-mode question.
3. Luna medium drives implementation. A fresh-context Luna medium reviewer
   checks the final diff once (one targeted recheck for high-risk fixes);
   consult Sol medium only for hard architecture or diagnosis.
4. Run Flutter tests/analyze, Maestro on Android/iOS, and Playwright on Web;
   report real per-platform PASS/FAIL/BLOCKED/SKIPPED evidence.
5. Automatically attempt push and a PR targeting `app`, honoring the
   separate tool permission prompt. **The owner reviews and merges**.
   No automatic PR merge or golden baseline acceptance.

OpenCode `permissions` require approval for external paths and Git pushes,
while denying common merges, force pushes and publishing operations.
These are *not a sandbox*; configure repository-side branch protection too.
Default profile disables Chrome DevTools MCP until needed to reduce the\nregular tool surface. It does not uninstall tools or assert exact token\nsavings. Use the harness session-usage script to measure model/tool usage.\nFor an optional interactive design process, upstream Superpowers may still\nbe enabled separately.\nSee [model routing and safety](https://github.com/halsab/flutter-harness/blob/main/docs/model-routing.md).

Installing into existing or legacy Flutter projects remains out of scope for v0.
