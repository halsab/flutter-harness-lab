// Bound actual child dispatches, not model tokens. Use OpenCode session
// outcome as execution evidence; a worker's text is not completion.
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
  async function read(id) {
    return (await ctx.storage.get(key(id))) || { children: [], pending: [] };
  }
  async function running(id, state) {
    const active = [];
    for (const c of state.children || []) {
      const session = await ctx.session.get({ sessionID:c.id });
      if (session.parentID !== id) throw Error("Unexpected child session ownership");
      if (!["succeeded","failed","canceled","cancelled","aborted"].includes(session.outcome)) active.push(c);
    }
    return active;
  }
  async function status(id) {
    return locked(id, async()=>{
      const state = await read(id);
      if ((state.pending || []).length) return "A child dispatch has not returned its actual session ID/outcome.";
      if ((await running(id,state)).length) return "Wait for actual child session completion before delivery.";
      return "";
    });
  }
  await ctx.tool.hook("execute.before", async event => {
    if (event.tool !== "subagent") return;
    const role = event.input?.agent;
    const id = event.sessionID;
    const session = await ctx.session.get({ sessionID:id });
    if (session.parentID) throw Error("Harness: only the task parent may delegate.");
    const task = await ctx.storage.get(taskKey(id));
    if (!task?.active) throw Error("No active root task for delegation");
    const explicitSol = typeof event.input?.model === "string" && /^openai\/gpt-6\.2-sol(?:#|$)/.test(event.input.model);
    if (explicitSol && role !== "advisor") throw Error("Harness: Sol is reserved for the focused advisor.");
    await locked(id, async () => {
      const state = await read(id);
      const active = await running(id,state);
      const pending = state.pending || [];
      if (role === "worker" && active.filter(x=>x.role==="worker").length + pending.filter(x=>x.role==="worker").length >= 2)
        throw Error("Harness: at most two active workers.");
      if (role === "advisor" || role === "reviewer") {
        const limit = role === "advisor" ? 1 : 2;
        if ((state[role] || 0) >= limit) throw Error("Harness: " + role + " attempt budget exhausted.");
        state[role] = (state[role] || 0) + 1;
      }
      if (role === "advisor") event.input = {...event.input, model:"openai/gpt-6.2-sol#medium"};
      if (typeof event.id !== "string" || !event.id) throw Error("Missing child dispatch identifier");
      state.pending = [...pending,{call:event.id,role}];
      await ctx.storage.set(key(id),state);
    });
  });
  await ctx.tool.hook("execute.after", async event => {
    if (event.tool !== "subagent") return;
    const id = event.sessionID;
    await locked(id, async()=>{
      const state = await read(id);
      const pending = (state.pending || []).find(x=>x.call===event.id);
      if (!pending) return;
      const childID = event.result?.output?.sessionID || event.result?.metadata?.sessionID;
      // A completed dispatch without a session ID cannot prove completion.
      if (event.status === "completed" && !childID) return;
      state.pending = state.pending.filter(x=>x.call!==event.id);
      if (typeof childID === "string" && childID && !(state.children || []).some(x=>x.id===childID)) {
        state.children = [...(state.children || []),{id:childID,role:pending.role}];
      }
      await ctx.storage.set(key(id),state);
    });
  });
  return {
    status,
    sessions: async id => [id,...(await read(id)).children.map(x=>x.id)],
    clear: id => locked(id, () => ctx.storage.remove(key(id)))
  };
}
