import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { join } from "node:path";

const exec = promisify(execFile);
async function command(root, bin, args) {
  try {
    const { stdout } = await exec(bin, args, {
      cwd: root, encoding: "utf8", timeout: 15000, maxBuffer: 100000,
    });
    return { ok: true, message: stdout.trim() };
  } catch (err) {
    return { ok: false, message: String(err.stderr || err.message || err).slice(0, 500) };
  }
}
export function taskIntent(text) {
  return /(?:\b(?:add|implement|fix|create|build|update|refactor|finish|continue)\b|добав|реализ|исправ|созда|разработ|доработ|переимен|измени|внеси|заверш|доведи|продолжи)/i.test(text || "");
}
export function changed(a, b) {
  return a.head !== b.head || a.branch !== b.branch || a.status !== b.status;
}
export async function snapshot(root) {
  const [head, branch, status] = await Promise.all([
    command(root, "git", ["rev-parse", "HEAD"]),
    command(root, "git", ["branch", "--show-current"]),
    command(root, "git", ["status", "--porcelain=v1", "--untracked-files=normal"]),
  ]);
  if (![head, branch, status].every(x => x.ok)) throw Error("Unable to read Git state");
  return { head: head.message, branch: branch.message, status: status.message };
}
export function decide(before, current, intent, prOK, prMessage) {
  const didWork = changed(before, current);
  if (!didWork && !intent) return { active: false, passed: true, reasons: [] };
  const reasons = [];
  if (["app", "main", "master", ""].includes(current.branch)) reasons.push("Create a feature branch; never commit onto the integration branch");
  // A feature may start with uncommitted edits and end clean after committing them.
  // An unchanged pre-existing dirty worktree is also not newly unfinished work.
  // Only flag a *currently dirty* worktree that differs from the initial state.
  if (current.status && current.status !== before.status) {
    reasons.push("New or changed uncommitted work remains (preserve unrelated preexisting changes)");
  }
  if (!didWork && intent) reasons.push("No task change was recorded in this session");
  if (!prOK) reasons.push("PR missing or invalid: " + prMessage);
  return { active: true, passed: reasons.length === 0, reasons };
}
export async function inspect(root, base, before, intent) {
  const current = await snapshot(root);
  const script = join(root, ".flutter-harness", "bin", "verify-pr.sh");
  const pr = await command(root, "bash", [script, ".", base]);
  return { ...decide(before, current, intent, pr.ok, pr.message), current };
}

// A repeated idle with identical source/check/delivery state is not progress.
// The first retry is allowed; a second needs a material change in evidence.
export function recovery(state, result, quality) {
  const reasons = [...result.reasons, quality.issue].filter(Boolean);
  const fingerprint = JSON.stringify([result.current, quality.digest, quality.check, quality.phase, reasons]);
  const reason = reasons.join("; ");
  if (state.attempts >= 2 || (state.attempts > 0 && state.lastRecovery === fingerprint)) {
    return { stop: true, reason, fingerprint };
  }
  const step = quality.phase === "check"
    ? "Diagnose the earliest failed or missing required check. Inspect its actual error, make a focused fix, run the affected check then standard once. Do not ask for push approval before checks pass."
    : quality.phase === "review"
      ? "Reuse the successful standard evidence for the unchanged candidate. Inspect any prior reviewer result; fix material findings and recheck only as needed. Use the remaining allowed independent review attempt, not a duplicate review loop."
      : quality.check === "passed"
        ? "Resume remaining acceptance or delivery steps. Reuse successful checks on unchanged source; do not repeat builds, tests or reviews solely because this continuation ran."
        : "Resume the unfinished implementation or plan from current files. Run focused checks on missing behavior, then the required final check; do not publish incomplete work.";
  return { stop: false, reason, fingerprint, prompt:
    "[Flutter Harness recovery] " + reason + ". " + step +
    " Preserve unrelated changes and any task manifest. A failed check is work to fix, not an external blocker. " +
    "Do not escalate to Sol because of failure. If permission is denied or recovery cannot progress, state the exact blocker; preserve work. " +
    "Only after all required evidence passes, commit task files, request push approval and create/update one PR. Never bypass checks or claim DONE without a verified PR." };
}
