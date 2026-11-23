
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
Sol medium for difficult architecture/diagnosis. Use Luna-low explore only
for broad unfamiliar-code search; skip it for small or focused changes.
Review the full task diff against app (including new task files), requiring
concrete failure scenarios and evidence. One fresh-context review; allow
one targeted recheck only for a material high-risk fix.
Use Flutter tests/analyze, Maestro on mobile, Playwright on Web, and honest
per-platform PASS/FAIL/BLOCKED/SKIPPED outcomes. Avoid repeated failing tool
loops. Always attempt push and PR into app after implementation; request push
approval, never bypass denials, and never merge a PR automatically.
Do not update golden baselines without owner approval.
<!-- flutter-harness:end -->
