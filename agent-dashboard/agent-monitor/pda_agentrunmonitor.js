/**
 * pda_agentrunmonitor.js
 * Detects when a monitored Copilot Studio agent is invoked via the M365 Copilot
 * side pane and immediately writes a pda_agentrun record to Dataverse.
 *
 * Why: The M365 Copilot channel does not write conversationtranscript records
 * (by Microsoft design), so the agent monitor has no liveness signal. This script
 * bridges that gap by writing the record the moment the user sends a message.
 *
 * Mechanism: postMessage interception. The Copilot pane runs in a cross-origin
 * iframe (apps.preview.powerapps.com) so MutationObserver cannot cross the
 * boundary — but the iframe posts messages to the parent window, which we can
 * intercept. Fallback: MutationObserver on the outer same-origin Copilot panel
 * container for attribute/class changes.
 *
 * Deploy: upload as a web resource (pda_agentrunmonitor.js), then add it to the
 * model-driven app via a form onLoad handler or as a global script dependency.
 */
(function () {
  "use strict";

  const API_BASE = "/api/data/v9.2";
  const HEADERS = {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "OData-Version": "4.0",
    "OData-MaxVersion": "4.0"
  };

  // { targetId (lowercase guid) → displayName }
  let watchedAgents = {};
  let initialized = false;

  // ── Load monitored Copilot agents from config table ──────────────────────
  async function loadWatchedAgents() {
    try {
      const res = await fetch(
        `${API_BASE}/pda_monitoredagents?$select=pda_name,pda_agenttype,pda_targetid&$filter=statecode eq 0&$top=50`,
        { credentials: "include", headers: HEADERS }
      );
      if (!res.ok) return;
      const data = await res.json();
      watchedAgents = {};
      for (const row of data.value || []) {
        if (row.pda_agenttype === 100000000) {  // Copilot type only
          watchedAgents[String(row.pda_targetid || "").toLowerCase().replace(/[{}]/g, "")] = row.pda_name;
        }
      }
    } catch (_) {}
  }

  // ── Write a pda_agentrun record immediately ───────────────────────────────
  async function writeRunRecord(agentName, agentId) {
    const dedupKey = `pda_run_${agentId}`;
    const last = Number(sessionStorage.getItem(dedupKey) || 0);
    if (Date.now() - last < 5000) return;   // 5-second dedup guard
    sessionStorage.setItem(dedupKey, Date.now());

    try {
      await fetch(`${API_BASE}/pda_agentruns`, {
        method: "POST",
        credentials: "include",
        headers: HEADERS,
        body: JSON.stringify({
          pda_name: `${agentName} – ${new Date().toISOString()}`,
          pda_agentid: agentId,
          pda_starttime: new Date().toISOString(),
          pda_status: 100000000  // running
        })
      });
    } catch (_) {}
  }

  // ── Determine if a postMessage payload references a watched agent ─────────
  function detectAgentInMessage(raw) {
    let text;
    try {
      text = typeof raw === "string" ? raw : JSON.stringify(raw);
    } catch (_) { return null; }

    const lower = text.toLowerCase();

    // Targeted: look for bot schema names or GUIDs matching our config
    for (const [id, name] of Object.entries(watchedAgents)) {
      if (text.includes(id)) return { id, name };
    }

    // Heuristic fallback: message from Copilot pane indicating a send action
    // Refine this condition after inspecting console logs on first deploy
    if (
      lower.includes("bizchat") &&
      (lower.includes("send") || lower.includes("submit") || lower.includes("message"))
    ) {
      // Can't pinpoint which agent — write for all watched agents
      // (rare fallback; targeted match above handles the normal case)
      const ids = Object.keys(watchedAgents);
      return ids.length === 1 ? { id: ids[0], name: watchedAgents[ids[0]] } : null;
    }
    return null;
  }

  // ── postMessage listener (primary) ───────────────────────────────────────
  function attachMessageListener() {
    window.addEventListener("message", (evt) => {
      // Log in dev mode to help discover the right event payload format
      if (window.__pdaMonitorDebug) {
        console.log("[pda_agentrunmonitor] postMessage from", evt.origin, evt.data);
      }

      if (!evt.data) return;

      const match = detectAgentInMessage(evt.data);
      if (match) {
        writeRunRecord(match.name, match.id);
      }
    });
  }

  // ── MutationObserver fallback (outer same-origin DOM) ────────────────────
  // Watches the Copilot panel container for the stop button appearing,
  // which indicates a run started. The stop button is injected into the
  // outer page DOM (not inside the cross-origin iframe) by the Power Apps host.
  function attachMutationObserver() {
    let triggered = false;

    const observer = new MutationObserver(() => {
      // The stop button on the Copilot pane toolbar appears while the agent
      // is processing. It lives on the outer page (complementary[aria-label="M365Chat"]).
      const copilotPanel = document.querySelector('complementary[data-id="sidePaneHost"]') ||
                           document.querySelector('[aria-label="M365Chat"]') ||
                           document.querySelector('[data-sidepaneliframe]')?.closest('[role="complementary"]');

      if (!copilotPanel) return;

      // Look for a stop/cancel button that appears only during processing
      const stopBtn = copilotPanel.querySelector('button[aria-label*="Stop"]') ||
                      copilotPanel.querySelector('button[title*="Stop"]') ||
                      copilotPanel.querySelector('[data-testid*="stop"]');

      if (stopBtn && !triggered) {
        triggered = true;
        // We can't tell which agent without reading the iframe — write for all
        for (const [id, name] of Object.entries(watchedAgents)) {
          writeRunRecord(name, id);
        }
        // Reset trigger after a cooldown so subsequent runs are captured
        setTimeout(() => { triggered = false; }, 10000);
      }
    });

    observer.observe(document.body, {
      subtree: true,
      childList: true,
      attributes: true,
      attributeFilter: ["aria-label", "aria-disabled", "class", "data-testid"]
    });
  }

  // ── Init ──────────────────────────────────────────────────────────────────
  async function init() {
    if (initialized) return;
    initialized = true;

    await loadWatchedAgents();

    // Reload watched agents every 5 minutes in case config table changes
    setInterval(loadWatchedAgents, 5 * 60 * 1000);

    attachMessageListener();
    attachMutationObserver();
  }

  // Start when DOM is ready
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }

  // Expose debug toggle: set window.__pdaMonitorDebug = true in console to see events
  window.__pdaMonitorDebug = false;

})();
