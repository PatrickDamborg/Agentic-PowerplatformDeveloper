import {
  Button, makeStyles, SearchBox, Switch, Text, tokens, Tooltip
} from "@fluentui/react-components";
import { ArrowClockwiseRegular, WeatherMoonRegular, WeatherSunnyRegular } from "@fluentui/react-icons";
import { useApp } from "../state/AppState";
import { retro } from "../theme";
import { VERSION } from "../config";

const useStyles = makeStyles({
  bar: {
    display: "flex",
    alignItems: "center",
    columnGap: "12px",
    flexWrap: "wrap",
    rowGap: "8px"
  },
  title: {
    fontFamily: retro.fontPixel,
    fontSize: "30px",
    color: tokens.colorNeutralForeground1,
    letterSpacing: "1px",
    marginRight: "4px"
  },
  version: { color: tokens.colorNeutralForeground3, fontSize: "11px" },
  spacer: { flexGrow: 1 }
});

export function TopBar() {
  const styles = useStyles();
  const {
    query, setQuery, refreshAgents, autoRefresh, setAutoRefresh, agentsLoading,
    themeMode, toggleThemeMode
  } = useApp();

  return (
    <div className={styles.bar}>
      <span className={styles.title}>AGENT COMMAND CENTER</span>
      <span className={styles.version}>v{VERSION}</span>
      <div className={styles.spacer} />
      <SearchBox
        placeholder="Search agents"
        value={query}
        onChange={(_, d) => setQuery(d.value)}
        data-testid="search"
      />
      <Switch
        checked={autoRefresh}
        onChange={(_, d) => setAutoRefresh(d.checked)}
        label={<Text size={200}>Auto-refresh</Text>}
      />
      <Button
        icon={<ArrowClockwiseRegular />}
        onClick={refreshAgents}
        disabled={agentsLoading}
        data-testid="refresh"
      >
        Refresh
      </Button>
      <Tooltip
        content={themeMode === "dark" ? "Switch to light mode" : "Switch to dark mode"}
        relationship="label"
      >
        <Button
          icon={themeMode === "dark" ? <WeatherSunnyRegular /> : <WeatherMoonRegular />}
          onClick={toggleThemeMode}
          data-testid="theme-toggle"
        />
      </Tooltip>
    </div>
  );
}
