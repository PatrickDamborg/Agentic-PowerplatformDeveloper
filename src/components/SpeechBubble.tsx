import { makeStyles } from "@fluentui/react-components";
import { timeAgo } from "../data/format";
import type { Agent, AgentStatus, FireState } from "../data/types";
import { retro } from "../theme";

const useStyles = makeStyles({
  speech: {
    fontFamily: retro.fontMono,
    fontSize: "11px",
    color: retro.greenSoft,
    backgroundColor: "#11111b",
    border: `1px solid ${retro.muted}`,
    borderRadius: "3px",
    padding: "3px 8px",
    maxWidth: "100%",
    overflow: "hidden",
    textOverflow: "ellipsis",
    whiteSpace: "nowrap"
  },
  err: { color: retro.red },
  amber: { color: retro.amber },
  cursor: {
    animationName: { "0%": { opacity: 1 }, "50%": { opacity: 0 }, "100%": { opacity: 1 } },
    animationDuration: "1s",
    animationIterationCount: "infinite"
  }
});

export function SpeechBubble({
  agent, status, fire
}: {
  agent: Agent;
  status: AgentStatus;
  fire?: FireState;
}) {
  const styles = useStyles();
  const cursor = <span className={styles.cursor}>_</span>;

  if (fire && (fire.phase === "sent" || fire.phase === "confirmed")) {
    return (
      <div className={styles.speech}>
        {fire.phase === "sent" ? "Trigger sent, waking up" : "On it, boss"} {cursor}
      </div>
    );
  }
  if (status === "waiting-input") {
    return <div className={`${styles.speech} ${styles.amber}`}>Needs your input {cursor}</div>;
  }
  if (status === "running" && agent.running.length) {
    const r = agent.running[0];
    const more = agent.running.length > 1 ? ` +${agent.running.length - 1}` : "";
    return (
      <div className={styles.speech}>
        {r.trigger || "Run"} started {timeAgo(r.start)}
        {more} {cursor}
      </div>
    );
  }
  if (status === "failed") {
    const n = agent.failedToday.length;
    return (
      <div className={`${styles.speech} ${styles.err}`}>
        {n} failure{n > 1 ? "s" : ""} today
      </div>
    );
  }
  return null;
}
