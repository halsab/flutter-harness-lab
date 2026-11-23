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
  if (current.status !== before.status) reasons.push("Uncommitted task changes remain (preserve preexisting unrelated changes)");
  if (!didWork && intent) reasons.push("No task change was recorded in this session");
  if (!prOK) reasons.push("PR missing or invalid: " + prMessage);
  return { active: true, passed: reasons.length === 0, reasons };
}
export async function inspect(root, base, before, intent) {
  const current = await snapshot(root);
  const script = join(root, ".flutter-harness", "bin", "verify-pr.sh");
  const pr = await command(root, "bash", [script, ".", base]);
  return decide(before, current, intent, pr.ok, pr.message);
}
