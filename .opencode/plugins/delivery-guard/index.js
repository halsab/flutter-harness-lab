import { Plugin } from "@opencode/plugin";
import { readFile, mkdir, writeFile, appendFile, rename } from "node:fs/promises";
import { join } from "node:path";
import { snapshot, inspect, taskIntent, recovery } from "./guard.mjs";
import { registerQualityGate } from "./quality.mjs";
import { registerResourceGuard } from "./resources.mjs";

// Runs at normal OpenCode V2 completion, not on interrupted/failed executions.
// Maximum two continuations, no privileged Git/GitHub write actions.
export default Plugin.define({
  id: "flutter-harness-delivery",
  async setup(ctx) {
    const root = ctx.location.project?.directory || ctx.location.project?.canonical || ctx.location.directory;
    const config = JSON.parse(await readFile(join(root, ".flutter-harness/config.json"), "utf8"));
    if (config.schema !== 2 || typeof config.integration_branch !== "string" || !config.integration_branch) throw Error("Harness schema 2 configuration required");
    const base = config.integration_branch;
    const key = (id) => "task/" + id;
    const directory = join(root, ".flutter-harness/work");
    async function record(id, stage, detail = {}) {
      await mkdir(directory, {recursive:true});
      await appendFile(join(directory,"lifecycle.jsonl"), JSON.stringify({at:Date.now(),session:id,stage,...detail}) + "\n");
    }
    async function saveSessions(id) {
      await mkdir(directory, {recursive:true});
      const target = join(directory,"sessions.json");
      const tmp = target + ".tmp-" + id;
      await writeFile(tmp, JSON.stringify({sessions:await resources.sessions(id)}));
      await rename(tmp,target);
    }
    let quality;
    const resources = await registerResourceGuard(ctx, key, id=>quality.inputs(id), (event,input)=>quality.prepareReview(event,input));
    quality = await registerQualityGate(ctx, root, "origin/" + base, key, undefined, resources.status, true, resources.reviewAvailability);
    await ctx.session.hook("prompt", async (event) => {
      const session = await ctx.session.get({ sessionID: event.sessionID });
      if (session.parentID) return;
      const previous = await ctx.storage.get(key(event.sessionID));
      if (previous?.active) return;
      await quality.clear(event.sessionID);
      await resources.clear(event.sessionID);
      await ctx.storage.set(key(event.sessionID), {
        active: true,
        intent: taskIntent(event.prompt?.text),
        request: event.prompt?.text || "",
        baseline: await snapshot(root),
        attempts: 0,
      });
      await record(event.sessionID, "task-start");
    });
    await ctx.session.hook("experimental.idle", async (event) => {
      const id = event.sessionID;
      const state = await ctx.storage.get(key(id));
      if (!state?.active) return;
      if (event.background?.some(work => work.sessionID === id)) return;
      const result = await inspect(root, base, state.baseline, state.intent);
      const evidence = result.active ? await quality.status(id) : { issue: "", phase: "work" };
      if (!result.active || (result.passed && !evidence.issue)) {
        if (result.active) {
          await saveSessions(id);
          await record(id, "task-complete", {attempts:state.attempts});
        }
        await ctx.storage.remove(key(id));
        await quality.clear(id);
        await resources.clear(id);
        return;
      }
      if (evidence.phase === "waiting") return;
      const next = recovery(state, result, evidence);
      await saveSessions(id);
      await record(id, next.stop ? "task-incomplete" : "task-recovery", {attempts:state.attempts, phase:evidence.phase, check:evidence.check});
      if (next.stop) {
        throw Error("Flutter Harness INCOMPLETE: " + next.reason + ". Recovery budget exhausted or no observable progress.");
      }
      await ctx.storage.set(key(id), { ...state, attempts: state.attempts + 1, lastRecovery: next.fingerprint });
      await ctx.session.synthetic({ sessionID: id, text: next.prompt });
    });
  },
});
