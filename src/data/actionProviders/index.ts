import { demoStore } from "../../demo/demoStore";
import type { Agent, AgentAction } from "../types";
import { agentActionProvider } from "./agentActionProvider";
import { flowRunProvider } from "./flowRunProvider";
import type { RunActionsProvider } from "./types";

const demoProvider: RunActionsProvider = {
  id: "demo",
  async isAvailable() {
    return true;
  },
  async getActions(agent: Agent) {
    return demoStore().getActions(agent.targetId);
  }
};

let resolved: RunActionsProvider[] | null = null;

async function resolveProviders(demo: boolean): Promise<RunActionsProvider[]> {
  if (resolved) return resolved;
  const chain = demo ? [demoProvider] : [agentActionProvider, flowRunProvider];
  const checks = await Promise.all(chain.map((p) => p.isAvailable().catch(() => false)));
  resolved = chain.filter((_, i) => checks[i]);
  return resolved;
}

/**
 * Walk the provider chain; the first non-null answer wins.
 * Returns the provider id alongside the rows so the UI can hint at the source.
 */
export async function getRunActions(
  demo: boolean,
  agent: Agent,
  runId?: string
): Promise<{ providerId: RunActionsProvider["id"] | null; actions: AgentAction[] }> {
  for (const p of await resolveProviders(demo)) {
    try {
      const actions = await p.getActions(agent, runId);
      if (actions && actions.length) return { providerId: p.id, actions };
    } catch {
      /* provider failed — fall through */
    }
  }
  return { providerId: null, actions: [] };
}
