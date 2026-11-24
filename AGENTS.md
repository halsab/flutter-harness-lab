<!-- flutter-harness:start -->
## Flutter Harness
Project tooling: https://github.com/halsab/flutter-harness
Read .flutter-harness/config.json and load the flutter-harness skill.
Read .flutter-harness/PRODUCT.md for the mandatory feature-first MVVM, UX,
UI profile and design-system baseline. Default Material 3 on all platforms, Flutter Web only.
Adopt the foundation before application delivery; do not disable the check.

User requests describe outcomes; implement with minimal technical approvals.
Use a feature branch from app (Lab) or the documented integration branch.
Preserve unrelated edits, particularly local opencode.jsonc; stage only task files.
Default build: GPT-6 Luna Medium. Complex planning/diagnosis: Luna High.
Simple delegated slices: Luna Low. Follow the orchestration guide for large
changes; one parent owns verification and delivery. Optional Sol Medium
advisor only for one compact consequential architectural decision per task;
no premium implementation or automatic escalation.
Format once with dart format lib test, then run one standard check.
Never remove a failing acceptance test to make checks green. Risky persistent
or destructive changes require a successful check and independent reviewer
verdict on the exact candidate before publication.
Write focused unit tests for important logic and widget tests only for stateful
UI behavior. No tests for boilerplate, trivial styling or coverage quotas.
Android/iOS/Web device/browser E2E are NOT required for ordinary features.
Choose a minimal scripted integration check only when platform/critical risk
actually demands it, or the user explicitly requests E2E.
Do not infer a failed save from an item hidden by a selected filter.
If optional E2E is not needed, report NOT RUN (not required), not BLOCKED.
The legacy verify-e2e.py helper is optional, not a delivery gate.
Preflight one task-diff review BEFORE final checks. Match important new
observable behavior to a focused unit/widget test; green old tests are not
evidence for untested sorting/filter interactions. Avoid redundant tests.
Keep main.dart as entrypoint; put growing feature UI/view state in feature
folders with no gratuitous state-management dependency.
One bounded independent read-only reviewer for cross-feature interactions,
security, sensitive data, migration, concurrency, large architecture or
explicit user request. Skip reviewer for trivial changes; no review loops.
The plugin routes reviewer Luna Medium/High from diff size and risk; large
changes still require review. No automatic xhigh. One advisor and at most two
review attempts per tracked root task; phase-aware recovery stops on no progress.
If required checks pass, push with approval and create a normal PR into app.
If a genuinely required check fails or a material finding remains, use Draft.
Never auto-merge or force-push. Respect denied tool actions and golden approvals.
Keep verification concise and report only actual command results.
<!-- flutter-harness:end -->
