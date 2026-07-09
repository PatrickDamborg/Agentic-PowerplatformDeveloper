import { finaliseAgent } from "../data/agents";
import type { Agent, AgentAction, ResponseOption, Run } from "../data/types";

// Interactive demo backend: a mutable in-memory store exposed through the same
// provider surfaces the live Dataverse code uses. Firing an agent streams fake
// action rows; answering an approval resumes the fake run.

const MIN = 60000;
let seq = 0;
const nid = () => `demo-${++seq}`;

function run(agoMin: number, status: Run["status"], durMin?: number, trigger = "Scheduled", error = ""): Run {
  const now = Date.now();
  return {
    id: nid(),
    start: new Date(now - agoMin * MIN),
    end: status === "running" ? null : new Date(now - (agoMin - (durMin || 1)) * MIN),
    durationMs: status === "running" ? null : (durMin || 1) * MIN,
    status,
    trigger,
    flowType: 3,
    error
  };
}

function agent(name: string, guidTail: string, runs: Run[], triggerUrl = "https://demo.invalid/workflows/trigger"): Agent {
  const targetId = `00000000-0000-0000-0000-0000000000${guidTail}`;
  return finaliseAgent({
    id: `auto-${targetId}`,
    name,
    targetId,
    triggerUrl,
    monitoredAgentId: targetId,
    scope: "initiative",
    sourceName: name,
    workflowIdUnique: null,
    active: true,
    warning: null,
    runs,
    running: [],
    today: [],
    failedToday: [],
    lastActivity: null,
    avgDurationMs: null
  });
}

function action(
  a: Agent,
  agoMin: number,
  name: string,
  status: AgentAction["status"],
  type: AgentAction["type"] = "step",
  detail = ""
): AgentAction {
  const start = new Date(Date.now() - agoMin * MIN);
  return {
    id: nid(),
    agentId: a.targetId,
    runId: `demo-run-${a.targetId}`,
    name,
    type,
    status,
    detail,
    response: null,
    responseOption: null,
    start,
    end: status === "completed" || status === "failed" ? new Date(+start + 40000) : null,
    createdOn: start
  };
}

class DemoStore {
  agents: Agent[];
  actions = new Map<string, AgentAction[]>(); // agent targetId → rows

  constructor() {
    const reporter = agent("Weekly Status Report Agent", "11", [
      run(3, "running"),
      run(70, "success", 6),
      run(200, "success", 5),
      run(1450, "success", 7)
    ]);
    const risk = agent("Risk Escalation Agent", "12", [
      run(12, "running", undefined, "Automated"),
      run(160, "success", 3, "Automated"),
      run(400, "success", 2, "Automated")
    ]);
    const rebalancer = agent("Resource Rebalancer", "13", [
      run(180, "success", 4),
      run(1600, "success", 4),
      run(3000, "success", 5)
    ]);
    const chaser = agent("Invoice Chaser", "14", [
      run(45, "failed", 2, "Scheduled",
        "Action 'Get_vendor_contact' failed: contact not resolved for vendor V-0087."),
      run(300, "success", 2),
      run(1500, "success", 3)
    ]);
    this.agents = [reporter, risk, rebalancer, chaser];

    this.actions.set(reporter.targetId, [
      action(reporter, 3, "Read project register", "completed"),
      action(reporter, 2.4, "Summarize sprint progress", "completed"),
      action(reporter, 1.5, "Draft weekly status report", "running", "step",
        "Composing summary for 7 active projects…")
    ]);

    this.actions.set(risk.targetId, [
      action(risk, 12, "Scan project risk register", "completed"),
      action(risk, 11, "Detect budget overrun on PRJ-0042", "completed"),
      action(risk, 10, "Escalation approval", "waiting", "approval",
        "Budget overrun of 18% detected on PRJ-0042. Approve sending the escalation email to the steering group?")
    ]);

    this.actions.set(chaser.targetId, [
      action(chaser, 46, "Load overdue invoices", "completed"),
      action(chaser, 45, "Resolve vendor contact", "failed", "step",
        "Contact not resolved for vendor V-0087.")
    ]);
    this.actions.set(rebalancer.targetId, []);
  }

  getActions(agentId: string): AgentAction[] {
    return [...(this.actions.get(agentId) || [])];
  }

  pendingApprovals(): AgentAction[] {
    return [...this.actions.values()]
      .flat()
      .filter((x) => (x.type === "approval" || x.type === "input") && x.status === "waiting");
  }

  /** Fire: stream fake steps every ~2 s — the demo money shot. */
  fire(agentTargetId: string, fireId: string): void {
    const a = this.agents.find((x) => x.targetId === agentTargetId);
    if (!a) return;
    const rows = this.actions.get(agentTargetId) || [];
    rows.length = 0;
    this.actions.set(agentTargetId, rows);

    const liveRun: Run = { ...run(0, "running", undefined, "Manual"), start: new Date() };
    a.runs = [liveRun, ...a.runs];
    finaliseAgent(a);

    const steps = ["Reading project register", "Drafting summary", "Posting to Teams"];
    const push = (name: string, i: number) => {
      const row: AgentAction = {
        id: nid(),
        agentId: agentTargetId,
        runId: fireId,
        name,
        type: "step",
        status: "running",
        detail: "",
        response: null,
        responseOption: null,
        start: new Date(),
        end: null,
        createdOn: new Date()
      };
      rows.push(row);
      setTimeout(() => {
        row.status = "completed";
        row.end = new Date();
        if (i === steps.length - 1) {
          liveRun.status = "success";
          liveRun.end = new Date();
          liveRun.durationMs = +liveRun.end - +(liveRun.start as Date);
          finaliseAgent(a);
        }
      }, 1800);
    };
    steps.forEach((name, i) => setTimeout(() => push(name, i), 400 + i * 2200));
  }

  /** Approve/reject: the fake workflow resumes ~2 s later. */
  respond(actionId: string, option: ResponseOption, response: string): boolean {
    for (const [agentId, rows] of this.actions) {
      const row = rows.find((x) => x.id === actionId);
      if (!row) continue;
      row.status = "completed";
      row.responseOption = option;
      row.response = response || null;
      row.end = new Date();
      const a = this.agents.find((x) => x.targetId === agentId);
      setTimeout(() => {
        const followUps =
          option === "approved"
            ? ["Send escalation email to steering group", "Log escalation in risk register"]
            : ["Log rejection and snooze risk for 7 days"];
        followUps.forEach((name, i) => {
          setTimeout(() => {
            const fu: AgentAction = {
              id: nid(),
              agentId,
              runId: row.runId,
              name,
              type: "step",
              status: "running",
              detail: "",
              response: null,
              responseOption: null,
              start: new Date(),
              end: null,
              createdOn: new Date()
            };
            rows.push(fu);
            setTimeout(() => {
              fu.status = "completed";
              fu.end = new Date();
              if (i === followUps.length - 1 && a) {
                const lr = a.runs.find((r) => r.status === "running");
                if (lr) {
                  lr.status = "success";
                  lr.end = new Date();
                  lr.durationMs = lr.start ? +lr.end - +lr.start : null;
                }
                finaliseAgent(a);
              }
            }, 1500);
          }, i * 2000);
        });
      }, 800);
      return true;
    }
    return false;
  }
}

let store: DemoStore | null = null;
export function demoStore(): DemoStore {
  if (!store) store = new DemoStore();
  return store;
}
