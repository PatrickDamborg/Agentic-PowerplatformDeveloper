import { Card, CounterBadge, makeStyles, tokens } from "@fluentui/react-components";
import { useApp } from "../state/AppState";
import { retro } from "../theme";

const useStyles = makeStyles({
  strip: {
    display: "grid",
    gridTemplateColumns: "repeat(auto-fit, minmax(140px, 1fr))",
    gap: "12px"
  },
  kpi: { padding: "12px 16px", rowGap: "2px" },
  value: { fontSize: "26px", fontWeight: 700, lineHeight: "1.2", fontFamily: retro.fontMono },
  accent: { color: retro.sky },
  warn: { color: retro.red },
  amber: { color: retro.amber },
  label: {
    fontSize: "11px",
    textTransform: "uppercase",
    letterSpacing: "0.5px",
    color: tokens.colorNeutralForeground3,
    display: "flex",
    alignItems: "center",
    columnGap: "6px"
  }
});

export function KpiStrip() {
  const styles = useStyles();
  const { agents, approvals } = useApp();
  const running = agents.reduce((s, a) => s + a.running.length, 0);
  const today = agents.reduce((s, a) => s + a.today.length, 0);
  const failed = agents.reduce((s, a) => s + a.failedToday.length, 0);

  const kpis = [
    { label: "Autonomous agents", value: agents.length, cls: "" },
    { label: "Running now", value: running, cls: running ? styles.accent : "" },
    { label: "Runs today", value: today, cls: "" },
    { label: "Failed today", value: failed, cls: failed ? styles.warn : "" },
    { label: "Awaiting input", value: approvals.length, cls: approvals.length ? styles.amber : "" }
  ];

  return (
    <div className={styles.strip} data-testid="kpi-strip">
      {kpis.map((k) => (
        <Card key={k.label} className={styles.kpi} data-testid="kpi">
          <div className={`${styles.value} ${k.cls}`}>{k.value}</div>
          <div className={styles.label}>
            {k.label}
            {k.label === "Awaiting input" && approvals.length > 0 && (
              <CounterBadge count={approvals.length} color="danger" size="small" />
            )}
          </div>
        </Card>
      ))}
    </div>
  );
}
