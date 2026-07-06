import type { Agent, AgentAction } from "../types";
import type { RunActionsProvider } from "./types";

/**
 * Provider B (fallback): maps run-LEVEL flowruns history to one synthetic
 * action row per run, so the drawer timeline is never useless even before
 * the pda_agentaction contract table exists. Uses the runs already loaded
 * on the agent — no extra query.
 */
export const flowRunProvider: RunActionsProvider = {
  id: "flowrun",

  async isAvailable() {
    return true;
  },

  async getActions(agent: Agent) {
    if (!agent.runs.length) return null;
    return agent.runs.slice(0, 10).map(
      (r): AgentAction => ({
        id: `flowrun-${r.id}`,
        agentId: agent.targetId,
        runId: r.id,
        name:
          r.status === "running"
            ? "Run in progress"
            : `Run ${r.status === "success" ? "succeeded" : r.status}`,
        type: "step",
        status:
          r.status === "running" ? "running" : r.status === "failed" ? "failed" : "completed",
        detail: r.error || (r.trigger ? `Trigger: ${r.trigger}` : ""),
        response: null,
        responseOption: null,
        start: r.start,
        end: r.end,
        createdOn: r.start
      })
    );
  }
};
