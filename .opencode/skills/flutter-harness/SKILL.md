---
name: flutter-harness
description: Build, verify and deliver Flutter features from short user requests with minimal approvals and bounded tool use.
---

# Flutter Harness — default delivery workflow

The user specifies **outcomes**, not commands, agent roles, branch strategy or test plans. Act as the delivery owner. Read `.flutter-harness/config.json` for the mobile/mobile-web profile. Keep replies brief and focus on product decisions and final evidence, not internal plans or tool transcripts.

## One product checkpoint, not several

- Clarify only **material** questions that change behavior, architecture, security, privacy, data ownership, integration, ongoing cost or product scope (e.g. local-only tasks versus cross-device sync). Ask one focused question at a time. Never ask the owner to select a package, class layout, worktree, test runner or agent execution style.
- For substantial ambiguous features, present **one short design summary** (user-visible behavior, important tradeoffs, key exclusions) and obtain approval. Approval of that design is permission to plan and implement the agreed scope. **No second approval of a technical plan or of execution method.** A clearly scoped straightforward request can proceed without a design checkpoint.
- If new information materially changes the approved design, ask for a targeted decision. Otherwise pick conventional, reversible defaults and proceed. Protect secrets, privacy, production actions and expensive/irreversible operations with explicit consent.

## Delivery sequence (do not stop halfway)

1. Inspect `git status`, the current branch and project configuration. For sequential tasks, **use a feature branch in the current checkout** from the integration branch (`app` in Flutter Harness Lab, otherwise the repository's documented integration branch). Reuse an existing task branch. Do not ask branch versus worktree. Do not reset, stash, overwrite or stage unrelated changes, including local `opencode.jsonc`. If a real dirty-worktree conflict or concurrent session makes the checkout unsafe, describe that specific blocker.
2. Derive acceptance criteria from the agreed behavior. Make a **concise internal plan**; small tasks do not need long `docs/superpowers` files or a second user approval. Implement in coherent increments with focused tests. Prefer standard Flutter/Dart facilities and minimal maintained dependencies.
3. Run `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `flutter test` and relevant build(s). On a `mobile-web` profile, verify Web with **Playwright**, not Maestro Web. For available Android and iOS simulators/emulators, use **Maestro mobile** UI scenarios. Check UI state **after** actions (not input-field text masquerading as a saved row); test persistence after relaunch where requested. Record platform outcomes separately as PASS / FAIL / BLOCKED / SKIPPED; never claim unrun checks passed. GitHub CI does not prove local iOS runs.
4. Obtain **one independent, fresh-context final review** of the changed diff (typically the read-only `reviewer` agent). Give it requirements and acceptance criteria, but not the author\'s confidence claims or prior review conclusions. Require concrete failure scenarios, relevant file locations and evidence; reject speculative cosmetic feedback. Have `build` fix confirmed Critical/Important findings with focused regression tests. If a high-risk fix materially changes behavior, permit **one targeted recheck of that fix** (not an unbounded loop); otherwise finish with a concise self-check. Never let reviewer edit files, commit or launch its own agents. Report outstanding risks explicitly.
5. Commit only task files on the feature branch; attempt `git push` and create a **PR into the integration branch** (`app` for the lab) with changes, key test results and any limitations. A user request to build the feature includes preparing a PR; **do not ask again whether to make the PR**. Git push/external paths remain approval-gated by OpenCode permissions; request permission through the tool and honor denial. Never merge, force-push, publish or change golden image baselines without explicit owner approval.
6. Before saying DONE, verify the PR exists and links to the right base. If push/PR is blocked, report **BLOCKED with the exact next required action** instead of calling a local commit completed delivery. Do not repeat the full plan in chat.

## Model and context budget (soft policy, not a hard quota)

- `build` on **GPT-6 Luna medium** is the default implementer and orchestrator. Use Luna low for cheap search and Luna medium for routine reviews. Do not choose high reasoning by default.
- `architect` uses **GPT-6.2 Sol medium** only for genuinely complex architecture or hard diagnosis. Prefer at most **one** targeted Sol consultation per small feature; do not call it reflexively. `reviewer` uses Luna medium and performs one bounded final diff review.
- Use each tool for its intended job. **MCP servers expose tool schemas in model context**; avoid unnecessary server/tool discovery, full-file dumps and repeated log reads. Chrome DevTools is optional and disabled by default for the Web profile; Playwright handles regular Web checks.
- After **two unsuccessful attempts at the same UI/tool approach**, inspect one concise diagnostic and switch to a better tool or report a clear blocker. Do not loop on Maestro Web/Flutter Canvas text selectors, unsupported key codes, simulator restarts, hot-restart transport errors or indefinite run commands. Bound command timeouts reasonably; do not mistake a truncated run for a successful test.
- Keep status updates to meaningful decisions, a real blocker and final results. Do not narrate every thought or run multiple full reviews. Prefer targeted fixes and tests to repeated full validation cycles.
- These are behavioral policies, **not enforced token caps or billing guarantees**. Track actual token counts from sanitized OpenCode session exports using the harness session-usage script; compare sessions before claiming savings.

## Superpowers compatibility

The *default* autonomous OpenCode profile intentionally does **not** load the upstream Superpowers plugin. Its `brainstorming` and `writing-plans` skills include mandatory design/plan approvals and execution-choice handoffs that conflict with the owner's one-checkpoint workflow and produced repeated, lengthy agent loops in the first lab feature trial. **Do not pretend to override or bypass those upstream skill contracts.** Upstream Superpowers remains an optional, separately selected **interactive** workflow, whose approval rules must then be honored. Reuse good ideas (focused TDD, systematic debugging and verification) in this first-party autonomous policy; do not vendor Superpowers.

## Safety

Respect project `permissions`, tool approval prompts and GitHub branch rulesets. Denied actions stay denied; do not route through another shell command, API, MCP or subagent to bypass them. `architect` and `reviewer` are read-only. Never fabricate test output, PR existence, a platform run, a saved-state observation, model costs or exact token savings. On a single-turn `opencode run`, a permission or material design question can terminate the turn: report the blocked next step and continue in an interactive OpenCode session when the user responds.
