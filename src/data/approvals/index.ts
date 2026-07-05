import { api, apiPatch } from "../../api/dataverse";
import { CONFIG } from "../../config";
import { demoStore } from "../../demo/demoStore";
import { mapActionRow } from "../actionProviders/agentActionProvider";
import type { AgentAction, ResponseOption } from "../types";

const t = CONFIG.actionTable;

/**
 * Default approval path (Dataverse-first): pending approvals are
 * pda_agentaction rows with status WaitingForInput. The PM's answer PATCHes
 * the row; the workflow's Do-until loop picks it up and resumes.
 */
export async function loadPendingApprovals(demo: boolean): Promise<AgentAction[]> {
  if (demo) return demoStore().pendingApprovals();
  if (CONFIG.features.msdynApprovals) {
    // Stretch (flagged off): merge native msdyn_flow_approval rows here once
    // responding via msdyn_flow_approvalresponse is validated in this env.
    // See src/data/approvals/msdynApprovalProvider.ts.
  }
  try {
    const data = await api(
      `${t.entitySet}?$select=${t.idCol},${t.nameCol},${t.agentIdCol},${t.runIdCol},${t.typeCol},` +
        `${t.statusCol},${t.detailCol},${t.responseCol},${t.responseOptionCol},${t.startCol},${t.endCol},createdon` +
        `&$filter=${t.statusCol} eq ${t.statusValues.waiting}&$orderby=createdon desc&$top=25`
    );
    return (data.value as any[]).map(mapActionRow);
  } catch {
    return []; // table missing → no approvals surface
  }
}

export async function respondToApproval(
  demo: boolean,
  action: AgentAction,
  option: ResponseOption,
  response: string
): Promise<void> {
  if (demo) {
    demoStore().respond(action.id, option, response);
    return;
  }
  await apiPatch(t.entitySet, action.id, {
    [t.statusCol]: t.statusValues.completed,
    [t.responseOptionCol]: t.responseValues[option],
    [t.responseCol]: response || null,
    [t.endCol]: new Date().toISOString()
  });
}
