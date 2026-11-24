import { Plugin } from "@opencode/plugin";
import { snapshot, inspect, taskIntent } from "./guard.mjs";
import { registerQualityGate } from "./quality.mjs";

// Runs at normal OpenCode V2 completion, not on interrupted/failed executions.
// Maximum two continuations, no privileged Git/GitHub write actions.
export default Plugin.define({
  id: "flutter-harness-delivery",
  async setup(ctx) {
    const root = ctx.location.project?.directory || ctx.location.project?.canonical || ctx.location.directory;
    const key = (id) => "task/" + id;
    const quality = await registerQualityGate(ctx, root, "app", key);
    await ctx.session.hook("prompt", async (event) => {
      const session = await ctx.session.get({ sessionID: event.sessionID });
      if (session.parentID) return;
      const previous = await ctx.storage.get(key(event.sessionID));
      if (previous?.active) return;
      await quality.clear(event.sessionID);
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
      const qualityIssue = result.active ? await quality.reason(id) : "";
      if (!result.active || (result.passed && !qualityIssue)) {
        await ctx.storage.remove(key(id));
        await quality.clear(id);
        return;
      }
      const reason = [...result.reasons, qualityIssue].filter(Boolean).join("; ");
      if (state.attempts >= 2) {
        throw Error("Flutter Harness INCOMPLETE: " + reason);
      }
      await ctx.storage.set(key(id), { ...state, attempts: state.attempts + 1 });
      await ctx.session.synthetic({
        sessionID: id,
        text: "[Flutter Harness automatic delivery check] " + reason +
          ". Do one concise self-review of the task diff, commit task files, ask for push approval, " +
          "push, and create/update exactly one PR targeting app. Verify with " +
          "bash .flutter-harness/bin/verify-pr.sh . app. Preserve unrelated files. " +
          "Never bypass a denied permission. If blocked, give the exact reason. " +
          "Do not say DONE without the PR.",
      });
    });
  },
});
