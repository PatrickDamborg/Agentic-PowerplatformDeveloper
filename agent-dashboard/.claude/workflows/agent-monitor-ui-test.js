export const meta = {
  name: 'agent-monitor-ui-test',
  description: 'E2E UI test for agent monitor dashboard and session resume flow via Playwright',
  phases: [
    { title: 'Load Dashboard', detail: 'Hard-refresh, verify dashboard loads with agent cards' },
    { title: 'Open Chat', detail: 'Reset state, open pane, diagnose postMessage + Dataverse write' },
    { title: 'Verify Resume', detail: 'Navigate away/back, check Resume badge, click and verify' },
  ],
};

const TEST_SCHEMA = {
  type: 'object',
  required: ['passed', 'cases'],
  properties: {
    passed: { type: 'boolean' },
    cases: {
      type: 'array',
      items: {
        type: 'object',
        required: ['name', 'passed', 'notes'],
        properties: {
          name:   { type: 'string' },
          passed: { type: 'boolean' },
          notes:  { type: 'string' }
        }
      }
    }
  }
};

const BASE_URL = 'https://pdausa.crm.dynamics.com';

// ── Phase 1: Dashboard load ──────────────────────────────────────────────────
phase('Load Dashboard');

const dashboardResult = await agent(`
You are a QA test agent. Use the Playwright MCP to test the xPM AI Agent Monitor.
Target: ${BASE_URL}

STEPS:
1. Take a screenshot.
2. Hard-refresh: browser_run_code_unsafe:
     await page.keyboard.press('Control+F5');
     await page.waitForTimeout(5000);
   Take a screenshot.
3. If not on Agent Dashboard: browser_evaluate: Xrm.Navigation.navigateTo({pageType:"webresource", webresourceName:"pda_agentmonitor"})
   Wait 4 seconds. Take a screenshot.
4. Read version: browser_evaluate:
     document.querySelector('iframe[title*="Web Resource"],iframe[src*="pda_agentmonitor"]')?.contentDocument?.querySelector('.version')?.textContent
5. Count agent cards (class "card") and look for "xPM Status Reporting".

RETURN: passed=true if dashboard loaded with agent cards. Version is informational only.
cases: "Dashboard loads without error" | "Version shows 1.5.0" | "Agent cards are present" | "xPM Status Reporting card found"
`, { phase: 'Load Dashboard', schema: TEST_SCHEMA });

log(`Dashboard: ${dashboardResult?.passed ? '✓ PASS' : '✗ FAIL'}`);

const dashboardLoaded = dashboardResult?.cases?.find(c => c.name.includes('Dashboard loads'))?.passed;
if (!dashboardLoaded) {
  return { passed: false, summary: 'Dashboard failed to load.', phases: { dashboard: dashboardResult } };
}

// ── Phase 2: Chat + postMessage diagnostics ──────────────────────────────────
phase('Open Chat');

const chatResult = await agent(`
You are a QA test agent at ${BASE_URL}. The Agent Dashboard is loaded. Continue from CURRENT state.

STEP 0 — Reset stale session state:
browser_evaluate:
  const iframe = document.querySelector('iframe[title*="Web Resource"],iframe[src*="pda_agentmonitor"]');
  if (iframe?.contentWindow?.sessionStorage) iframe.contentWindow.sessionStorage.removeItem('pda_chat_pane_agent');
  try { Xrm.App.sidePanes.getPane('pda-agent-chat')?.close(); } catch(e) {}
  return 'reset done';
Wait 2 seconds.

STEP 1 — Click Chat badge:
browser_evaluate:
  const iframe = document.querySelector('iframe[title*="Web Resource"],iframe[src*="pda_agentmonitor"]');
  const badge = iframe?.contentDocument?.querySelector('.card-chat-badge');
  if (badge) badge.click();
  return badge ? 'clicked' : 'not found';
Wait 5 seconds. Take a screenshot.

STEP 2 — Find frames:
browser_run_code_unsafe:
  const frames = page.frames();
  const urls = frames.map((f,i) => i+': '+f.url());
  console.log('All frames:', urls.join(' | '));
  return urls;
Report which frame is pda_agentchat and which is copilotstudio.

STEP 3 — Confirm pane URL has monitoredAgentId:
browser_run_code_unsafe:
  const frames = page.frames();
  const chatFrame = frames.find(f => f.url().includes('pda_agentchat'));
  return chatFrame ? chatFrame.url() : 'not found';

STEP 4 — Wait for Copilot Studio frame, then read its console log buffer:
browser_run_code_unsafe:
  const frames = page.frames();
  const chatFrame = frames.find(f => f.url().includes('pda_agentchat'));
  if (!chatFrame) return 'no pda_agentchat frame';
  // Read the diagnostic log stored by pda_agentchat.html
  const msgLog = await chatFrame.evaluate(() => window.__msgLog || []);
  console.log('pda_agentchat.__msgLog:', JSON.stringify(msgLog));
  return msgLog;
Report what postMessages have been received (if any).

STEP 5 — Simulate a Bot Framework postMessage directly into pda_agentchat to test the listener:
browser_run_code_unsafe:
  const frames = page.frames();
  const chatFrame = frames.find(f => f.url().includes('pda_agentchat'));
  if (!chatFrame) return 'no frame';
  // Inject a synthetic Bot Framework activity with a conversation ID
  await chatFrame.evaluate(() => {
    const syntheticMsg = {
      activity: {
        type: 'conversationUpdate',
        conversation: { id: 'test-conv-' + Date.now().toString(36) },
        from: { id: 'bot', role: 'bot' }
      }
    };
    window.dispatchEvent(new MessageEvent('message', {
      data: JSON.stringify(syntheticMsg),
      origin: 'https://copilotstudio.preview.microsoft.com'
    }));
  });
  await page.waitForTimeout(3000);
  // Read the message log again
  const afterLog = await chatFrame.evaluate(() => window.__msgLog || []);
  console.log('After synthetic postMessage, __msgLog:', JSON.stringify(afterLog));
  return afterLog;
Wait 2 seconds.

STEP 6 — Check Dataverse for pda_agentsession records (after synthetic postMessage):
browser_evaluate:
  const r = await fetch('/api/data/v9.2/pda_agentsessions?$select=pda_name,pda_conversationid,pda_lastactivity,pda_monitoredagentguid&$orderby=pda_lastactivity desc&$top=5', {
    credentials: 'include',
    headers: {'Accept':'application/json','OData-Version':'4.0','OData-MaxVersion':'4.0'}
  });
  const d = await r.json();
  return { count: d.value.length, records: d.value };

STEP 7 — Read browser console messages to find [pda_agentchat] log lines:
Use browser_console_messages or browser_run_code_unsafe to collect console output.
Look for lines containing "[pda_agentchat]" — these show postMessage events and dvPost calls.

RETURN:
passed: true if EITHER (a) a real postMessage with conversation.id was received and a pda_agentsession record was created,
        OR (b) the synthetic postMessage triggered dvPost and created a record.
cases:
  - "Session state reset"
  - "Chat badge clicked — fresh pane with monitoredAgentId"
  - "pda_agentchat frame found"
  - "Copilot Studio sends postMessages to pda_agentchat" (did __msgLog have entries from copilotstudio origin?)
  - "Synthetic postMessage was received by listener"
  - "dvPost was called (logged in console)"
  - "pda_agentsession record created in Dataverse"
  - "Session record has conversationId"
`, { phase: 'Open Chat', schema: TEST_SCHEMA });

log(`Chat: ${chatResult?.passed ? '✓ PASS' : '✗ FAIL'} — ` +
  (chatResult?.cases || []).map(c => c.name + ':' + (c.passed ? '✓' : '✗') + (c.notes ? ' (' + c.notes + ')' : '')).join(' | '));

// ── Phase 3: Navigate away/back, verify Resume badge ────────────────────────
phase('Verify Resume');

const resumeResult = await agent(`
You are a QA test agent at ${BASE_URL}. A pda_agentsession Dataverse record may now exist.
Continue from the CURRENT browser state.

STEPS:
1. Take a screenshot.
2. Navigate AWAY (SPA): browser_evaluate: Xrm.Navigation.navigateTo({pageType:"entitylist", entityName:"pum_initiative"})
   Wait 3 seconds. Take a screenshot.
3. Navigate BACK: browser_evaluate: Xrm.Navigation.navigateTo({pageType:"webresource", webresourceName:"pda_agentmonitor"})
   Wait 5 seconds. Take a screenshot.
4. Check for Resume badge:
   browser_evaluate:
     const iframe = document.querySelector('iframe[title*="Web Resource"],iframe[src*="pda_agentmonitor"]');
     return { count: iframe?.contentDocument?.querySelectorAll('.card-resume-badge')?.length || 0,
              text: iframe?.contentDocument?.querySelector('.card-resume-badge')?.textContent || '' };
   Take a screenshot.
5. If Resume badge visible, click it:
   browser_evaluate:
     document.querySelector('iframe[title*="Web Resource"],iframe[src*="pda_agentmonitor"]')
       ?.contentDocument?.querySelector('.card-resume-badge')?.click();
   Wait 4 seconds. Take a screenshot.
6. Check agentFrame src for conversationId:
   browser_run_code_unsafe:
     const frames = page.frames();
     const chatFrame = frames.find(f => f.url().includes('pda_agentchat'));
     if (chatFrame) {
       const src = await chatFrame.evaluate(() => document.getElementById('agentFrame')?.src || 'no agentFrame');
       return { chatFrameUrl: chatFrame.url(), agentFrameSrc: src };
     }
     return 'no pda_agentchat frame';

RETURN: passed=true if Resume badge appeared AND side pane opened after clicking it.
cases: "Navigated away" | "Returned to dashboard" | "Resume badge visible" | "Resume click opened pane" | "Pane src has conversationId"
`, { phase: 'Verify Resume', schema: TEST_SCHEMA });

log(`Resume: ${resumeResult?.passed ? '✓ PASS' : '✗ FAIL'} — ` +
  (resumeResult?.cases || []).map(c => c.name + ':' + (c.passed ? '✓' : '✗') + (c.notes ? ' (' + c.notes + ')' : '')).join(' | '));

const allPassed = dashboardLoaded && chatResult?.passed && resumeResult?.passed;

return {
  passed: allPassed,
  summary: allPassed ? 'All tests passed.' : 'Some tests failed — see phase results.',
  phases: { dashboard: dashboardResult, chat: chatResult, resume: resumeResult }
};
