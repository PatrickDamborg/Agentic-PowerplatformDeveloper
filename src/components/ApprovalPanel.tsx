import {
  Button, Field, makeStyles, Textarea, tokens
} from "@fluentui/react-components";
import { CheckmarkRegular, DismissRegular } from "@fluentui/react-icons";
import { useState } from "react";
import type { AgentAction } from "../data/types";
import { retro } from "../theme";

const useStyles = makeStyles({
  panel: {
    border: `1px solid ${retro.amber}`,
    borderRadius: "6px",
    padding: "12px",
    backgroundColor: "#2a2415",
    display: "flex",
    flexDirection: "column",
    rowGap: "10px"
  },
  heading: {
    fontFamily: retro.fontMono,
    fontSize: "12px",
    color: retro.amber,
    textTransform: "uppercase",
    letterSpacing: "1px"
  },
  question: { fontSize: "13px", color: tokens.colorNeutralForeground1, whiteSpace: "pre-wrap" },
  buttons: { display: "flex", columnGap: "8px" }
});

export function ApprovalPanel({
  action,
  onRespond
}: {
  action: AgentAction;
  onRespond: (action: AgentAction, option: "approved" | "rejected", response: string) => Promise<void>;
}) {
  const styles = useStyles();
  const [response, setResponse] = useState("");
  const [busy, setBusy] = useState<"approved" | "rejected" | null>(null);

  const submit = async (option: "approved" | "rejected") => {
    setBusy(option);
    try {
      await onRespond(action, option, response.trim());
    } finally {
      setBusy(null);
    }
  };

  return (
    <div className={styles.panel} data-testid="approval-panel">
      <div className={styles.heading}>
        ⚠ {action.type === "input" ? "Input requested" : "Approval requested"} — {action.name}
      </div>
      <div className={styles.question}>{action.detail || "The agent is waiting for you."}</div>
      <Field label="Your comment / input" size="small">
        <Textarea
          value={response}
          onChange={(_, d) => setResponse(d.value)}
          placeholder={action.type === "input" ? "Type the requested input…" : "Optional comment…"}
          data-testid="approval-input"
        />
      </Field>
      <div className={styles.buttons}>
        <Button
          appearance="primary"
          icon={<CheckmarkRegular />}
          disabled={busy !== null}
          onClick={() => submit("approved")}
          data-testid="approve-button"
        >
          {busy === "approved" ? "Sending…" : "Approve"}
        </Button>
        <Button
          icon={<DismissRegular />}
          disabled={busy !== null}
          onClick={() => submit("rejected")}
          data-testid="reject-button"
        >
          {busy === "rejected" ? "Sending…" : "Reject"}
        </Button>
      </div>
    </div>
  );
}
