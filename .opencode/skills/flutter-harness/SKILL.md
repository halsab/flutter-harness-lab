---
name: flutter-harness
description: Deliver Flutter features autonomously with fast risk-based verification and minimal test maintenance.
---

# Flutter Harness — fast autonomous delivery

The user describes the desired result. Handle implementation, appropriate checks and PR without requesting a technical plan, tooling choices or another approval. Clarify only a material product/security decision. Read .flutter-harness/config.json for the profile. Use GPT-6 Luna medium by default, and check the actual UI model variant if measuring usage. Preserve unrelated local changes.

## Five-stage workflow

1. Inspect the relevant project files, status and integration branch. Create a task branch from app (Lab) or the documented integration base. On follow-up tasks reuse the existing feature branch. Never stage, stash or overwrite unrelated local edits.
2. Implement a minimal maintainable change. Internally name the observable outcomes and meaningful failure cases before editing (no separate planning document or user approval). For each new business rule or stateful interaction, choose the smallest test that would fail if that behavior were wrong. Reuse an existing test if it already exercises the new outcome. Static text, styling and trivial framework wiring need no new test. Do not add tests just to meet a count.
3. **Preflight review BEFORE the standard check and PR:** inspect the complete task diff once against the integration base. Compare each changed observable behavior to an assertion in an existing/new unit or widget test; if none covers the important new branch, add one focused test now. In particular, new sorting requires checking both directions and original order, and combined search/filter/sort changes require checking their interaction without mutating persisted data. Also inspect whether the change is being appended to an unrelated oversized entrypoint/widget file. Fix material issues before continuing; do not invent tests for minor visual details.
   Then run ONE bash .flutter-harness/bin/check.sh . standard PROFILE (format, analyzer, all fast Dart unit/widget tests). During implementation run targeted tests only when useful. If checks fail, correct the specific cause and rerun the affected check(s), followed by one confirmation. A green existing suite alone is not proof that a newly implemented behavior was tested. Do not run full builds or launch emulators/browsers by default.
4. After passing checks, do not repeat the full diff review. If the change combines multiple existing behaviors (e.g. sorting plus filtering and search) or affects security/auth, sensitive data, migrations, payments/privacy, complex concurrency or wide architecture, use ONE **bounded, fresh-context read-only reviewer** before PR. Ask only: does the new behavior meet requirements, are any important cases untested, is persistent state preserved, and are there material architecture/regression risks? Supply the whole task diff and relevant tests; reject cosmetic findings. For trivial labels, ordinary isolated UI and style changes, the implementer's preflight review is enough. If a material finding requires a fix, run its targeted test and (if needed) the standard check again; at most one focused recheck, no review loops.
5. Commit only task files, request required push approval, create/update ONE PR into the integration branch and verify its target. **Never end after reporting tests passed without a PR.** The project OpenCode V2 delivery-guard plugin checks the Git state at normal session completion and injects at most two task continuations if no verified PR exists. This is not a substitute for PR/CI review; if the bounded gate cannot finish, report INCOMPLETE rather than a false success. A regular PR is appropriate if required fast checks pass and no material blocker remains. Note which tests ran and which optional tests were not required. Only the owner merges. Never claim device/browser E2E unless actually executed.

## Flutter architecture boundary

For a growing Flutter app, main.dart should be an entrypoint and app bootstrap, **not** the accumulating home for feature UI, view-state transformations, and persistence orchestration. Prefer a feature folder (e.g. lib/features/tasks/) containing the screen and a small pure Dart function/model for filter/search/sort/count, while existing repository/model code remains separate. Test pure transformations with fast unit tests and UI integration with the smallest meaningful widget test. No default Bloc/Riverpod/provider, layered architecture or new dependencies merely to organize a small feature.

When an existing entrypoint is already monolithic, do **not** bury another feature in it. Extract a cohesive touched component when small and safe; otherwise flag a focused refactor as separate work rather than silently mixing a 500-line restructuring into an unrelated PR. No arbitrary max-lines CI rule; consider responsibilities and change coupling.

## Test choice: protect logic, not implementation details

| Change | Appropriate new coverage |
| --- | --- |
| Validation, calculations, business rules, data transforms, state transitions | A few focused Dart unit tests (test()) for meaningful behavior/edge cases |
| Serialization, persistence, consequential error paths | Focused unit/repository tests with controlled dependencies |
| Meaningful stateful interface such as filtering, form validation and loading/error states | One focused Flutter widget test (testWidgets()) asserting public UI behavior |
| Static labels, styling, trivial wiring, normal framework behavior | Usually NO new tests |
| Native/plugin integration, device permissions, platform-dependent operation | Selective committed integration test only when fast tests cannot cover risk |
| Payment/auth, destructive migration, release-critical transaction path | Minimal scripted integration/E2E may be required for the actual risk |

Do not duplicate a scenario across unit/widget/Android/iOS/Web. No arbitrary coverage quotas, snapshots/goldens for minor style changes, private-method tests, excessive mock scaffolding or tests for every widget. A new nontrivial behavior is a test-selection decision even when all OLD tests are green. For a single new sorting feature, one focused unit/widget test is better than many broad UI E2E runs or no test at all. Favor stable public behavior over brittle layout details. Reuse existing tests when possible. If tests fail, check whether the feature or expectation is incorrect before changing assertions.

## E2E only when justified

Android/iOS Maestro and Web Playwright are NOT mandatory per feature. An available simulator or MCP does not create an E2E obligation. For simple task filters, a widget test that verifies visible items and unchanged saved status is sufficient. If integration/E2E is explicitly requested or materially necessary, run only the affected platform(s), preferably using a committed executable script with assertions and exit status. Do not replace programmatic tests with free-form AI inspection of screenshots.

When running UI tests: establish known preconditions first (current selected filter, seeded task data, app version). Assert the exact postcondition after each relevant action. A new active task hidden by the Completed filter is not a failed add; check All and saved state before diagnosing. Never adjust expected values to match an erroneous result. For Web, use the built local Web preview and Playwright rather than a Flutter Chrome debug-service connection. A build or server READY is not UI PASS.

On an infrastructure or keyboard/input issue, permit one focused diagnostic and one changed attempt, then report the selected optional test BLOCKED. Do not keep retrying and expanding scope. In a PR, distinguish PASS, FAIL, BLOCKED and NOT RUN (not required) for any optional integration tests. If a genuinely REQUIRED high-risk test fails or is blocked, keep the PR Draft. An unrun OPTIONAL E2E does not block an ordinary feature PR.

The existing verify-e2e.py is an OPTIONAL legacy completeness utility for an explicitly requested all-platform test; it is NOT a default delivery gate. Its agent-authored evidence strings are not independent proof. Do not create verification.json on ordinary tasks.

## Efficiency, reviewer safety and honesty

Aim for implementation to dominate total task time. Default verification is one standard script run and one concise self-review. Do not spawn explore, reviewer or architect for ordinary focused changes; prefer direct code inspection. Read-only reviewer shell: use individual permitted git status, git merge-base and git diff calls (no chained commands or substitutions), and read files via the read tool. Keep critical review findings grounded in realistic failure scenarios.

Hosted CI stays lightweight: formatting, analyzer, Flutter tests. Do not add heavy mobile/browser CI because local device checks were flaky. Respect Git push approval, no force-push, no auto-merge or golden acceptance. Report only observed results and actual model usage. Instructions help guide OpenCode, but the executable check script and CI are the deterministic pass/fail layer; strengthen only the gates required for actual risk.
