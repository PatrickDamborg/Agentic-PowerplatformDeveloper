import type { Agent, AgentAction } from "../types";

/**
 * Pluggable source for "what is this run doing right now".
 * Step-level telemetry for the new Copilot Studio Workflows experience is not
 * (yet) exposed through the Dataverse Web API — when tomorrow's investigation
 * finds a native source, implement one more provider and add it to the
 * resolution list in ./index.ts. No UI changes needed.
 */
export interface RunActionsProvider {
  id: "pda_agentaction" | "flowrun" | "demo" | "native-todo";
  /** Probed once at startup; unavailable providers are skipped. */
  isAvailable(): Promise<boolean>;
  /** null = "this provider cannot answer for this agent" (fall through). */
  getActions(agent: Agent, runId?: string): Promise<AgentAction[] | null>;
}
