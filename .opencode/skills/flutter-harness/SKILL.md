---
name: flutter-harness
description: Use when developing, testing, diagnosing or preparing a PR for a Flutter project with Flutter Harness installed.
---

# Flutter Harness

Use Superpowers for planning, TDD, debugging and review; use official Flutter/Dart tools for source and runtime diagnosis. Maestro is for mobile UI exploration and repeatable flows. If the profile includes Web, use Playwright for browser E2E and Chrome DevTools for diagnostics.

## Workflow

1. For v0, start from a newly created default Flutter SDK project. Inspect its baseline and read `.flutter-harness/config.json`; do not assume Web is enabled. Do not attempt legacy-project migration or retrofit.
2. Agree scope and acceptance criteria with the human, then create a feature branch before implementation. Never commit to main.
3. Implement in small, verified increments, committing each meaningful milestone.
4. Prefer official Flutter/Dart commands and the harness scripts over ad hoc shell commands.
5. Use stable Flutter `Semantics(identifier: ...)` for critical UI selectors.
6. Save Maestro exploration as reusable YAML flows and rerun via CLI.
7. Record PASS, FAIL, SKIPPED and BLOCKED separately. Never claim unexecuted tests passed.
8. For changes to accepted golden screenshots, obtain explicit human approval first; don't silently update baselines.
9. Review the diff and push the feature branch. Open a PR with summary, plan, checkpoint commits, tests, platform evidence and blocked checks.
10. Never auto-merge, publish/store-release or use production secrets.

## Bootstrap checks

Until the Dart CLI ships, run:
`bash /path/to/flutter-harness/scripts/check.sh /path/to/project [quick|standard|full] [mobile|mobile-web]`

Make no claim of successful verification without actual command output.
