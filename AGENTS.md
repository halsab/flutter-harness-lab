<!-- flutter-harness:start -->
# Flutter Harness
Use native SDK/components and the deterministic CLI, not invented command sequences.
CLI prefix: python3 .flutter-harness/bin/harness.py
No Skills or MCP by default. Read only the relevant project sources. For architecture/theme read .flutter-harness/PRODUCT.md; for material behavior, UI, or complex work read the respective BEHAVIOR.md, DESIGN.md, ORCHESTRATION.md in .flutter-harness/templates/product.
For a new task use CLI begin <feature-branch> (clean checkout); status reports actual state. Implement only the requested behavior; preserve data and unrelated work. Use scaffold <name> <needed layers> when useful. Standard Material 3, feature-first MVVM, adaptive system theme.
Write focused executable acceptance tests for material behavior, including rejected writes and reload for persistence; no arbitrary test quotas. Inspect the diff once. Run the exact CLI check command once on the final candidate; it resolves dependencies, formats and verifies. Fix failures rather than weakening tests. Do not rerun unchanged checks.
For material UX use CLI launch/capture and actual populated runtime images, light/dark on a representative platform; compare to baseline and chosen direction. Use CLI e2e only for meaningful platform/critical risk or explicit request; known initial state, scripted assertions. No all-platform E2E ritual.
Default Luna Medium, one parent. Independent reviewer for interacting behavior, risky or large changes and material UI; follow the guard's actual effort and verdict. Optional advisor and workers only per ORCHESTRATION.md. No automatic premium escalation.
For delivery write ignored .flutter-harness/work/delivery.json with message, title, body, exact files (all task dirty paths), review_required and required_e2e. Set the semantic risk flags before check/review; the script appends actual verification outcomes. Invoke exactly: python3 .flutter-harness/bin/harness.py deliver
This checks current evidence, stages, commits, pushes with owner approval, creates/updates and verifies one PR. Never publish via other commands; never auto-merge. If required evidence is missing/denied, stop with BLOCKED/INCOMPLETE. Do not claim completion from prose or a draft PR. Only report actual checks.
<!-- flutter-harness:end -->
