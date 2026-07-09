import { makeStyles, Spinner, Text, tokens } from "@fluentui/react-components";
import {
  CheckmarkCircleFilled, DismissCircleFilled, PersonClockRegular
} from "@fluentui/react-icons";
import { fmtDuration, fmtTime } from "../data/format";
import type { AgentAction } from "../data/types";
import { retro } from "../theme";

const useStyles = makeStyles({
  list: { display: "flex", flexDirection: "column" },
  row: {
    display: "grid",
    gridTemplateColumns: "24px 1fr auto",
    columnGap: "10px",
    alignItems: "start",
    padding: "8px 0",
    borderBottom: `1px solid ${tokens.colorNeutralStroke2}`
  },
  icon: { paddingTop: "2px" },
  name: { fontWeight: 600, fontSize: "13px" },
  detail: { fontSize: "12px", color: tokens.colorNeutralForeground3, whiteSpace: "pre-wrap" },
  failedDetail: { color: retro.red },
  response: { fontSize: "12px", color: retro.amber },
  when: { fontSize: "11px", color: tokens.colorNeutralForeground3, textAlign: "right" },
  empty: {
    fontFamily: retro.fontMono,
    fontSize: "12px",
    color: retro.greenSoft,
    backgroundColor: "#11111b",
    border: `1px dashed ${retro.muted}`,
    borderRadius: "4px",
    padding: "16px",
    lineHeight: "1.7"
  }
});

function ActionIcon({ action }: { action: AgentAction }) {
  if (action.status === "running") return <Spinner size="extra-tiny" />;
  if (action.status === "waiting")
    return <PersonClockRegular fontSize={18} color={retro.amber} />;
  if (action.status === "failed")
    return <DismissCircleFilled fontSize={18} color={retro.red} />;
  return <CheckmarkCircleFilled fontSize={18} color={retro.green} />;
}

export function ActionTimeline({ actions }: { actions: AgentAction[] }) {
  const styles = useStyles();

  if (!actions.length) {
    return (
      <div className={styles.empty} data-testid="timeline-empty">
        &gt; STEP-LEVEL TELEMETRY NOT CONNECTED_
        <br />
        This agent's workflow hasn't logged any actions yet. Add Dataverse
        "Add a new row" steps to the workflow writing to the pda_agentaction
        table (see the README's workflow contract) and its actions will stream
        here live.
      </div>
    );
  }

  return (
    <div className={styles.list} data-testid="action-timeline">
      {actions.map((a) => (
        <div key={a.id} className={styles.row} data-testid="action-row" data-status={a.status}>
          <span className={styles.icon}>
            <ActionIcon action={a} />
          </span>
          <div>
            <div className={styles.name}>{a.name}</div>
            {a.detail && (
              <div
                className={`${styles.detail} ${a.status === "failed" ? styles.failedDetail : ""}`}
              >
                {a.detail}
              </div>
            )}
            {a.response != null && (
              <div className={styles.response}>
                ↳ {a.responseOption === "rejected" ? "Rejected" : "Approved"}
                {a.response ? `: ${a.response}` : ""}
              </div>
            )}
          </div>
          <div className={styles.when}>
            {a.status === "running" ? (
              <Text size={200} italic>
                in progress
              </Text>
            ) : a.status === "waiting" ? (
              <Text size={200} italic>
                waiting
              </Text>
            ) : (
              <>
                {fmtTime(a.end || a.start)}
                {a.start && a.end ? <div>{fmtDuration(+a.end - +a.start)}</div> : null}
              </>
            )}
          </div>
        </div>
      ))}
    </div>
  );
}
