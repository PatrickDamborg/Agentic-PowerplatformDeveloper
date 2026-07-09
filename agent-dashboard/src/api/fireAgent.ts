import { CONFIG } from "../config";
import { api, apiPost } from "./dataverse";
import type { BrowseRecord } from "./projects";
import { demoStore } from "../demo/demoStore";
import type { Agent } from "../data/types";

export interface FireResult {
  fireId: string;
  firedAt: Date;
  /** true = the workflow answered with a CORS-enabled Response node. */
  confirmedByResponse: boolean;
}

/**
 * Fire the agent's workflow by writing a row to the custom pda_agentruns table.
 * The workflow's own Dataverse trigger ("When a row is added") reacts to it with
 * a filter on the monitored agent lookup — no HTTP trigger, no OAuth, no secrets,
 * and createdby/modifiedby land on the row as the real signed-in user rather than
 * a shared service identity. See README "Firing agents".
 *
 * `project`, when supplied, is bound to the lookup column matching the agent's
 * scope (pda_initiative / pda_program / pda_portfolio on pda_agentruns).
 *
 * The row write is synchronous (throws on failure) but only confirms Dataverse
 * accepted it — not that the flow has started, since the Dataverse-trigger handoff
 * isn't instantaneous. Actual run confirmation still comes from polling Dataverse
 * (pollForRunEvidence).
 */
export async function fireAgent(
  demo: boolean,
  agent: Agent,
  project?: BrowseRecord | null
): Promise<FireResult> {
  const fireId = crypto.randomUUID();
  const firedAt = new Date();

  if (demo) {
    demoStore().fire(agent.targetId, fireId);
    return { fireId, firedAt, confirmedByResponse: false };
  }

  if (!agent.monitoredAgentId) {
    throw new Error(`${agent.name} has no monitored agent record id`);
  }

  const t = CONFIG.fireTable;
  const body: Record<string, unknown> = {
    [t.nameCol]: agent.name || agent.sourceName || "Agent",
    "pda_agentid": agent.targetId,
    [t.messageCol]: JSON.stringify({ fireId, agentId: agent.targetId, firedBy: "dashboard" }),
    [`${t.agentCol}@odata.bind`]: `/${CONFIG.configTable.entitySet}(${agent.monitoredAgentId})`,
    [t.statusCol]: 100000000
  };

  if (project) {
    const scopeTable = CONFIG.scopeTables[agent.scope];
    body[`${scopeTable.runLookupCol}@odata.bind`] = `/${scopeTable.entitySet}(${project.id})`;
  }

  await apiPost(t.entitySet, body);

  return { fireId, firedAt, confirmedByResponse: false };
}

/**
 * Look for evidence that the fired run actually started: an action row
 * carrying our fireId, or a flowrun that began after we fired.
 */
export async function pollForRunEvidence(
  agent: Agent,
  fireId: string,
  firedAt: Date
): Promise<boolean> {
  const t = CONFIG.actionTable;
  try {
    const data = await api(
      `${t.entitySet}?$select=${t.idCol}&$filter=${t.runIdCol} eq '${fireId}'&$top=1`
    );
    if ((data.value as any[]).length) return true;
  } catch {
    /* table may not exist yet */
  }
  try {
    const data = await api(
      `flowruns?$select=name,starttime&$filter=_workflow_value eq ${agent.targetId}` +
        ` and starttime gt ${firedAt.toISOString()}&$top=1`
    );
    if ((data.value as any[]).length) return true;
  } catch {
    /* flowruns may be unavailable */
  }
  return false;
}
