export type RunStatus = "success" | "failed" | "cancelled" | "running" | "completed";

export interface Run {
  id: string;
  start: Date | null;
  end: Date | null;
  durationMs: number | null;
  status: RunStatus;
  trigger: string;
  flowType?: number;
  error: string;
}

export type AgentStatus = "waiting-input" | "running" | "failed" | "idle" | "offline";

export interface Agent {
  id: string;
  name: string;
  targetId: string;
  triggerUrl: string | null;
  monitoredAgentId: string | null;
  sourceName: string | null;
  workflowIdUnique: string | null;
  active: boolean | null;
  warning: string | null;
  runs: Run[];
  running: Run[];
  today: Run[];
  failedToday: Run[];
  lastActivity: Date | null;
  avgDurationMs: number | null;
}

export type ActionType = "step" | "approval" | "input";
export type ActionStatus = "running" | "completed" | "failed" | "waiting";
export type ResponseOption = "approved" | "rejected";

export interface AgentAction {
  id: string;
  agentId: string;
  runId: string | null;
  name: string;
  type: ActionType;
  status: ActionStatus;
  detail: string;
  response: string | null;
  responseOption: ResponseOption | null;
  start: Date | null;
  end: Date | null;
  createdOn: Date | null;
}

export type FirePhase = "sent" | "confirmed" | "timeout" | "error";

export interface FireState {
  fireId: string;
  firedAt: Date;
  phase: FirePhase;
}
