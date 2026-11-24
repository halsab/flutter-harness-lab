<!-- flutter-harness:start -->
## Flutter Harness — fast autonomous Flutter development
Project tooling: https://github.com/halsab/flutter-harness
Read .flutter-harness/config.json and load the flutter-harness project skill.
Read .flutter-harness/PRODUCT.md and .flutter-harness/product.json for product
architecture, UX, Adaptive UI and reusable design system. Adopt the pending
foundation in the next product migration; activate only after real integration.
The standard check and CI enforce convention rules; never bypass or downgrade.
For material UX changes inspect actual rendered screenshots, including Cupertino
and Material for initial adoption, and supply them to the same reviewer.
No routine E2E or separate designer agent. Sol for difficult decisions or
repeated substantive failures; anticipate rejected-write tests before review.

One short feature request authorizes implementation, necessary checks and PR.
Ask only unresolved material product/security decisions, not technical plans,
tools, branching, execution mode or whether to prepare a PR.
Use a feature branch from app; preserve unrelated files, including local config.
GPT-6 Luna medium is the default; inspect the active UI variant when relevant.

Test only meaningful behavior: Dart unit tests for business rules/persistence,
selective Flutter widget tests for stateful UI such as filtering/forms/errors.
No tests for trivial styling, labels, framework wiring or artificial coverage.
Format touched Dart files before one standard check (format/analyze/flutter test).
Never remove a meaningful failing acceptance test to obtain green checks.
Android/iOS Maestro and Web Playwright are optional risk-based checks, NOT
required on every task and NOT a condition of a regular PR for routine UI work.
Use scripted executable assertions for real platform/security/payment/data-loss
risk or explicitly requested E2E; only necessary platforms, limited retries.
Normalize app state before UI assertions; hidden by a filter is not missing.
The legacy verify-e2e.py helper is optional, not an ordinary delivery gate.

Before the standard check/PR, review the task diff ONCE against the
requirements and ensure important NEW behavior is asserted by a focused unit
or widget test; passing old tests alone is not enough. For sorting, test
ascending, descending, default order and state not being persisted. No tests
for trivial labels or styling. Use one bounded read-only reviewer when a
change intersects multiple existing features (sort/search/filter), critical
security/data/concurrency/architecture risk, persistence mutations, destructive
operations (including bulk delete), or when explicitly requested.
No reviewer loops. Keep main.dart limited to app bootstrap and use a feature
folder for growing UI/transformation logic, without needless dependencies.
Refactor an existing monolith in focused work separate from an unrelated PR. Report actual checks honestly,
mark unneeded E2E NOT RUN (not required). A genuinely required failed check
or material unresolved issue means Draft. Push with tool approval, create PR
into app, never auto-merge, force-push or change golden baselines.

A project OpenCode V2 delivery guard checks Git state before normal session
completion. If a feature is not on a feature branch with a verified open PR
at local HEAD, it may continue the session up to twice, then reports INCOMPLETE.
It never commits or pushes itself, and never bypasses push permission prompts.
Never claim DONE after only code checks without an open PR.
The risk gate observes actual check results and reviewer child-session verdicts
for the same source/test candidate. Risky publication is denied without both.
If a failing test disappears, the reviewer must consider its original scenario.
Do not replace a persistence failure assertion with a fake UI-only failure.
Reviewer effort is selected by the plugin from actual source/test diff size:
Luna Medium up to 100 changed lines/3 files, High up to 400 lines/8 files
or for risk-flagged changes, Extra High (xhigh) above either large threshold.
Large changes require independent review. A weaker child model/variant cannot
satisfy required review. No extra reviewer for trivial changes or tier loops.
<!-- flutter-harness:end -->
