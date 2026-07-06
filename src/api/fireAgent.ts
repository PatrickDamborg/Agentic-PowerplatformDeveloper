import { CONFIG } from "../config";
import { api } from "./dataverse";
import { demoStore } from "../demo/demoStore";
import type { Agent } from "../data/types";

export interface FireResult {
  fireId: string;
  firedAt: Date;
  /** true = the workflow answered with a CORS-enabled Response node. */
  confirmedByResponse: boolean;
}

/**
 * Fire the agent's workflow with a single HTTP POST.
 *
 * CORS strategy (see README): the request is "simple-request" shaped
 * (text/plain, no custom headers) so the browser never sends an OPTIONS
 * preflight — the workflow trigger cannot answer one. If the workflow
 * includes a Response node with an Access-Control-Allow-Origin header, we can
 * read the reply and confirm immediately. If not, fetch throws a TypeError
 * AFTER the POST was delivered — the run almost certainly started, so we do
 * NOT retry (a resend would double-trigger). Confirmation then comes from
 * polling Dataverse (pollForRunEvidence).
 */
export async function fireAgent(demo: boolean, agent: Agent): Promise<FireResult> {
  const fireId = crypto.randomUUID();
  const firedAt = new Date();

  if (demo) {
    demoStore().fire(agent.targetId, fireId);
    return { fireId, firedAt, confirmedByResponse: false };
  }

  if (!agent.triggerUrl) throw new Error("No trigger URL configured for this agent.");

  const body = JSON.stringify({ fireId, agentId: agent.targetId, firedBy: "dashboard" });
  try {
    const res = await fetch(agent.triggerUrl, {
      method: "POST",
      headers: { "Content-Type": "text/plain;charset=UTF-8" },
      body
    });
    if (res.ok) return { fireId, firedAt, confirmedByResponse: true };
    throw new Error(`Trigger returned HTTP ${res.status}`);
  } catch (e) {
    if (e instanceof TypeError) {
      // CORS read-block: delivered but unreadable. Fired, unconfirmed.
      return { fireId, firedAt, confirmedByResponse: false };
    }
    throw e;
  }
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
