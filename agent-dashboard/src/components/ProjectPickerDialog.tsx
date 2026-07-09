import {
  Body1, Button, Dialog, DialogActions, DialogBody, DialogContent, DialogSurface,
  DialogTitle, Input, Spinner, makeStyles, tokens
} from "@fluentui/react-components";
import { SearchRegular } from "@fluentui/react-icons";
import { useEffect, useMemo, useState } from "react";
import type { BrowseRecord } from "../api/projects";
import { loadBrowseRecords } from "../api/projects";
import { useApp } from "../state/AppState";

const useStyles = makeStyles({
  list: {
    display: "flex",
    flexDirection: "column",
    rowGap: "2px",
    maxHeight: "320px",
    overflowY: "auto",
    marginTop: "12px"
  },
  row: {
    display: "flex",
    alignItems: "center",
    padding: "8px 10px",
    borderRadius: "4px",
    cursor: "pointer",
    fontSize: "13px",
    "&:hover": { backgroundColor: tokens.colorNeutralBackground1Hover }
  },
  selected: {
    backgroundColor: tokens.colorBrandBackground2,
    fontWeight: 600
  },
  empty: { padding: "20px 4px", color: tokens.colorNeutralForeground3, fontSize: "13px" },
  center: { display: "flex", justifyContent: "center", padding: "20px" }
});

const DEMO_RECORDS: Record<string, BrowseRecord[]> = {
  initiative: [
    { id: "demo-init-1", name: "EU FMD Serialisation Platform" },
    { id: "demo-init-2", name: "GxP Quality Management System" },
    { id: "demo-init-3", name: "Regulatory Reporting Automation" }
  ],
  program: [
    { id: "demo-prog-1", name: "Digital Compliance Program" },
    { id: "demo-prog-2", name: "Operational Excellence Program" }
  ],
  portfolio: [
    { id: "demo-port-1", name: "Quality & Compliance Portfolio" },
    { id: "demo-port-2", name: "Digital Transformation Portfolio" }
  ]
};

export function ProjectPickerDialog() {
  const styles = useStyles();
  const { demo, pickerAgent, cancelPicker, confirmPicker } = useApp();
  const [search, setSearch] = useState("");
  const [records, setRecords] = useState<BrowseRecord[]>([]);
  const [loading, setLoading] = useState(false);
  const [selected, setSelected] = useState<BrowseRecord | null>(null);
  const [firing, setFiring] = useState(false);

  const open = !!pickerAgent;
  const scope = pickerAgent?.scope || "initiative";

  useEffect(() => {
    if (!open) return;
    setSearch("");
    setSelected(null);
  }, [open, pickerAgent?.id]);

  useEffect(() => {
    if (!open) return;
    let cancelled = false;
    setLoading(true);
    const task = demo
      ? Promise.resolve(
          DEMO_RECORDS[scope].filter((r) =>
            r.name.toLowerCase().includes(search.trim().toLowerCase())
          )
        )
      : loadBrowseRecords(scope, search);
    task
      .then((rows) => {
        if (!cancelled) setRecords(rows);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [open, scope, search, demo]);

  const scopeLabel = useMemo(
    () => ({ initiative: "Initiative", program: "Program", portfolio: "Portfolio" })[scope],
    [scope]
  );

  const onFire = async () => {
    if (!pickerAgent || !selected) return;
    setFiring(true);
    try {
      await confirmPicker(selected);
    } finally {
      setFiring(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={(_, d) => !d.open && cancelPicker()}>
      <DialogSurface>
        <DialogBody>
          <DialogTitle>Fire {pickerAgent?.name}</DialogTitle>
          <DialogContent>
            <Body1>Choose the {scopeLabel.toLowerCase()} this run applies to.</Body1>
            <Input
              contentBefore={<SearchRegular />}
              placeholder={`Search ${scopeLabel.toLowerCase()}s…`}
              value={search}
              onChange={(_, d) => setSearch(d.value)}
              style={{ width: "100%", marginTop: "12px" }}
              data-testid="project-picker-search"
            />
            <div className={styles.list}>
              {loading && (
                <div className={styles.center}>
                  <Spinner size="tiny" label="Loading…" />
                </div>
              )}
              {!loading && records.length === 0 && (
                <div className={styles.empty}>No {scopeLabel.toLowerCase()}s found.</div>
              )}
              {!loading &&
                records.map((r) => (
                  <div
                    key={r.id}
                    className={`${styles.row} ${selected?.id === r.id ? styles.selected : ""}`}
                    onClick={() => setSelected(r)}
                    data-testid="project-picker-row"
                  >
                    {r.name}
                  </div>
                ))}
            </div>
          </DialogContent>
          <DialogActions>
            <Button appearance="secondary" onClick={cancelPicker}>
              Cancel
            </Button>
            <Button
              appearance="primary"
              disabled={!selected || firing}
              onClick={onFire}
              data-testid="project-picker-confirm"
            >
              {firing ? "Firing…" : "Fire agent"}
            </Button>
          </DialogActions>
        </DialogBody>
      </DialogSurface>
    </Dialog>
  );
}
