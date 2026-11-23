
<!-- flutter-harness:start -->
## Flutter Harness
Project tooling: https://github.com/halsab/flutter-harness
Read .flutter-harness/config.json and load the flutter-harness skill.

A feature request authorizes routine implementation and PR preparation.
Only ask when a material product/security/architecture decision is unresolved.
When needed, ONE concise design approval suffices; do not ask again to approve
a technical plan, branch/worktree choice, execution style or routine library.
Choose a feature branch in this checkout from app by default. Preserve and
do not stage unrelated local changes (including opencode.jsonc).
Use Luna medium for implementation and ordinary independent review; reserve
Sol medium for difficult architecture/diagnosis. OpenCode can persist a
session-specific High variant despite Medium in the config: check the active
variant in the new session and audit actual usage from its export.
Use Luna-low explore only for broad unfamiliar-code search; skip it for small
or focused changes.
Review the full task diff against app (including new task files). Reviewer
runs permitted Git status, merge-base and diff commands separately (no shell
chaining or substitutions), and reads files with read, not cat. Permission
denials or inaccessible diff coverage mean review OPEN, never PASSED. Require
evidence-backed failure scenarios; one fresh-context review, one targeted
recheck only for a material high-risk fix.
Discover Android and iOS devices. If the iOS Simulator is booted and visible,
run affected Maestro UI scenarios on it **as well as** Android. iOS build is
not iOS Maestro. Use Playwright on Web. Assert exact expected text after
actions and relaunch; do not adjust assertions to accidental duplicate text.
Report separate Android/iOS/Web PASS/FAIL/BLOCKED/SKIPPED with evidence and
specific blockers. Avoid repeated failing tool loops. Always attempt push and PR into app after implementation; request push
approval, never bypass denials, and never merge a PR automatically.
Use python3 .flutter-harness/bin/web-preview.py start for Web Playwright: it
builds/serves Flutter Web on a local random port without the Chrome debugger.
Do not use flutter run -d chrome as the Web E2E test server. HTTP READY is not
browser E2E PASS. Android, iOS and Web checks run independently even when one
fails; never skip mobile because Web fails. Record Android/iOS/Web evidence in
.flutter-harness/verification.json (local/ignored), run verify-e2e.py before
the PR; missing or unverified platform results mean INCOMPLETE, so create
a DRAFT PR with limitations and do not claim verified DONE.
PR description must include Android: STATUS — evidence, iOS: STATUS — evidence,
Web: STATUS — evidence, even when one platform is BLOCKED/FAIL/SKIPPED.
Do not update golden baselines without owner approval.
<!-- flutter-harness:end -->
