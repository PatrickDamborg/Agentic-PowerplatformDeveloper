import { api } from "../../api/dataverse";
import { CONFIG } from "../../config";
import type { Agent, AgentAction, ActionStatus, ActionType, ResponseOption } from "../types";
import type { RunActionsProvider } from "./types";

const t = CONFIG.actionTable;

const TYPE_BY_VALUE: Record<number, ActionType> = {
  [t.typeValues.step]: "step",
  [t.typeValues.approval]: "approval",
  [t.typeValues.input]: "input"
};
const STATUS_BY_VALUE: Record<number, ActionStatus> = {
  [t.statusValues.running]: "running",
  [t.statusValues.completed]: "completed",
  [t.statusValues.failed]: "failed",
  [t.statusValues.waiting]: "waiting"
};
const RESPONSE_BY_VALUE: Record<number, ResponseOption> = {
  [t.responseValues.approved]: "approved",
  [t.responseValues.rejected]: "rejected"
};

export function mapActionRow(r: any): AgentAction {
  return {
    id: r[t.idCol],
    agentId: r[t.agentIdCol] || "",
    runId: r[t.runIdCol] || null,
    name: r[t.nameCol] || "Step",
    type: TYPE_BY_VALUE[r[t.typeCol]] ?? "step",
    status: STATUS_BY_VALUE[r[t.statusCol]] ?? "running",
    detail: r[t.detailCol] || "",
    response: r[t.responseCol] || null,
    responseOption: RESPONSE_BY_VALUE[r[t.responseOptionCol]] ?? null,
    start: r[t.startCol] ? new Date(r[t.startCol]) : null,
    end: r[t.endCol] ? new Date(r[t.endCol]) : null,
    createdOn: r.createdon ? new Date(r.createdon) : null
  };
}

const SELECT = [
  t.idCol, t.nameCol, t.agentIdCol, t.runIdCol, t.typeCol, t.statusCol,
  t.detailCol, t.responseCol, t.responseOptionCol, t.startCol, t.endCol, "createdon"
].join(",");

/**
 * Provider A (default contract): the agent workflow logs its own steps into
 * pda_agentaction via Dataverse "Add a new row" nodes. See README.
 */
export const agentActionProvider: RunActionsProvider = {
  id: "pda_agentaction",

  async isAvailable() {
    try {
      await api(`${t.entitySet}?$select=${t.idCol}&$top=1`);
      return true;
    } catch {
      return false; // 404 = table not created yet
    }
  },

  async getActions(agent: Agent, runId?: string) {
    const filter = runId
      ? `${t.runIdCol} eq '${runId}'`
      : `${t.agentIdCol} eq '${agent.targetId}'`;
    const data = await api(
      `${t.entitySet}?$select=${SELECT}&$filter=${filter}&$orderby=createdon asc&$top=100`
    );
    const rows = (data.value as any[]).map(mapActionRow);
    if (!runId) {
      // Latest run only: rows correlate by pda_runid; fall back to "today".
      const latest = rows.length ? rows[rows.length - 1].runId : null;
      return latest ? rows.filter((x) => x.runId === latest) : rows;
    }
    return rows;
  }
};
