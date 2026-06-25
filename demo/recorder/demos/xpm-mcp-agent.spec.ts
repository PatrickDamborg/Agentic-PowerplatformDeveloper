/**
 * Demo: xPM - MCP Agent answering a project-status question.
 *
 * This is the authored "happy path." It is NOT a test — there are no hard
 * assertions that would fail the run and abort the recording. The job of this
 * file is to drive the UI through a clean narrative while the recast helpers
 * lay down narration, highlight, zoom, and click markers for the renderer.
 *
 * HOW TO ADAPT TO YOUR REAL UI
 * ----------------------------
 * The selectors below are placeholders. The reliable way to fill them in:
 *   1. `npm run login`    → sign in once; session saved to .auth/state.json
 *   2. `npm run codegen`  → click through the real flow; copy the selectors
 *      Playwright generates into the steps below, keeping the narrate()/zoom()/
 *      highlight() wrapper lines.
 *
 * Each recast helper is optional and composable — delete any you don't want.
 */
import { test, narrate, highlight, zoom, click, pace, waitForNarration } from './fixtures'

// Where the agent is reachable. Override per environment:
//   DEMO_AGENT_URL="https://copilotstudio.microsoft.com/.../canvas" npm run demo
const AGENT_URL =
  process.env.DEMO_AGENT_URL ??
  'https://copilotstudio.microsoft.com/environments/Default/bots/a5d3909a-b17e-49ee-80b2-ea3902e1f70d/canvas'

test('xPM MCP Agent — project status query', async ({ page }) => {
  await narrate(
    'Meet the xPM MCP Agent. It reads live project data straight from Dataverse — no dashboards, just ask.',
  )
  await page.goto(AGENT_URL)
  await pace(page, 2500)

  await narrate('We open the test canvas where the agent is waiting for a question.')
  // TODO(codegen): replace with the real chat input locator.
  const input = page.getByRole('textbox', { name: /ask|message|type/i })
  await highlight(input, { text: 'Ask anything' })
  await zoom(input, 1.25)
  await input.click()
  await input.fill('What is the current status of the CRM & Automation project?')
  await pace(page, 1200)

  await narrate('We ask for the current status of the CRM and Automation project.')
  // TODO(codegen): some canvases submit on Enter; others have a send button.
  await input.press('Enter')

  await narrate(
    'Behind the scenes the agent calls the Dataverse MCP, finds the initiative, and pulls its latest status report.',
    { autoWait: true },
  )
  // TODO(codegen): replace with the locator for the agent's response bubble.
  const answer = page.locator('[data-testid="chat-message"]').last()
  await answer.waitFor({ state: 'visible', timeout: 60_000 })
  await waitForNarration()

  await narrate('Here is the answer: the traffic-light KPIs and the headline from the most recent report.')
  await highlight(answer, { text: 'Live from Dataverse' })
  await zoom(answer, 1.2)
  await pace(page, 4000)

  await narrate('One question, a grounded answer — that is the xPM MCP Agent.')
  await pace(page, 2000)
})
