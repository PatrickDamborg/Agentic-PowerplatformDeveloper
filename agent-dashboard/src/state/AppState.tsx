import {
  Toast, Toaster, ToastTitle, useId, useToastController
} from "@fluentui/react-components";
import {
  createContext, useCallback, useContext, useMemo, useRef, useState, type ReactNode
} from "react";
import { resolveClientUrl } from "../api/dataverse";
import { fireAgent, pollForRunEvidence } from "../api/fireAgent";
import type { BrowseRecord } from "../api/projects";
import { CONFIG } from "../config";
import { agentStatus, loadAgents, SetupRequiredError } from "../data/agents";
import { loadPendingApprovals, respondToApproval } from "../data/approvals";
import type { Agent, AgentAction, AgentStatus, FireState, ResponseOption } from "../data/types";
import { demoStore } from "../demo/demoStore";
import { usePolling } from "../hooks/usePolling";
import type { ThemeMode } from "../theme";

export const THEME_STORAGE_KEY = "pda-agent-dashboard-theme";

export function loadThemeMode(): ThemeMode {
  const stored = localStorage.getItem(THEME_STORAGE_KEY);
  return stored === "dark" ? "dark" : "light";
}

export interface AppState {
  demo: boolean;
  agents: Agent[];
  agentsLoading: boolean;
  agentsError: Error | null;
  setupRequired: boolean;
  refreshAgents: () => void;
  autoRefresh: boolean;
  setAutoRefresh: (v: boolean) => void;
  themeMode: ThemeMode;
  toggleThemeMode: () => void;

  approvals: AgentAction[];
  respond: (action: AgentAction, option: ResponseOption, response: string) => Promise<void>;

  fireStates: Map<string, FireState>;
  fire: (agent: Agent, project?: BrowseRecord | null) => Promise<void>;

  pickerAgent: Agent | null;
  requestFire: (agent: Agent) => void;
  cancelPicker: () => void;
  confirmPicker: (project: BrowseRecord) => Promise<void>;

  openAgentId: string | null;
  setOpenAgentId: (id: string | null) => void;

  statusOf: (agent: Agent) => AgentStatus;
  query: string;
  setQuery: (q: string) => void;
}

const Ctx = createContext<AppState | null>(null);

export function useApp(): AppState {
  const v = useContext(Ctx);
  if (!v) throw new Error("useApp outside provider");
  return v;
}

const isDemo = () =>
  !resolveClientUrl() || new URLSearchParams(location.search).has("demo");

export function AppStateProvider({
  themeMode,
  toggleThemeMode,
  children
}: {
  themeMode: ThemeMode;
  toggleThemeMode: () => void;
  children: ReactNode;
}) {
  const demo = useMemo(isDemo, []);
  const [autoRefresh, setAutoRefresh] = useState(true);
  const [openAgentId, setOpenAgentId] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [fireStates, setFireStates] = useState<Map<string, FireState>>(new Map());
  const [setupRequired, setSetupRequired] = useState(false);
  const [pickerAgent, setPickerAgent] = useState<Agent | null>(null);
  const fireTimers = useRef(new Map<string, number>());

  const toasterId = useId("toaster");
  const { dispatchToast } = useToastController(toasterId);
  const notify = useCallback(
    (intent: "success" | "info" | "warning" | "error", title: string) =>
      dispatchToast(
        <Toast>
          <ToastTitle>{title}</ToastTitle>
        </Toast>,
        { intent, timeout: 5000 }
      ),
    [dispatchToast]
  );

  const {
    data: agents,
    loading: agentsLoading,
    error: agentsError,
    refresh: refreshAgents
  } = usePolling<Agent[]>(
    async () => {
      if (demo) return [...demoStore().agents];
      try {
        setSetupRequired(false);
        return await loadAgents();
      } catch (e) {
        if (e instanceof SetupRequiredError) {
          setSetupRequired(true);
          return [];
        }
        throw e;
      }
    },
    // Demo agents mutate in place (fires/approvals); poll fast so cards track.
    demo ? 2000 : CONFIG.agentsRefreshSeconds * 1000,
    autoRefresh || demo
  );

  const { data: approvals, refresh: refreshApprovals } = usePolling<AgentAction[]>(
    () => loadPendingApprovals(demo),
    demo ? CONFIG.demoActionsRefreshMs : CONFIG.approvalsRefreshMs
  );

  const setFire = useCallback((agentId: string, fs: FireState | null) => {
    setFireStates((prev) => {
      const next = new Map(prev);
      if (fs) next.set(agentId, fs);
      else next.delete(agentId);
      return next;
    });
  }, []);

  const fire = useCallback(
    async (agent: Agent, project?: BrowseRecord | null) => {
      const existing = fireTimers.current.get(agent.id);
      if (existing) window.clearInterval(existing);

      let result;
      try {
        result = await fireAgent(demo, agent, project);
      } catch (e: any) {
        notify("error", `Could not fire ${agent.name}: ${e.message}`);
        throw e;
      }
      setFire(agent.id, {
        fireId: result.fireId,
        firedAt: result.firedAt,
        phase: result.confirmedByResponse ? "confirmed" : "sent"
      });
      setOpenAgentId(agent.id);

      if (demo) {
        notify("success", `${agent.name} is running`);
        window.setTimeout(() => setFire(agent.id, null), 8000);
        refreshAgents();
        return;
      }
      if (result.confirmedByResponse) {
        notify("success", `${agent.name} is running (workflow confirmed)`);
        window.setTimeout(() => setFire(agent.id, null), 15000);
        refreshAgents();
        return;
      }
      notify("info", `Trigger sent to ${agent.name} — waiting for the run to appear`);

      // Unconfirmed (CORS-blocked response): poll Dataverse for evidence.
      const deadline = Date.now() + CONFIG.fireConfirmTimeoutMs;
      const timer = window.setInterval(async () => {
        const found = await pollForRunEvidence(agent, result.fireId, result.firedAt);
        if (found) {
          window.clearInterval(timer);
          fireTimers.current.delete(agent.id);
          setFire(agent.id, { ...result, phase: "confirmed" });
          notify("success", `${agent.name} is running`);
          refreshAgents();
          window.setTimeout(() => setFire(agent.id, null), 15000);
        } else if (Date.now() > deadline) {
          window.clearInterval(timer);
          fireTimers.current.delete(agent.id);
          setFire(agent.id, { ...result, phase: "timeout" });
          notify(
            "warning",
            `No run detected for ${agent.name} — check the trigger URL and that the workflow is on`
          );
        }
      }, CONFIG.fireConfirmPollMs);
      fireTimers.current.set(agent.id, timer);
    },
    [demo, refreshAgents, setFire, notify]
  );

  const requestFire = useCallback((agent: Agent) => {
    setPickerAgent(agent);
  }, []);

  const cancelPicker = useCallback(() => {
    setPickerAgent(null);
  }, []);

  const confirmPicker = useCallback(
    async (project: BrowseRecord) => {
      const agent = pickerAgent;
      if (!agent) return;
      setPickerAgent(null);
      await fire(agent, project);
    },
    [pickerAgent, fire]
  );

  const respond = useCallback(
    async (action: AgentAction, option: ResponseOption, response: string) => {
      await respondToApproval(demo, action, option, response);
      notify(
        option === "approved" ? "success" : "info",
        `${option === "approved" ? "Approved" : "Rejected"}: ${action.name} — the workflow will resume`
      );
      refreshApprovals();
      refreshAgents();
    },
    [demo, refreshApprovals, refreshAgents, notify]
  );

  const approvalAgentIds = useMemo(
    () => new Set((approvals || []).map((x) => x.agentId)),
    [approvals]
  );

  const statusOf = useCallback(
    (agent: Agent) =>
      agentStatus(agent, fireStates.get(agent.id), approvalAgentIds.has(agent.targetId)),
    [fireStates, approvalAgentIds]
  );

  const value: AppState = {
    demo,
    agents: agents || [],
    agentsLoading,
    agentsError,
    setupRequired,
    refreshAgents,
    autoRefresh,
    setAutoRefresh,
    themeMode,
    toggleThemeMode,
    approvals: approvals || [],
    respond,
    fireStates,
    fire,
    pickerAgent,
    requestFire,
    cancelPicker,
    confirmPicker,
    openAgentId,
    setOpenAgentId,
    statusOf,
    query,
    setQuery
  };

  return (
    <Ctx.Provider value={value}>
      <Toaster toasterId={toasterId} position="bottom-end" />
      {children}
    </Ctx.Provider>
  );
}
