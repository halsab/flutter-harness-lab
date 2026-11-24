# Flutter Harness Lab

Public test project for [Flutter Harness](https://github.com/halsab/flutter-harness).
- main: unmodified SDK-generated starter; leave untouched.
- app: integration branch for the evolving example task application.
- New features: task branches with PRs into app; only owner merges.

## Delivery completion guard

The project includes a local OpenCode V2 plugin under
`.opencode/plugins/delivery-guard/`, installed from Flutter Harness.
It records the initial Git state on a feature request and uses OpenCode's
experimental `session.hook("experimental.idle")` to verify that delivery
reached an open PR into `app`, containing the same commit as local HEAD.
If not, it asks the same agent to continue delivery, **at most twice**,
then fails the execution instead of silently claiming DONE.

The plugin makes no GitHub writes or Git commits, does not bypass push
approvals, and does not add Android/iOS/Web E2E. The one standard Flutter
check and concise task-diff self-review remain the default verification.
This is a bounded delivery backstop rather than a guarantee against
provider interruption or all OpenCode-version differences.

**Runtime check still needed on the owner's Mac.** Confirm the plugin is
loaded in a new OpenCode session and that a short feature reaches a PR.
Older sessions do not automatically adopt updated plugins.

## Adaptive reviewer effort

The plugin routes the existing read-only reviewer at actual invocation:
- Luna Medium: <=100 added/deleted lines and <=3 files, no risk flags.
- Luna High: <=400 lines and <=8 files, or elevated risk.
- Luna Extra High (xhigh): above either large-change threshold.

Source/test diff includes untracked new files and excludes pubspec.lock from
size. Large changes require independent review; trivial changes still skip
it. Only one reviewer is used, with the required actual child-session model
variant verified for publication. This is an initial heuristic to tune from
observed review quality and overhead. Build and Sol settings are unchanged.
Verify variant availability and routing on the installed OpenCode runtime.

## Risk review gate

For persistent-data changes, destructive operations, and tests removed after
a failed standard run, the delivery plugin requires the observed standard
check result and an actual independent reviewer child-session PASS for the
same source/test candidate before supported push/PR commands. Missing or stale
evidence blocks publication; existing push approvals are not bypassed. It also
checks at session completion. Ordinary changes do not launch extra review
automatically. The check runner stops on a formatting error before Flutter
analysis/tests. Fix the format once before rerunning.

The reviewer must inspect removed acceptance tests and consequential persistence
errors, including reload of seeded storage after a rejected write. A successful
review is evidence, not a semantic proof. This is a workflow guard for supported
OpenCode tool actions, not a GitHub security boundary. Real runtime integration
needs a new local session smoke test.

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

## Architecture and pre-PR review

For a growing app `lib/main.dart` is a bootstrap, not the permanent home
for all feature screens and list transformations. Prefer
`lib/features/tasks/task_list_screen.dart` and a small pure view-state
transformation alongside the existing task repository/model, without introducing
state-management packages solely to organize code. The currently oversized
task screen should be extracted in a separate focused refactor after the
in-flight sorting PR is merged.

Before the usual single standard Flutter check, the build agent must inspect
the complete task diff and map material new behavior to a focused unit/widget
test. Existing green tests do not prove a new sorting rule. For interactions
between multiple features, e.g. search+filter+sort, invoke at most one bounded
independent read-only review BEFORE submitting the PR; trivial isolated changes
do not need it. This is not a mandate for multiple tests or Android/iOS/Web E2E.

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

## Product foundation adoption

The reusable Harness now supplies an Adaptive/Universal starter, product UX
standard and architecture/design-system convention checks. See
`.flutter-harness/PRODUCT.md` and `.flutter-harness/product.json`.
Status is deliberately pending until the agent migrates the existing app.
The next focused PR must adopt feature-first MVVM, platform-neutral feature
screens, shared design tokens/components, native iOS Cupertino and Material
on Android/Flutter Web, preserve current behavior/data, activate the product
config, and pass standard checks, reviewer and actual visual acceptance.
Run `python3 .flutter-harness/bin/init-product.py .` to copy missing starter
files; it never overwrites existing files or installs dependencies. Adjust the
SDK-compatible dependencies and app composition explicitly. The Lab sync PR
changes tooling only; CI permits pending only on config-only adoption, not on
application changes or after activation.
