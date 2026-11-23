# Flutter Harness Lab

Public test project for [Flutter Harness](https://github.com/halsab/flutter-harness).
- main: unmodified SDK-generated starter; leave untouched.
- app: integration branch for the evolving example task application.
- New features: task branches with PRs into app; only owner merges.

## Autonomous workflow

The goal is fast, stable implementation from one concise user requirement.
The default OpenCode project skill uses GPT-6 Luna medium for implementation
(with the usual caveat that an existing UI-selected variant can override it).

For ordinary features:
1. Implement with a small coherent change.
2. Write only useful Dart unit tests for business logic/persistence and
   selective Flutter widget tests for significant state behavior.
3. Run one standard Flutter code check (format, analyzer, flutter test).
4. Self-review the diff once; use a separate reviewer only for material
   data/security/architecture/concurrency risks or explicit request.
5. Push with permission and create/update one PR into app; owner merges.

**There is no default Android+iOS+Web E2E requirement.** Heavy Maestro,
Playwright, emulator/simulator or full-build checks are reserved for platform
integration or other genuinely critical risks, or explicit requests. Such
checks should be committed/repeatable scripts with assertions, not subjective
AI screenshot exploration. Run only relevant platforms. Optional E2E unrun
is NOT RUN (not required), not a blocker or reason for Draft.

A failed required check or unresolved material risk does require Draft.
Hosted GitHub CI validates Flutter formatting, analyzer, tests and basic
config/scripts; it does not prove mobile or Web E2E execution.

## Why the policy changed

In task-filter PR #8, a new active task was successfully saved on Android but
hidden under the Completed filter. The agent wrongly blamed Maestro input,
repeated tool attempts and spent disproportionate time testing a small UI
feature. The new policy emphasizes known starting state, unit/widget tests,
scripted assertions where justified, and a strict budget for manual tool
diagnosis. Heavy E2E is not a standard feature-acceptance ritual.

## Optional tools

If a Web browser flow is actually necessary, build/serve on localhost without
the Flutter Chrome debug-service handshake:

    python3 .flutter-harness/bin/web-preview.py start
    # Run targeted Playwright scenario with real assertions
    python3 .flutter-harness/bin/web-preview.py stop

The existing verify-e2e.py is a legacy OPTIONAL checklist for explicitly
requested all-platform verification. Do not create verification.json on
routine features; do not treat agent-written evidence as independent proof.
MCP connections for Dart, Maestro, Playwright and optional Xcode remain
available but availability alone does not make those tools mandatory.

## Existing-project installation

The upstream installer deliberately preserves an existing project
opencode.jsonc and skill/AGENTS files. Harness policy updates must be
explicitly synced to this Lab via a configuration-only PR. Lab main must
remain the untouched SDK starter. For installation and model-routing details,
see upstream README and docs/verification-policy.md.
