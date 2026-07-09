import {
  Badge, Button, Card, makeStyles, shorthands, tokens, Tooltip
} from "@fluentui/react-components";
import { PlayFilled } from "@fluentui/react-icons";
import { fmtDuration, timeAgo } from "../data/format";
import type { Agent, AgentStatus } from "../data/types";
import { PixelWorker } from "../sprites/PixelWorker";
import type { SpriteAnim } from "../sprites/spriteEngine";
import { useApp } from "../state/AppState";
import { retro } from "../theme";
import { HudBar } from "./HudBar";
import { SpeechBubble } from "./SpeechBubble";

const useStyles = makeStyles({
  card: {
    cursor: "pointer",
    display: "flex",
    flexDirection: "column",
    rowGap: "10px",
    padding: "14px",
    minHeight: "270px",
    position: "relative",
    transition: "border-color .2s ease, box-shadow .2s ease"
  },
  running: { ...shorthands.borderColor(retro.sky), boxShadow: `0 0 12px ${retro.sky}33` },
  failed: { ...shorthands.borderColor(retro.red), boxShadow: `0 0 12px ${retro.red}33` },
  waiting: { ...shorthands.borderColor(retro.amber), boxShadow: `0 0 12px ${retro.amber}33` },
  top: { display: "flex", alignItems: "center", columnGap: "8px" },
  spacer: { flexGrow: 1 },
  spriteWrap: {
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    rowGap: "6px",
    paddingTop: "4px"
  },
  name: {
    fontFamily: retro.fontMono,
    fontSize: "13px",
    letterSpacing: "0.5px",
    textTransform: "uppercase",
    color: tokens.colorNeutralForeground1,
    margin: 0,
    textAlign: "center"
  },
  stats: {
    display: "grid",
    gridTemplateColumns: "1fr 1fr 1fr",
    columnGap: "8px",
    textAlign: "center",
    marginTop: "auto"
  },
  statV: { fontSize: "18px", fontWeight: 600, color: tokens.colorNeutralForeground1 },
  statVWarn: { color: retro.red },
  statK: { fontSize: "10px", color: tokens.colorNeutralForeground3, textTransform: "uppercase" },
  foot: {
    fontSize: "11px",
    color: tokens.colorNeutralForeground3,
    borderTop: `1px solid ${tokens.colorNeutralStroke2}`,
    paddingTop: "6px"
  }
});

const BADGE: Record<AgentStatus, { label: string; color: "informative" | "success" | "danger" | "warning" | "brand" }> = {
  running: { label: "Running", color: "brand" },
  "waiting-input": { label: "Needs input", color: "warning" },
  failed: { label: "Failed", color: "danger" },
  idle: { label: "Idle", color: "success" },
  offline: { label: "Off", color: "informative" }
};

const SPRITE_ANIM: Record<AgentStatus, SpriteAnim> = {
  running: "typing",
  "waiting-input": "idle",
  failed: "error",
  idle: "idle",
  offline: "idle"
};

export function AgentCard({ agent }: { agent: Agent }) {
  const styles = useStyles();
  const { statusOf, fireStates, requestFire, setOpenAgentId, demo } = useApp();
  const status = statusOf(agent);
  const fireState = fireStates.get(agent.id);
  const badge = BADGE[status];
  const canFire = !!agent.targetId || demo;

  const cardStatusClass =
    status === "running" ? styles.running :
    status === "failed" ? styles.failed :
    status === "waiting-input" ? styles.waiting : "";

  const onFire = (e: React.MouseEvent) => {
    e.stopPropagation();
    requestFire(agent);
  };

  return (
    <Card
      className={`${styles.card} ${cardStatusClass}`}
      onClick={() => setOpenAgentId(agent.id)}
      data-testid="agent-card"
      data-agent-name={agent.name}
      data-status={status}
    >
      <div className={styles.top}>
        <Badge appearance="tint" color={badge.color} data-testid="status-badge">
          {badge.label}
        </Badge>
        {agent.active === false && (
          <Badge appearance="outline" color="informative">Inactive</Badge>
        )}
        <div className={styles.spacer} />
        {canFire ? (
          <Tooltip content="Fire this agent now" relationship="label">
            <Button
              appearance={status === "idle" ? "primary" : "secondary"}
              size="small"
              icon={<PlayFilled />}
              disabled={status === "running"}
              onClick={onFire}
              data-testid="fire-button"
            >
              Fire
            </Button>
          </Tooltip>
        ) : (
          <Tooltip
            content="This agent's row is missing a Target Id (pda_targetid) — required to fire it from here"
            relationship="label"
          >
            <Button appearance="secondary" size="small" icon={<PlayFilled />} disabled>
              Fire
            </Button>
          </Tooltip>
        )}
      </div>

      <div className={styles.spriteWrap}>
        <HudBar agent={agent} status={status} />
        <PixelWorker agentId={agent.id} anim={SPRITE_ANIM[status]} />
        <SpeechBubble agent={agent} status={status} fire={fireState} />
      </div>

      <h3 className={styles.name}>{agent.name || agent.sourceName || "Unnamed"}</h3>

      <div className={styles.stats}>
        <div>
          <div className={styles.statV}>{agent.today.length}</div>
          <div className={styles.statK}>runs today</div>
        </div>
        <div>
          <div className={`${styles.statV} ${agent.failedToday.length ? styles.statVWarn : ""}`}>
            {agent.failedToday.length}
          </div>
          <div className={styles.statK}>failed</div>
        </div>
        <div>
          <div className={styles.statV}>
            {agent.avgDurationMs != null ? fmtDuration(agent.avgDurationMs) : "--"}
          </div>
          <div className={styles.statK}>avg dur</div>
        </div>
      </div>

      <div className={styles.foot}>
        {agent.warning ? `[!] ${agent.warning}` : `Last: ${timeAgo(agent.lastActivity)}`}
      </div>
    </Card>
  );
}
