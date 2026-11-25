import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { createHash } from "node:crypto";
import { readFile, lstat, readlink } from "node:fs/promises";
import { join } from "node:path";

const exec = promisify(execFile);

async function git(root, args) {
  return (await exec("git", args, { cwd: root, encoding: "utf8", timeout: 12000, maxBuffer: 4 * 1024 * 1024 })).stdout;
}
const split = (value) => value.split("\0").filter(Boolean);
const unique = (values) => [...new Set(values)].sort();
const textOf = (content) => typeof content === "string" ? content :
  Array.isArray(content) ? content.filter(x => x.type === "text").map(x => x.text).join("\n") : "";

export function testNames(source) {
  return [...source.matchAll(/\btest(?:Widgets)?\s*\(\s*(['"])([^'"\n]+)\1/g)].map(x => x[2]);
}
const visualRisk = "material UI redesign or design-system change";
// Lexical hints, not semantic understanding. Do not classify every widget edit as a redesign.
export function explicitVisualRequest(request = "") {
  return /(?:redesign|design.system|ui\s*\/\s*ux|new\s+(?:screen|page|flow)|(?:rework|overhaul|revamp)\b[^\n.!?]{0,70}\b(?:interface|screen|layout|ui)\b|редизайн|дизайн.систем|адаптивн\p{L}*\s+(?:дизайн|интерфейс)|(?:переработ\p{L}*|передел\p{L}*|перепроектир\p{L}*|обнов\p{L}*\s+дизайн)[^\n.!?]{0,70}(?:интерфейс|экран|композици|дизайн)|нов\p{L}*\s+(?:экран|страниц))/iu.test(request);
}
export function classify(paths, request = "", removed = [], diff = "") {
  const reasons = [];
  if (paths.some(p => /^lib\//i.test(p) &&
    /(?:\/(?:data|repositories?|storage|database|migrations?|auth|payments?)(?:\/|$)|(?:repository|storage|database|migration|credential|payment|auth)[^/]*\.dart$)/i.test(p))) {
    reasons.push("persistent data, storage or sensitive operation changed");
  }
  if (paths.some(p => p.startsWith("lib/")) &&
      (/(?:bulk\s+delet|delete\s+all|clear\s+all|mass\s+delet|удал\p{L}*\s+(?:все|всех|всё)|массов\p{L}*\s+удал)/iu.test(request) ||
      /(?:\bdelete(?:All|Completed|Many|Bulk)\w*\s*\(|\b(?:clear|remove)All\w*\s*\(|\bDROP\s+TABLE\b)/i.test(diff))) {
    reasons.push("destructive or bulk operation");
  }
  if (paths.some(p => p.startsWith("lib/app/"))) {
    reasons.push("product architecture changed");
  }
  if (paths.some(p => p.startsWith("lib/design_system/")) ||
      (paths.some(p => p.startsWith("lib/")) && explicitVisualRequest(request))) {
    reasons.push(visualRisk);
  }
  if (removed.length) reasons.push("tests disappeared after a failed check: " + removed.join("; "));
  return reasons;
}
// Count additions and deletions in source/tests, excluding generated lockfiles.
export function reviewEffort({ files, lines }, reasons = []) {
  if (lines > 100 || files > 3 || reasons.length) return "high";
  return "medium";
}
const reviewModel = "openai/gpt-6-luna";
const effortRank = { medium: 1, high: 2, xhigh: 3 };
export function matchingReviewModel(model, required) {
  return model?.providerID === "openai" && model?.id === "gpt-6-luna" &&
    (effortRank[model.variant] || 0) >= effortRank[required];
}
export function canonicalDelivery(command) {
  return /^\s*python3[ \t]+\.flutter-harness\/bin\/harness\.py[ \t]+deliver[ \t]*$/.test(command || "");
}
export function publishing(command) {
  return /(?:git\s+(?:-C\s+\S+\s+)?push\b|gh\s+pr\s+(?:create|ready|edit|merge)\b|harness\.py\s+deliver\b)/.test(command || "");
}
export function standardCheck(command) {
  return /^\s*python3[ \t]+\.flutter-harness\/bin\/harness\.py[ \t]+check[ \t]*$/.test(command || "");
}
export function finalVerdict(messages, requireVisual = false) {
  if (!Array.isArray(messages)) return false;
  const final = [...messages].reverse().find(m => m.type === "assistant" && textOf(m.content).trim());
  const text = textOf(final?.content);
  return requireVisual
    ? /(?:^|\n)VISUAL: PASS[ \t]*\r?\nVERDICT: PASS\s*$/.test(text)
    : /(?:^|\n)VERDICT: PASS\s*$/.test(text);
}
export function gateReason(candidate, state, reviewPassed) {
  if (state.lastCheckFailed && state.passedDigest !== candidate.digest) {
    return "The previous standard check failed or lacked required evidence. Fix the cause and run the standard check on the exact current candidate.";
  }
  if (state.passedDigest !== candidate.digest) {
    return "Run the standard check on the exact current source and tests; the previous result is absent or stale.";
  }
  if (candidate.reasons.length && !reviewPassed) return "A completed independent reviewer verdict PASS for this exact diff is required.";
  return "";
}

export async function candidate(root, base, request, failedNames = []) {
  const mergeBase = (await git(root, ["merge-base", base, "HEAD"])).trim();
  const untracked = split(await git(root, ["ls-files", "--others", "--exclude-standard", "-z", "--"]));
  const changed = unique([
    ...split(await git(root, ["diff", "--no-renames", "--name-only", "-z", mergeBase, "--"])),
    ...untracked,
  ]);
  const measured = changed.filter(p => /^(?:lib\/|test\/|integration_test\/|pubspec\.yaml$)/.test(p));
  const measuredSet = new Set(measured);
  let lines = 0;
  const stats = split(await git(root, ["diff", "--no-renames", "--numstat", "-z", mergeBase, "--"]));
  for (const row of stats) {
    const match = row.match(/^(\d+|-)\t(\d+|-)\t([\s\S]+)$/);
    if (!match || !measuredSet.has(match[3])) continue;
    lines += match[1] === "-" || match[2] === "-" ? 401 : Number(match[1]) + Number(match[2]);
  }
  for (const path of untracked.filter(p => measuredSet.has(p))) {
    const data = await readFile(join(root, path));
    if (data.includes(0)) { lines += 401; continue; }
    const source = data.toString("utf8");
    if (source.length) lines += source.split("\n").length - (source.endsWith("\n") ? 1 : 0);
  }
  const size = { files: measured.length, lines };
  const hash = createHash("sha256").update(mergeBase);
  const inputs = unique(split(await git(root, ["ls-files", "-z", "--cached", "--others", "--exclude-standard"])));
  for (const path of inputs) {
    try {
      const info = await lstat(join(root, path));
      if (info.isDirectory()) throw Error("Submodules not supported: " + path);
      hash.update("\0" + path + "\0" + (info.mode & 0o100 ? "x" : "-"));
      hash.update(info.isSymbolicLink() ? "link:" + await readlink(join(root,path)) : await readFile(join(root,path)));
    } catch (err) { if (err.code !== "ENOENT") throw err; }
  }
  const names = [];
  const testPaths = unique(split(await git(root, ["ls-files", "--cached", "--others", "--exclude-standard", "-z", "--", "test", "integration_test"])));
  for (const path of testPaths.filter(p => p.endsWith("_test.dart"))) {
    try { names.push(...testNames(await readFile(join(root, path), "utf8")).map(n => path + ": " + n)); }
    catch (err) { if (err.code !== "ENOENT") throw err; }
  }
  const removed = unique(failedNames.filter(n => !names.includes(n)));
  const diff = await git(root, ["diff", "--unified=0", mergeBase, "--", "lib"]);
  const additions = diff.split("\n").filter(line => line.startsWith("+") && !line.startsWith("+++")).join("\n");
  const reasons = classify(changed, request, removed, additions);
  if (changed.some(p => /^(android|ios|web)\//.test(p))) reasons.push("native or web platform configuration changed");
  let product = false;
  try { await readFile(join(root, ".flutter-harness/product.json")); product = true; }
  catch (err) { if (err.code !== "ENOENT") throw err; }
  const effort = reviewEffort(size, reasons);
  if (size.lines > 400 || size.files > 8) reasons.push("large change requires independent review");
  return { digest: hash.digest("hex"), paths: changed, names, removed, reasons, size, effort, product };
}

// All evidence comes from tool hooks and the child session, not a build-agent
// assertion or a marker file. Ordinary tasks do not launch another model.
export async function registerQualityGate(ctx, root, base, taskKey, verifyVisual = async () => {
  await exec("python3", [join(root, ".flutter-harness/bin/harness.py"), "visual-evidence"], {cwd:root, timeout:60000});
}, childStatus = async () => "") {
  const key = (id) => "quality/" + id;
  const pending = (id, call) => "quality-call/" + id + "/" + call;
  async function readState(id) { return (await ctx.storage.get(key(id))) || {}; }
  async function view(id) {
    const task = await ctx.storage.get(taskKey(id));
    if (!task?.active) return null;
    const state = await readState(id);
    const change = await candidate(root, base, task.request || "", state.failedNames || []);
    try {
      const manifest = JSON.parse(await readFile(join(root, ".flutter-harness/work/delivery.json"),"utf8"));
      if (manifest.review_required === true && !change.reasons.length) {
        change.reasons.push("semantic or owner-requested independent review");
        change.effort = reviewEffort(change.size, change.reasons);
      }
    } catch (err) { if (err.code !== "ENOENT") throw err; }
    return { task, state, change };
  }
  async function approved(id, state, change) {
    if (!state.review || state.review.digest !== change.digest) return false;
    const child = await ctx.session.get({ sessionID: state.review.childID });
    if (child.parentID !== id || child.agent !== "reviewer" || child.outcome !== "succeeded") return false;
    if (!matchingReviewModel(child.model, change.effort)) return false;
    return finalVerdict(await ctx.session.context({ sessionID: state.review.childID }), change.reasons.includes(visualRisk));
  }
  async function status(id) {
    const v = await view(id);
    if (!v) return { issue: "", phase: "work", digest: "", check: "unknown" };
    const checked = v.state.passedDigest === v.change.digest;
    const check = checked ? "passed" : v.state.lastCheckFailed ? "failed" : "missing";
    const approvedReview = checked && v.change.reasons.length > 0 &&
      await approved(id, v.state, v.change);
    let why = await childStatus(id) || gateReason(v.change, v.state, approvedReview);
    if (checked && v.change.reasons.includes(visualRisk)) {
      try { await verifyVisual(); }
      catch { why = "Current candidate needs actual light/dark runtime capture evidence (CLI launch/capture)."; }
    }
    if (!why) return { issue: "", phase: "work", digest: v.change.digest, check };
    const phase = !checked ? "check" : why.startsWith("Current candidate needs") ? "work" : "review";
    const prefix = v.change.reasons.length ? "Risk gate: " + v.change.reasons.join("; ") + ". " : "";
    const review = v.change.reasons.length ?
      " Reviewer route: Luna #" + v.change.effort + " (" + v.change.size.files +
      " files, " + v.change.size.lines + " changed lines). Use the read-only reviewer after successful checks; wait for its result. At most one targeted re-review." : "";
    return { issue: prefix + why + review +
      " Do not drop a failing acceptance test or bypass the gate.", phase, digest: v.change.digest, check };
  }
  async function reason(id) { return (await status(id)).issue; }

  await ctx.tool.hook("execute.before", async (event) => {
    const id = event.sessionID;
    const checking = event.tool === "shell" && standardCheck(event.input?.command);
    const reviewing = event.tool === "subagent" && event.input?.agent === "reviewer";
    if (event.tool === "shell" && publishing(event.input?.command)) {
      if (!canonicalDelivery(event.input?.command)) throw Error("Use only the canonical Harness delivery command");
      const task = await ctx.storage.get(taskKey(id));
      if (!task?.active) throw Error("No active root task for delivery");
      const why = await reason(id);
      if (why) throw Error(why);
    }
    if (!checking && !reviewing) return;
    const v = await view(id);
    if (!v) return;
    if (checking) {
      await ctx.storage.set(pending(id, event.id), { kind: "check", digest: v.change.digest, names: v.change.names, product: v.change.product });
      return;
    }
    // The normal reviewer is used, retaining its configured read-only permissions.
    // Append a short required verdict contract, not a second review prompt.
    const extra = [
      "Independently inspect the complete task diff (including uncommitted/new files) and the relevant source and tests.",
      "Original requirement: " + (v.task.request || "(see task prompt)"),
      "Check the behavior contract in docs/product when applicable against the original request, including interacting state and acceptance examples. A green test of an incorrect rule is not acceptance.",
      "Risk flags: " + (v.change.reasons.join("; ") || "requested review"),
      v.change.removed.length ? "Tests removed after a failed run: " + v.change.removed.join("; ") : "",
      v.change.reasons.some(r => /persistent data|destructive|tests disappeared/.test(r)) ? "For rejected persistence writes, verify the real repository against a seeded storage double that rejects only the write, not a replacement empty store. Assert reload and preserved records. Reject unsupported claims, missing important assertions, and removed failing tests without a valid replacement." : "Reject unsupported claims and missing important assertions.",
      v.change.reasons.includes(visualRisk) ? "Apply the visual acceptance checklist in .flutter-harness/templates/product/DESIGN.md. Actually open the final populated runtime captures and the baseline when available, compare at comparable viewport/content, and name the evidence and concrete differences. Inspect the visual plan, content start/density, persistent controls and secondary actions, readable long labels, selected state, changed interaction, and both themes when required. A full redesign cannot pass just because sorting works, spacing changed, or the app launches. Require a justified hierarchy and material improvement over the baseline. If required captures cannot be inspected, or a material visual defect remains, report VISUAL: CHANGES_REQUIRED followed by VERDICT: CHANGES_REQUIRED. On visual acceptance end with VISUAL: PASS on the line immediately before VERDICT: PASS. A logic-only recheck may reuse unchanged, actually inspected visual evidence. No screenshots are needed for architecture-only work." : "",
      "End with exactly VERDICT: PASS or VERDICT: CHANGES_REQUIRED on its own last line. PASS means no unresolved material findings; if evidence is incomplete, use CHANGES_REQUIRED.",
    ].filter(Boolean).join("\n");
    // Select the variant at the actual subagent invocation. Keep the same read-only
    // reviewer role; honor a stronger explicit Luna review but never a weaker one.
    const requested = typeof event.input.model === "string" && event.input.model.startsWith(reviewModel + "#")
      ? event.input.model.slice(reviewModel.length + 1) : "";
    const effort = (effortRank[requested] || 0) > effortRank[v.change.effort] ? requested : v.change.effort;
    event.input = { ...event.input, model: reviewModel + "#" + effort,
      prompt: (event.input.prompt || "") + "\n\n[Harness review contract]\n" + extra };
    await ctx.storage.set(pending(id, event.id), { kind: "review", digest: v.change.digest });
  });
  await ctx.tool.hook("execute.after", async (event) => {
    const id = event.sessionID;
    if (event.tool !== "shell" && event.tool !== "subagent") return;
    const call = await ctx.storage.get(pending(id, event.id));
    if (!call) return;
    await ctx.storage.remove(pending(id, event.id));
    const state = await readState(id);
    if (event.status !== "completed") {
      if (call.kind === "check") await ctx.storage.set(key(id), {...state, passedDigest: null, lastCheckFailed: true});
      return;
    }
    if (call.kind === "check") {
      const output = textOf(event.result?.content);
      const exit = event.result?.metadata?.exit;
      if (exit === 0 && /PASS format/.test(output) && /PASS analyze/.test(output) && /PASS flutter-tests/.test(output) && (!call.product || /PASS product/.test(output))) {
        const current = await view(id);
        // CLI formats/resolves dependencies before fingerprinting and checks that
        // inputs did not change during tests. Bind evidence to the resulting tree.
        await ctx.storage.set(key(id), { ...state, passedDigest: current.change.digest, lastCheckFailed: false });
      } else if (/FAIL flutter-tests/.test(output)) {
        await ctx.storage.set(key(id), { ...state, passedDigest: null, lastCheckFailed: true, failedNames: unique([...(state.failedNames || []), ...call.names]) });
      } else {
        await ctx.storage.set(key(id), { ...state, passedDigest: null, lastCheckFailed: true });
      }
    } else {
      const childID = event.result?.output?.sessionID || event.result?.metadata?.sessionID;
      if (typeof childID === "string" && childID) {
        await ctx.storage.set(key(id), { ...state, review: { digest: call.digest, childID } });
      }
    }
  });

  // Deny only publication when evidence is missing. Never turn an ask/deny
  // into allow; existing user approval and force-push rules remain intact.
  await ctx.permission.hook("evaluate", async (event) => {
    if (event.action !== "shell" || !event.resources.some(publishing)) return;
    const task = await ctx.storage.get(taskKey(event.sessionID));
    const why = !task?.active ? "No active root task" : !event.resources.every(canonicalDelivery) ? "Use the canonical Harness delivery command" : await reason(event.sessionID);
    if (why) {
      event.effect = "deny";
      event.message = why;
    } else if (event.effect !== "deny") {
      event.effect = "ask";
    }
  });
  return { reason, status, clear: (id) => ctx.storage.remove(key(id)) };
}
