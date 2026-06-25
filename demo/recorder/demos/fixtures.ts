/**
 * Shared test fixture for all demos.
 *
 * `setupRecast(test)` wires the recast helpers (narrate/highlight/zoom/click/
 * pace/waitForNarration) into Playwright so that when they run they write
 * marker steps into the trace zip. The render pipeline (render.mjs) then reads
 * those markers back via `subtitlesFromTrace()` and turns them into subtitles,
 * cursor moves, zooms, and click ripples — no separate config needed.
 *
 * We leave `narrateAutoWait` ON by default: without a TTS key, each narrate()
 * line still gets enough on-screen time for a viewer to read it. Once you wire
 * up a voiceover provider in render.mjs, the renderer re-times to the real
 * audio length, so this stays correct either way.
 */
import { test as base } from '@playwright/test'
import { setupRecast } from 'playwright-recast'

setupRecast(base, { narrateAutoWait: true, clickSettleMs: 200 })

export const test = base
export { expect } from '@playwright/test'
export {
  narrate,
  highlight,
  zoom,
  pace,
  click,
  markClick,
  waitForNarration,
} from 'playwright-recast'
