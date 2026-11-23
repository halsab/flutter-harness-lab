---
name: flutter-harness
description: Use when developing, testing, diagnosing or preparing a PR for a Flutter project with Flutter Harness installed.
---

# Flutter Harness

Use Superpowers for planning, TDD, debugging and review; use official Flutter/Dart tools for source and runtime diagnosis. Maestro is for mobile UI exploration and repeatable flows. If the profile includes Web, use Playwright for browser E2E and Chrome DevTools for diagnostics.

## OpenCode model routing

The project `opencode.jsonc` selects models and reasoning effort by agent:
- `build` uses GPT-6 Luna high for implementation, debugging, running tests and preparing a PR.
- `plan` and the `architect` subagent use GPT-6.2 Sol medium for design, trade-offs, acceptance criteria and difficult diagnosis.
- The `reviewer` subagent uses GPT-6.2 Sol medium for an independent code/test review before a PR. Use focused reviews rather than repeatedly reviewing unchanged files.
- `explore` uses GPT-6 Luna low for repository search; `general` uses Luna medium for routine delegated work.
- `compaction`, `title` and `summary` use Luna low for maintenance work.

When working as `build`, explicitly delegate substantive upfront design or complex diagnosis to `architect`; use `reviewer` for a focused final review. Follow Superpowers for the actual planning, implementation and verification process. Do not use Sol for mechanical file search, formatting or simple tool invocations. Never silently raise Sol reasoning above medium.

Do not assume that switching between primary `plan` and `build` in an existing OpenCode session switches the selected model: session model selection is sticky. For reliable routing use named subagents, or start separate sessions with the intended model and reasoning variant. A configured model is not a verified model call; check actual tool outputs and session/model selection.

## Git working-directory preference

The project owner has already chosen **feature branches in the current checkout** as the default for sequential development. For normal tasks, do not ask whether to use a separate worktree. Before changing application code, inspect `git status` and the current branch; if already on the feature branch for this task, continue there. Otherwise create a new `feat/...`, `fix/...`, or `chore/...` branch from the project's integration branch (`app` in `flutter-harness-lab`; `main` in the harness repository). Never commit directly to the protected integration branch.

Do not reset, stash, discard, or commit unrelated local changes (including local `opencode.jsonc` edits). Stage only task files. If changing branches or working in the current checkout would overwrite existing changes or interfere with concurrent work, stop and report the concrete conflict instead of guessing. Use a separate Git worktree only when the owner explicitly requests one; this standing branch preference is already the answer to routine Superpowers worktree/branch prompts.

## Safety and approval

Follow the project's `permissions` in `opencode.jsonc`. External paths,
Git pushes and potentially destructive shell operations require approval.
Never try alternate shell commands, MCP tools or APIs to bypass a denied
action. Never merge PRs, force-push or publish a release on the user's behalf.
An approval prompt from OpenCode is not the same as a GitHub branch-protection
rule; the owner reviews merges. The `architect` and `reviewer` subagents
may inspect files and read-only Git history but must not edit or run builds.
The `build` agent performs tests and reports actual tool output.

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
