// Reserve expensive child attempts before dispatch. This bounds supported
// tool invocations in one tracked root task, not provider tokens or billing.
export async function registerResourceGuard(ctx, taskKey) {
  const key = id => "resources/" + id;
  const queues = new Map();
  async function locked(id, fn) {
    const prior = queues.get(id) || Promise.resolve();
    const next = prior.catch(() => {}).then(fn);
    queues.set(id, next);
    try { return await next; }
    finally { if (queues.get(id) === next) queues.delete(id); }
  }
  await ctx.tool.hook("execute.before", async event => {
    if (event.tool !== "subagent") return;
    const role = event.input?.agent;
    const explicitSol = typeof event.input?.model === "string" &&
      /^openai\/gpt-6\.2-sol(?:#|$)/.test(event.input.model);
    if (!["advisor", "reviewer"].includes(role) && !explicitSol) return;
    const id = event.sessionID;
    const session = await ctx.session.get({ sessionID: id });
    if (session.parentID && (role === "advisor" || explicitSol)) {
      throw Error("Harness: only the task parent may request the focused Sol advisor.");
    }
    const task = await ctx.storage.get(taskKey(id));
    if (!task?.active) return;
    if (explicitSol && role !== "advisor") {
      throw Error("Harness: Sol is reserved for the optional focused advisor, not implementation or review.");
    }
    await locked(id, async () => {
      const state = (await ctx.storage.get(key(id))) || {};
      const limit = role === "advisor" ? 1 : 2;
      if ((state[role] || 0) >= limit) {
        throw Error("Harness: " + role + " attempt budget exhausted for this tracked task. Reuse evidence or report INCOMPLETE; do not switch models or bypass checks.");
      }
      await ctx.storage.set(key(id), { ...state, [role]: (state[role] || 0) + 1 });
      if (role === "advisor") event.input = { ...event.input, model: "openai/gpt-6.2-sol#medium" };
    });
  });
  return { clear: id => locked(id, () => ctx.storage.remove(key(id))) };
}
