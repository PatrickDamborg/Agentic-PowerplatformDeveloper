import { api } from "../api/dataverse";
import { CONFIG } from "../config";
import { cleanGuid, GUID_RE, isToday, normaliseStatus } from "./format";
import type { Agent, AgentStatus, FireState, Run } from "./types";

// Port of loadConfigRows/loadFlowAgent/finaliseAgent (legacy lines 576-692),
// narrowed to autonomous agents only. The config table keeps both choice
// values — the dashboard filter lives here, in the OData query.

interface ConfigRow {
  name: string;
  targetId: string;
  triggerUrl: string | null;
  monitoredAgentId: string | null;
}

async function loadConfigRows(): Promise<ConfigRow[]> {
  const t = CONFIG.configTable;
  const data = await api(
    `${t.entitySet}?$select=${t.nameCol},${t.typeCol},${t.targetCol},${t.triggerUrlCol},${t.idCol}` +
      `&$filter=statecode eq 0 and ${t.typeCol} eq ${t.typeValues.autonomous}` +
      `&$orderby=${t.nameCol} asc`
  );
  return (data.value as any[])
    .map((r) => ({
      name: r[t.nameCol] as string,
      targetId: cleanGuid(r[t.targetCol]),
      triggerUrl: (r[t.triggerUrlCol] as string) || null,
      monitoredAgentId: (r[t.idCol] as string) || null
    }))
    .filter((r) => GUID_RE.test(r.targetId));
}

function baseAgent(cfg: ConfigRow): Agent {
  return {
    id: `auto-${cfg.targetId}`,
    name: cfg.name,
    targetId: cfg.targetId,
    triggerUrl: cfg.triggerUrl,
    monitoredAgentId: cfg.monitoredAgentId,
    sourceName: null,
    workflowIdUnique: null,
    active: null,
    warning: null,
    runs: [],
    running: [],
    today: [],
    failedToday: [],
    lastActivity: null,
    avgDurationMs: null
  };
}

export function finaliseAgent(a: Agent): Agent {
  a.running = a.runs.filter((r) => r.status === "running");
  a.today = a.runs.filter((r) => isToday(r.start));
  a.failedToday = a.today.filter((r) => r.status === "failed");
  a.lastActivity = a.runs.length ? a.runs[0].start : null;
  const done = a.runs.filter((r) => r.durationMs != null);
  a.avgDurationMs = done.length
    ? done.reduce((s, r) => s + (r.durationMs as number), 0) / done.length
    : null;
  return a;
}

async function loadAutonomousAgent(cfg: ConfigRow): Promise<Agent> {
  const agent = baseAgent(cfg);
  try {
    const wf = await api(
      `workflows(${cfg.targetId})?$select=name,statecode,workflowidunique,modifiedon`
    );
    agent.sourceName = wf.name;
    agent.active = wf.statecode === 1;
    agent.workflowIdUnique = wf.workflowidunique;
  } catch (e: any) {
    agent.warning = `Workflow not found (${e.message})`;
  }
  try {
    const data = await api(
      `flowruns?$select=name,starttime,endtime,duration,status,triggertype,errorcode,errormessage,modernflowtype` +
        `&$filter=_workflow_value eq ${cfg.targetId}&$orderby=starttime desc&$top=${CONFIG.runsPerAgent}`
    );
    agent.runs = (data.value as any[]).map((r): Run => {
      const start = r.starttime ? new Date(r.starttime) : null;
      const end = r.endtime ? new Date(r.endtime) : null;
      return {
        id: r.name,
        start,
        end,
        durationMs:
          r.duration != null ? Number(r.duration) : start && end ? +end - +start : null,
        status: normaliseStatus(r.status, end),
        trigger: r.triggertype || "",
        flowType: r.modernflowtype,
        error: r.errormessage || r.errorcode || ""
      };
    });
  } catch (e: any) {
    agent.warning = agent.warning || `Runs unavailable (${e.message})`;
  }
  return finaliseAgent(agent);
}

export class SetupRequiredError extends Error {
  constructor() {
    super("Config table not found");
  }
}

export async function loadAgents(): Promise<Agent[]> {
  let rows: ConfigRow[];
  try {
    rows = await loadConfigRows();
  } catch (e: any) {
    if (e.status === 404) throw new SetupRequiredError();
    throw e;
  }
  return Promise.all(rows.map(loadAutonomousAgent));
}

/** Derived status driving the Badge + sprite: waiting > running > failed > idle. */
export function agentStatus(
  a: Agent,
  fire: FireState | undefined,
  hasPendingApproval: boolean
): AgentStatus {
  if (hasPendingApproval) return "waiting-input";
  const optimisticRunning =
    fire && (fire.phase === "sent" || fire.phase === "confirmed");
  if (a.running.length || optimisticRunning) return "running";
  if (a.failedToday.length) return "failed";
  if (a.active === false) return "offline";
  return "idle";
}
