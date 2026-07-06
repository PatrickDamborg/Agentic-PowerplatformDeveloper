import {
  FluentProvider, makeStyles, MessageBar, MessageBarBody, MessageBarTitle
} from "@fluentui/react-components";
import { AgentDrawer } from "./components/AgentDrawer";
import { AgentGrid } from "./components/AgentGrid";
import { KpiStrip } from "./components/KpiStrip";
import { TopBar } from "./components/TopBar";
import { AppStateProvider, useApp } from "./state/AppState";
import { pixelDarkTheme } from "./theme";

const useStyles = makeStyles({
  root: {
    minHeight: "100vh",
    backgroundColor: "#11111b",
    backgroundImage:
      "radial-gradient(circle at 20% 0%, #1e1e2e 0%, #11111b 60%)",
    padding: "20px",
    boxSizing: "border-box",
    display: "flex",
    flexDirection: "column",
    rowGap: "16px"
  }
});

function Shell() {
  const styles = useStyles();
  const { demo } = useApp();
  return (
    <div className={styles.root}>
      {demo && (
        <MessageBar intent="info" data-testid="demo-banner">
          <MessageBarBody>
            <MessageBarTitle>Demo mode</MessageBarTitle>
            Showing sample autonomous agents — no Dataverse connection. Fire an agent or
            answer the pending approval to see the live experience.
          </MessageBarBody>
        </MessageBar>
      )}
      <TopBar />
      <KpiStrip />
      <AgentGrid />
      <AgentDrawer />
    </div>
  );
}

export function App() {
  return (
    <FluentProvider theme={pixelDarkTheme}>
      <AppStateProvider>
        <Shell />
      </AppStateProvider>
    </FluentProvider>
  );
}
