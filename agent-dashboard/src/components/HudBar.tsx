import { makeStyles } from "@fluentui/react-components";
import type { Agent, AgentStatus } from "../data/types";
import { retro } from "../theme";

// Retro HUD above each pixel worker: status label + "fuel" bar driven by the
// agent's average run duration (port of legacy fuelBarClass/fuelBarWidth/hudFuel).

const useStyles = makeStyles({
  hud: { display: "flex", flexDirection: "column", alignItems: "center", rowGap: "3px" },
  label: {
    fontFamily: retro.fontPixel,
    fontSize: "15px",
    letterSpacing: "1px",
    lineHeight: "1"
  },
  track: {
    width: "64px",
    height: "6px",
    backgroundColor: "#11111b",
    border: `1px solid ${retro.muted}`,
    overflow: "hidden"
  },
  bar: { height: "100%", transition: "width .6s ease" }
});

const HUD_LABEL: Record<AgentStatus, string> = {
  running: "TYPING…",
  "waiting-input": "AWAITING PM",
  failed: "ERROR",
  offline: "OFFLINE",
  idle: "IDLE"
};

const HUD_COLOR: Record<AgentStatus, string> = {
  running: retro.sky,
  "waiting-input": retro.amber,
  failed: retro.red,
  offline: retro.muted,
  idle: retro.green
};

function fuel(avgMs: number | null, status: AgentStatus): { color: string; width: string } {
  if (status === "waiting-input") return { color: retro.amber, width: "50%" };
  if (!avgMs) return { color: retro.green, width: "8%" };
  const s = avgMs / 1000;
  const color = s < 15 ? retro.green : s < 60 ? retro.sky : s < 180 ? retro.orange : retro.red;
  const width = Math.min(100, Math.max(5, (s / 300) * 100)).toFixed(0) + "%";
  return { color, width };
}

export function HudBar({ agent, status }: { agent: Agent; status: AgentStatus }) {
  const styles = useStyles();
  const f = fuel(agent.avgDurationMs, status);
  return (
    <div className={styles.hud}>
      <div className={styles.label} style={{ color: HUD_COLOR[status] }}>
        {HUD_LABEL[status]}
      </div>
      <div className={styles.track}>
        <div className={styles.bar} style={{ width: f.width, backgroundColor: f.color }} />
      </div>
    </div>
  );
}
