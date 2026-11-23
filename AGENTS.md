<!-- flutter-harness:start -->
## Flutter Harness — fast autonomous Flutter development
Project tooling: https://github.com/halsab/flutter-harness
Read .flutter-harness/config.json and load the flutter-harness project skill.

One short feature request authorizes implementation, necessary checks and PR.
Ask only unresolved material product/security decisions, not technical plans,
tools, branching, execution mode or whether to prepare a PR.
Use a feature branch from app; preserve unrelated files, including local config.
GPT-6 Luna medium is the default; inspect the active UI variant when relevant.

Test only meaningful behavior: Dart unit tests for business rules/persistence,
selective Flutter widget tests for stateful UI such as filtering/forms/errors.
No tests for trivial styling, labels, framework wiring or artificial coverage.
One standard check (format/analyze/flutter test) after implementation is normal.
Android/iOS Maestro and Web Playwright are optional risk-based checks, NOT
required on every task and NOT a condition of a regular PR for routine UI work.
Use scripted executable assertions for real platform/security/payment/data-loss
risk or explicitly requested E2E; only necessary platforms, limited retries.
Normalize app state before UI assertions; hidden by a filter is not missing.
The legacy verify-e2e.py helper is optional, not an ordinary delivery gate.

Self-review the task diff once. Independent read-only reviewer only for
material security/data migration/privacy/architecture/concurrency risk or
explicit request; no repeated reviews. Report actual checks honestly,
mark unneeded E2E NOT RUN (not required). A genuinely required failed check
or material unresolved issue means Draft. Push with tool approval, create PR
into app, never auto-merge, force-push or change golden baselines.

A project OpenCode V2 delivery guard checks Git state before normal session
completion. If a feature is not on a feature branch with a verified open PR
at local HEAD, it may continue the session up to twice, then reports INCOMPLETE.
It never commits or pushes itself, and never bypasses push permission prompts.
Never claim DONE after only code checks without an open PR.
<!-- flutter-harness:end -->
