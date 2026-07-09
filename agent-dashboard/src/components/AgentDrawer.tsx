import {
  Badge, Button, Divider, DrawerBody, DrawerHeader, DrawerHeaderTitle,
  Link, makeStyles, OverlayDrawer, tokens
} from "@fluentui/react-components";
import { DismissRegular, PlayFilled } from "@fluentui/react-icons";
import { useMemo } from "react";
import { CONFIG } from "../config";
import { getRunActions } from "../data/actionProviders";
import type { AgentAction } from "../data/types";
import { usePolling } from "../hooks/usePolling";
import { useApp } from "../state/AppState";
import { retro, sectionLabelColor } from "../theme";
import { ActionTimeline } from "./ActionTimeline";
import { ApprovalPanel } from "./ApprovalPanel";
import { RecentRuns } from "./RecentRuns";

const useStyles = makeStyles({
  body: { display: "flex", flexDirection: "column", rowGap: "16px", paddingBottom: "24px" },
  meta: { fontSize: "12px", color: tokens.colorNeutralForeground3 },
  section: {
    fontFamily: retro.fontMono,
    fontSize: "12px",
    textTransform: "uppercase",
    letterSpacing: "1px"
  },
  headerRow: { display: "flex", alignItems: "center", columnGap: "10px" }
});

export function AgentDrawer() {
  const styles = useStyles();
  const {
    agents, openAgentId, setOpenAgentId, statusOf, fireStates, requestFire, demo,
    approvals, respond, themeMode
  } = useApp();

  const agent = agents.find((a) => a.id === openAgentId) || null;
  const open = !!agent;

  const { data: actionsResult } = usePolling(
    async () => {
      if (!agent) return null;
      const fireState = fireStates.get(agent.id);
      return getRunActions(demo, agent, fireState?.fireId);
    },
    demo ? CONFIG.demoActionsRefreshMs : CONFIG.actionsRefreshMs,
    open,
    [agent?.id]
  );

  const pendingForAgent = useMemo(
    () => (agent ? approvals.filter((x) => x.agentId === agent.targetId) : []),
    [agent, approvals]
  );

  // Merge: polled timeline rows, with any pending approval surfaced even if
  // the actions provider hasn't caught up yet.
  const actions: AgentAction[] = useMemo(() => {
    const rows = actionsResult?.actions || [];
    const missing = pendingForAgent.filter((p) => !rows.some((r) => r.id === p.id));
    return [...rows, ...missing];
  }, [actionsResult, pendingForAgent]);

  if (!agent) return null;

  const status = statusOf(agent);
  const studioLink =
    CONFIG.environmentId && agent.workflowIdUnique
      ? `https://make.powerautomate.com/environments/${CONFIG.environmentId}/flows/${agent.workflowIdUnique}/details`
      : "";

  const onFire = () => {
    requestFire(agent);
  };

  return (
    <OverlayDrawer
      open={open}
      onOpenChange={(_, d) => !d.open && setOpenAgentId(null)}
      position="end"
      size="medium"
      data-testid="agent-drawer"
    >
      <DrawerHeader>
        <DrawerHeaderTitle
          action={
            <Button
              appearance="subtle"
              aria-label="Close"
              icon={<DismissRegular />}
              onClick={() => setOpenAgentId(null)}
              data-testid="drawer-close"
            />
          }
        >
          <div className={styles.headerRow}>
            {agent.name}
            <Badge
              appearance="tint"
              color={
                status === "running" ? "brand"
                : status === "failed" ? "danger"
                : status === "waiting-input" ? "warning"
                : "success"
              }
            >
              {status === "waiting-input" ? "Needs input" : status}
            </Badge>
          </div>
        </DrawerHeaderTitle>
      </DrawerHeader>

      <DrawerBody className={styles.body}>
        <div className={styles.meta}>
          Agent workflow{agent.sourceName && agent.sourceName !== agent.name ? `: ${agent.sourceName}` : ""}
          {agent.active != null && <> · {agent.active ? "On" : "Off"}</>}
          {studioLink && (
            <>
              {" · "}
              <Link href={studioLink} target="_blank" rel="noopener">
                Open workflow ↗
              </Link>
            </>
          )}
        </div>

        <div>
          <Button
            appearance="primary"
            icon={<PlayFilled />}
            disabled={status === "running" || (!agent.targetId && !demo)}
            onClick={onFire}
            data-testid="drawer-fire-button"
          >
            {status === "running" ? "Running…" : "Fire agent"}
          </Button>
        </div>

        {pendingForAgent.map((p) => (
          <ApprovalPanel key={p.id} action={p} onRespond={respond} />
        ))}

        <Divider />
        <div className={styles.section} style={{ color: sectionLabelColor[themeMode] }}>
          Current run
          {actionsResult?.providerId === "flowrun" && " (run-level history — step telemetry not connected)"}
        </div>
        <ActionTimeline actions={actions} />

        <Divider />
        <div className={styles.section} style={{ color: sectionLabelColor[themeMode] }}>
          Recent runs ({agent.runs.length})
        </div>
        <RecentRuns agent={agent} />
      </DrawerBody>
    </OverlayDrawer>
  );
}
