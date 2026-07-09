import {
  FluentProvider, makeStyles, MessageBar, MessageBarBody, MessageBarTitle
} from "@fluentui/react-components";
import { useCallback, useState } from "react";
import { AgentDrawer } from "./components/AgentDrawer";
import { AgentGrid } from "./components/AgentGrid";
import { KpiStrip } from "./components/KpiStrip";
import { ProjectPickerDialog } from "./components/ProjectPickerDialog";
import { TopBar } from "./components/TopBar";
import { AppStateProvider, loadThemeMode, THEME_STORAGE_KEY, useApp } from "./state/AppState";
import { pixelDarkTheme, pixelLightTheme, shellBackground, type ThemeMode } from "./theme";

const useStyles = makeStyles({
  root: {
    minHeight: "100vh",
    padding: "20px",
    boxSizing: "border-box",
    display: "flex",
    flexDirection: "column",
    rowGap: "16px"
  }
});

function Shell() {
  const styles = useStyles();
  const { demo, themeMode } = useApp();
  const bg = shellBackground[themeMode];
  return (
    <div className={styles.root} style={{ backgroundColor: bg.bg, backgroundImage: bg.image }}>
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
      <ProjectPickerDialog />
    </div>
  );
}

export function App() {
  const [themeMode, setThemeMode] = useState<ThemeMode>(loadThemeMode);
  const toggleThemeMode = useCallback(() => {
    setThemeMode((prev) => {
      const next = prev === "light" ? "dark" : "light";
      localStorage.setItem(THEME_STORAGE_KEY, next);
      return next;
    });
  }, []);

  return (
    <FluentProvider theme={themeMode === "dark" ? pixelDarkTheme : pixelLightTheme}>
      <AppStateProvider themeMode={themeMode} toggleThemeMode={toggleThemeMode}>
        <Shell />
      </AppStateProvider>
    </FluentProvider>
  );
}
