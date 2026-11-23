---
name: flutter-harness
description: Deliver Flutter features autonomously with fast risk-based verification and minimal test maintenance.
---

# Flutter Harness — fast autonomous delivery

The user describes the desired result. Handle implementation, appropriate checks and PR without requesting a technical plan, tooling choices or another approval. Clarify only a material product/security decision. Read .flutter-harness/config.json for the profile. Use GPT-6 Luna medium by default, and check the actual UI model variant if measuring usage. Preserve unrelated local changes.

## Five-stage workflow

1. Inspect the relevant project files, status and integration branch. Create a task branch from app (Lab) or the documented integration base. On follow-up tasks reuse the existing feature branch. Never stage, stash or overwrite unrelated local edits.
2. Implement a minimal maintainable change. Decide test needs using the matrix below. Write ONLY tests that protect important observable behavior; do not add tests just to satisfy a count, or rewrite tests not affected by the feature.
3. Verify after implementation with ONE run of: bash .flutter-harness/bin/check.sh . standard PROFILE (format, analyzer, all fast Dart unit/widget tests). During implementation run targeted tests only if useful. If a check fails, diagnose, fix and rerun the affected test, then confirm the standard check. A successful code check is not an E2E result. Do not run full builds or launch emulators/browsers by default.
4. Inspect the task diff against the integration base ONCE and check acceptance criteria. Independent read-only reviewer is OPTIONAL and reserved for security/auth, sensitive data, migrations, payment/privacy, complex concurrency, wide architecture changes or explicit user request. If invoked, exactly one focused review; only one targeted recheck for important fixes. Routine simple features do not need delegated review.
5. Commit only task files, request required push approval, create/update ONE PR into the integration branch and verify its target. A regular PR is appropriate if required fast checks pass and no material blocker remains. Note which tests ran and which optional tests were not required. Only the owner merges. Never claim device/browser E2E unless actually executed.

## Test choice: protect logic, not implementation details

| Change | Appropriate new coverage |
| --- | --- |
| Validation, calculations, business rules, data transforms, state transitions | A few focused Dart unit tests (test()) for meaningful behavior/edge cases |
| Serialization, persistence, consequential error paths | Focused unit/repository tests with controlled dependencies |
| Meaningful stateful interface such as filtering, form validation and loading/error states | One focused Flutter widget test (testWidgets()) asserting public UI behavior |
| Static labels, styling, trivial wiring, normal framework behavior | Usually NO new tests |
| Native/plugin integration, device permissions, platform-dependent operation | Selective committed integration test only when fast tests cannot cover risk |
| Payment/auth, destructive migration, release-critical transaction path | Minimal scripted integration/E2E may be required for the actual risk |

Do not duplicate a scenario across unit/widget/Android/iOS/Web. No arbitrary coverage quotas, snapshots/goldens for minor style changes, private-method tests, excessive mock scaffolding or tests for every widget. Favor stable public behavior over brittle layout details. Reuse existing tests when possible. If tests fail, check whether the feature or expectation is incorrect before changing assertions.

## E2E only when justified

Android/iOS Maestro and Web Playwright are NOT mandatory per feature. An available simulator or MCP does not create an E2E obligation. For simple task filters, a widget test that verifies visible items and unchanged saved status is sufficient. If integration/E2E is explicitly requested or materially necessary, run only the affected platform(s), preferably using a committed executable script with assertions and exit status. Do not replace programmatic tests with free-form AI inspection of screenshots.

When running UI tests: establish known preconditions first (current selected filter, seeded task data, app version). Assert the exact postcondition after each relevant action. A new active task hidden by the Completed filter is not a failed add; check All and saved state before diagnosing. Never adjust expected values to match an erroneous result. For Web, use the built local Web preview and Playwright rather than a Flutter Chrome debug-service connection. A build or server READY is not UI PASS.

On an infrastructure or keyboard/input issue, permit one focused diagnostic and one changed attempt, then report the selected optional test BLOCKED. Do not keep retrying and expanding scope. In a PR, distinguish PASS, FAIL, BLOCKED and NOT RUN (not required) for any optional integration tests. If a genuinely REQUIRED high-risk test fails or is blocked, keep the PR Draft. An unrun OPTIONAL E2E does not block an ordinary feature PR.

The existing verify-e2e.py is an OPTIONAL legacy completeness utility for an explicitly requested all-platform test; it is NOT a default delivery gate. Its agent-authored evidence strings are not independent proof. Do not create verification.json on ordinary tasks.

## Efficiency, reviewer safety and honesty

Aim for implementation to dominate total task time. Default verification is one standard script run and one concise self-review. Do not spawn explore, reviewer or architect for ordinary focused changes; prefer direct code inspection. Read-only reviewer shell: use individual permitted git status, git merge-base and git diff calls (no chained commands or substitutions), and read files via the read tool. Keep critical review findings grounded in realistic failure scenarios.

Hosted CI stays lightweight: formatting, analyzer, Flutter tests. Do not add heavy mobile/browser CI because local device checks were flaky. Respect Git push approval, no force-push, no auto-merge or golden acceptance. Report only observed results and actual model usage. Instructions help guide OpenCode, but the executable check script and CI are the deterministic pass/fail layer; strengthen only the gates required for actual risk.
