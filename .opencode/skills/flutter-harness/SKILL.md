---
name: flutter-harness
description: Deliver Flutter features autonomously with fast risk-based verification and minimal test maintenance.
---

# Flutter Harness — fast autonomous delivery

The user describes the desired result. Handle implementation, appropriate checks and PR without requesting a technical plan, tooling choices or another approval. Clarify only a material product/security decision. Read .flutter-harness/config.json for the profile. Use GPT-6 Luna medium by default, and check the actual UI model variant if measuring usage. Preserve unrelated local changes.

## Product foundation (mandatory for installed product.json)

Read .flutter-harness/PRODUCT.md and product.json before the first product
change or meaningful screen/architecture change. Follow one feature-first
MVVM baseline, default universal Material 3, Flutter Web, reusable
design-system tokens and components. If status is pending, adopt the starter
with init-product.py and activate after real migration; never disable the
guard. Use stock Material widgets directly in presentation and shared themes/tokens.
Separate foundation adoption in an existing app from a broad redesign.
Inspect actual rendered screens for material UX changes on representative
platforms/states as specified in PRODUCT.md; no AI-driven functional E2E ritual.
Include UX and architecture in the same bounded reviewer. If useful, consult
Luna High architect once for genuine complexity or two unsuccessful fixes
to the same substantive failure. Sol Medium is allowed only through the optional
focused advisor route described in ORCHESTRATION.md; no premium implementation
or automatic failure-based escalation. Anticipate meaningful rejected-write/reload scenarios
before coding; prefer targeted checks during iteration. Required review may
run concurrently with standard checks on an unchanged candidate. Do not
spawn parallel duplicate reviews. Preserve existing behavior and user data.

## Large-task orchestration (one user request, one delivery)

Use .flutter-harness/templates/product/ORCHESTRATION.md for multi-slice work.
The build agent remains the parent/orchestrator at Luna Medium. For complex
product/architecture changes, request one read-only Luna High architect plan
before editing; give original request, behavior contract or draft, relevant
code and tests. Parent resolves the product rules and persists a validated
task graph in .flutter-harness/work/. For a large task delegate simple,
stable-contract slices to worker (Luna Low); handle consequential or tightly
coupled code at Medium yourself. Do not delegate ordinary focused tasks.
Only dispatch ready, nonconflicting slices, at most two workers at once.
Parent owns checks, integration, shared files, actual visual evidence,
recovery and PR. Await actual final child results; a session ID or idle
partial report is not completion. No user-visible stop between slices.
Only the parent may invoke advisor (Sol Medium) once per original task for a
consequential architectural decision with compact self-contained evidence.
Not a mandatory second planning round, implementation or broad diagnosis.
Record the reason and prior call in the durable plan or working context.
No other premium escalation and no extra reviewer per slice.

## Five-stage workflow

1. Inspect the relevant project files, status and integration branch. Fetch the integration branch and confirm the base is current before creating a fresh task branch from app (Lab) or the documented integration base; fast-forward only when safe. On follow-up tasks reuse the existing feature branch. Never stage, stash or overwrite unrelated local edits.
2. Define intended behavior before visual design or code. For trivial work or an obvious isolated bug, name the result and regression case internally. For material new/changed behavior, a new screen/redesign or interacting state, load .flutter-harness/templates/product/BEHAVIOR.md and write/update one compact contract in the existing spec or docs/product/<feature>.md. Establish change vs preserved behavior, initial/retained state, combined transitions, invariants, meaningful failures/recovery and concrete acceptance examples. Challenge the contract once against the original request and current product. Resolve routine decisions autonomously; no separate approval or agent. For substantial visual changes load .flutter-harness/templates/product/DESIGN.md, settle a coherent visual direction and include it in the slice handoff before UI implementation. For a multi-slice task follow the orchestration guide and execute ready slices until the integrated contract is met; otherwise implement directly. For each new business rule or stateful interaction, choose the smallest test that would fail if that behavior were wrong. Reuse an existing test if it already exercises the new outcome. Static text, styling and trivial framework wiring need no new test. Do not add tests just to meet a count.
3. **Preflight review BEFORE the standard check and PR:** inspect the complete task diff once against the integration base. Compare original request and behavior contract to the diff, and map each material acceptance example to appropriate evidence. Match testable changes to an assertion in an existing/new unit or widget test; if none covers the important new branch, add one focused test now. In particular, sorting must check each supported order, ties when relevant, visible selected state and interaction with grouping/filter/search, without mutating persisted data. Also inspect whether the change is being appended to an unrelated oversized entrypoint/widget file. Fix material issues before continuing; do not invent tests for minor visual details.
   Format touched Dart files (dart format lib test) before running ONE bash .flutter-harness/bin/check.sh . standard PROFILE (format, analyzer, all fast Dart unit/widget tests). During implementation run targeted tests only when useful. If checks fail, correct the specific cause and rerun the affected check(s), followed by one confirmation. A green existing suite alone is not proof that a newly implemented behavior was tested. Do not run full builds or launch emulators/browsers by default.
4. After implementation and targeted checks, do not repeat the full diff review. Required independent review may overlap final standard checks on an unchanged candidate; after material fixes both must cover the resulting candidate. If the change combines multiple existing behaviors (e.g. sorting plus filtering and search) or affects security/auth, sensitive data, persistent-data mutations, destructive operations (including bulk delete), migrations, payments/privacy, complex concurrency or wide architecture, material new screens/redesigns or shared design-system changes, use ONE **bounded, fresh-context read-only reviewer** before PR. Ask only: does the new behavior meet requirements, are any important cases untested, is persistent state preserved, and are there material architecture/regression risks? Supply original request, relevant behavior contract if required, selected visual direction and actual captures for material UX changes, whole task diff and relevant tests; challenge contradictory or incomplete product rules as well as code. Reject arbitrary cosmetic preferences, not material UX defects. For trivial labels, ordinary isolated UI and style changes, the implementer's preflight review is enough. If a material finding requires a fix, run its targeted test and (if needed) the standard check again; at most one focused recheck, no review loops.
5. For orchestrated work first confirm all planned slices have actual acceptance evidence and no child is still running; use task-plan.py complete on the current manifest. Commit only task files, request required push approval, create/update ONE PR into the integration branch and verify its target. **Never end after reporting tests passed without a PR.** The project OpenCode V2 delivery-guard plugin checks the Git state at normal session completion and injects at most two phase-aware continuations if delivery is incomplete, stopping earlier if the candidate and evidence do not progress. This is not a substitute for PR/CI review; if the bounded gate cannot finish, report INCOMPLETE rather than a false success. A regular PR is appropriate if required fast checks pass and no material blocker remains. Note which tests ran and which optional tests were not required. Only the owner merges. Never claim device/browser E2E unless actually executed.

## Adaptive reviewer effort

Keep one read-only reviewer role. The delivery plugin selects the actual GPT-6 Luna variant at subagent invocation based on the source/test diff (added plus deleted lines, including new untracked files, excluding pubspec.lock):

| Review scope | Luna effort |
| --- | --- |
| Small: at most 100 changed lines and 3 files, no risk flags | Medium |
| Larger: over 100 lines or 3 files; or risk-flagged changes | High |
| Large: over 400 changed lines or 8 files | High, mandatory independent review |

These are initial tuning thresholds, not quality quotas. Do not automatically select xhigh merely due to diff size; explicit owner-requested stronger Luna review is still supported. A risk flag raises a small review to at least High. Large changes require independent review. Small routine edits still use the existing self-review policy; no mandatory independent reviewer for trivial changes. Select one level once, not three successive reviews. For required review the child session must actually use Luna at the required effort or stronger; a weaker variant cannot satisfy the publication gate. Never claim a variant was used without observing it; unsupported variants block required review rather than silently falling back. Manual planning and the read-only architect default to Luna High; the build parent remains Luna Medium, the bounded worker Luna Low. Only the narrowly scoped optional advisor uses
Sol Medium; no premium implementation or blanket escalation.

## Enforced risk gate

The OpenCode delivery plugin classifies persistent-data paths, explicit bulk deletion, tests removed after a failing standard run and large changes. For those risks, the actual standard-check result and the configured read-only reviewer child session's final PASS verdict must match the same source/test candidate before git push or gh pr create/ready/edit. The idle hook also checks the evidence. Do not start an extra reviewer for ordinary isolated work. The plugin augments the reviewer prompt with the original requirement, risk flags and removed test names. Do not replace a failing persistence test with a widget fake that only throws. Seed storage, reject only the write, reload and assert retained records. If a test fixture is wrong, repair it; never delete a material assertion merely to obtain a green suite. Use one focused review and at most one targeted follow-up after fixing findings. This is a workflow gate on supported OpenCode tools, not a GitHub security boundary; the reviewer verdict remains semantic evidence, not a proof of correctness.

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

## Resource-aware recovery

Follow the resource policy in ORCHESTRATION.md. Reuse successful evidence on
unchanged candidates; after a failure inspect the first actual error and make
a targeted correction before rerunning. Do not repeat full builds/reviews to
show activity. One advisor attempt and at most two reviewer attempts are
reserved by the delivery plugin per tracked root task. No new premium call
on failure. The automatic idle recovery allows at most two continuations,
with an early stop for identical candidate/check/delivery state. Preserve
local progress and report INCOMPLETE when exhausted. These are workflow
limits, not subscription-token caps; verify actual OpenCode behavior.

## Efficiency, reviewer safety and honesty

Aim for implementation to dominate total task time. Default verification is one standard script run and one concise self-review. Do not spawn explore, reviewer or architect for ordinary focused changes; prefer direct code inspection. Read-only reviewer shell: use individual permitted git status, git merge-base and git diff calls (no chained commands or substitutions), and read files via the read tool. Keep critical review findings grounded in realistic failure scenarios.

Hosted CI stays lightweight: formatting, analyzer, Flutter tests. Do not add heavy mobile/browser CI because local device checks were flaky. Respect Git push approval, no force-push, no auto-merge or golden acceptance. Report only observed results and actual model usage. Instructions help guide OpenCode, but the executable check script and CI are the deterministic pass/fail layer; strengthen only the gates required for actual risk.
