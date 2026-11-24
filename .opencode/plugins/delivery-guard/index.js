import { Plugin } from "@opencode/plugin";
import { snapshot, inspect, taskIntent, recovery } from "./guard.mjs";
import { registerQualityGate } from "./quality.mjs";
import { registerResourceGuard } from "./resources.mjs";

// Runs at normal OpenCode V2 completion, not on interrupted/failed executions.
// Maximum two continuations, no privileged Git/GitHub write actions.
export default Plugin.define({
  id: "flutter-harness-delivery",
  async setup(ctx) {
    const root = ctx.location.project?.directory || ctx.location.project?.canonical || ctx.location.directory;
    const key = (id) => "task/" + id;
    const resources = await registerResourceGuard(ctx, key);
    const quality = await registerQualityGate(ctx, root, "app", key);
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
    });
    await ctx.session.hook("experimental.idle", async (event) => {
      const id = event.sessionID;
      const state = await ctx.storage.get(key(id));
      if (!state?.active) return;
      if (event.background?.some(work => work.sessionID === id)) return;
      const result = await inspect(root, "app", state.baseline, state.intent);
      const evidence = result.active ? await quality.status(id) : { issue: "", phase: "work" };
      if (!result.active || (result.passed && !evidence.issue)) {
        await ctx.storage.remove(key(id));
        await quality.clear(id);
        await resources.clear(id);
        return;
      }
      const next = recovery(state, result, evidence);
      if (next.stop) {
        throw Error("Flutter Harness INCOMPLETE: " + next.reason + ". Recovery budget exhausted or no observable progress.");
      }
      await ctx.storage.set(key(id), { ...state, attempts: state.attempts + 1, lastRecovery: next.fingerprint });
      await ctx.session.synthetic({ sessionID: id, text: next.prompt });
    });
  },
});
