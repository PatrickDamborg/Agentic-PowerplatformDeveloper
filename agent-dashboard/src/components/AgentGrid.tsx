import { makeStyles, MessageBar, MessageBarBody, MessageBarTitle } from "@fluentui/react-components";
import { useApp } from "../state/AppState";
import { AgentCard } from "./AgentCard";
import { MatrixSkeleton } from "./MatrixSkeleton";

const useStyles = makeStyles({
  grid: {
    display: "grid",
    gridTemplateColumns: "repeat(auto-fill, minmax(250px, 1fr))",
    gap: "16px"
  }
});

export function AgentGrid() {
  const styles = useStyles();
  const { agents, agentsLoading, agentsError, setupRequired, query, statusOf } = useApp();

  if (agentsLoading && !agents.length) return <MatrixSkeleton />;

  if (agentsError && !agents.length) {
    return (
      <MessageBar intent="error">
        <MessageBarBody>
          <MessageBarTitle>Could not load agents</MessageBarTitle>
          {agentsError.message}
          {(agentsError as any).status === 403 &&
            " — check security-role read access to pda_monitoredagent, workflow and flowrun."}
        </MessageBarBody>
      </MessageBar>
    );
  }

  if (setupRequired) {
    return (
      <MessageBar intent="warning">
        <MessageBarBody>
          <MessageBarTitle>Setup required</MessageBarTitle>
          The pda_monitoredagent table was not found in this environment. Create it (and
          optionally pda_agentaction) as described in the README, then add a row per
          autonomous agent with pda_agenttype = Autonomous and its workflow id.
        </MessageBarBody>
      </MessageBar>
    );
  }

  const q = query.trim().toLowerCase();
  const visible = agents
    .filter((a) => !q || (a.name || "").toLowerCase().includes(q))
    .sort((x, y) => {
      const rank = (s: string) =>
        s === "waiting-input" ? 3 : s === "running" ? 2 : s === "failed" ? 1 : 0;
      return (
        rank(statusOf(y)) - rank(statusOf(x)) ||
        (y.lastActivity?.getTime() || 0) - (x.lastActivity?.getTime() || 0)
      );
    });

  if (!visible.length) {
    return (
      <MessageBar intent="info">
        <MessageBarBody>
          <MessageBarTitle>No autonomous agents</MessageBarTitle>
          {q
            ? "No agents match your search."
            : "No active rows with pda_agenttype = Autonomous in pda_monitoredagent."}
        </MessageBarBody>
      </MessageBar>
    );
  }

  return (
    <div className={styles.grid} data-testid="agent-grid">
      {visible.map((a) => (
        <AgentCard key={a.id} agent={a} />
      ))}
    </div>
  );
}
