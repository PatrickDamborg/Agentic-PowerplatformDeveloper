import { Badge, Link, makeStyles, tokens } from "@fluentui/react-components";
import { CONFIG } from "../config";
import { fmtDuration, fmtTime, STATUS_LABEL, timeAgo } from "../data/format";
import type { Agent, Run } from "../data/types";
import { retro } from "../theme";

const useStyles = makeStyles({
  row: {
    display: "grid",
    gridTemplateColumns: "auto 1fr auto auto",
    columnGap: "10px",
    alignItems: "center",
    padding: "7px 0",
    borderBottom: `1px solid ${tokens.colorNeutralStroke2}`
  },
  when: { fontSize: "12px" },
  ago: { fontSize: "11px", color: tokens.colorNeutralForeground3 },
  dur: { fontSize: "11px", color: tokens.colorNeutralForeground3 },
  err: {
    gridColumn: "1 / -1",
    fontSize: "11px",
    color: retro.red,
    whiteSpace: "pre-wrap",
    paddingTop: "2px"
  },
  empty: { fontSize: "12px", color: tokens.colorNeutralForeground3, padding: "8px 0" }
});

const BADGE_COLOR: Record<string, "success" | "danger" | "warning" | "brand" | "informative"> = {
  success: "success",
  completed: "success",
  failed: "danger",
  cancelled: "warning",
  running: "brand"
};

function runLink(agent: Agent, run: Run): string {
  if (!CONFIG.environmentId || !agent.workflowIdUnique) return "";
  return `https://make.powerautomate.com/environments/${CONFIG.environmentId}/flows/${agent.workflowIdUnique}/runs/${run.id}`;
}

export function RecentRuns({ agent }: { agent: Agent }) {
  const styles = useStyles();
  if (!agent.runs.length) {
    return <div className={styles.empty}>No runs recorded yet.</div>;
  }
  return (
    <div data-testid="recent-runs">
      {agent.runs.slice(0, 15).map((r) => {
        const link = runLink(agent, r);
        return (
          <div key={r.id} className={styles.row}>
            <Badge appearance="tint" color={BADGE_COLOR[r.status] || "informative"} size="small">
              {STATUS_LABEL[r.status] || r.status}
            </Badge>
            <div>
              <div className={styles.when}>{fmtTime(r.start)}</div>
              <div className={styles.ago}>
                {timeAgo(r.start)}
                {r.trigger ? ` · ${r.trigger}` : ""}
              </div>
            </div>
            <span className={styles.dur}>
              {r.status === "running" ? "in progress" : fmtDuration(r.durationMs)}
            </span>
            {link ? (
              <Link href={link} target="_blank" rel="noopener">
                Open ↗
              </Link>
            ) : (
              <span />
            )}
            {r.error ? <div className={styles.err}>{String(r.error).slice(0, 400)}</div> : null}
          </div>
        );
      })}
    </div>
  );
}
