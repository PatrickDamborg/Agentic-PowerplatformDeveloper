import { defineConfig, devices } from '@playwright/test'

/**
 * Demo-recording config — NOT a test config.
 *
 * The point here is reproducible, good-looking capture, not assertions:
 *  - `video: 'on'` gives recast a native-framerate .webm to work from
 *    (much smoother than reconstructing frames from the trace alone).
 *  - `trace: 'on'` captures the actions, cursor positions, network timing,
 *    and the narrate()/highlight()/zoom()/click() markers our specs write.
 *    recast reads both together.
 *  - A fixed 1280x720 viewport keeps framing predictable so zoom math is stable.
 *  - storageState reuses the M365/Dataverse login captured by `npm run login`
 *    so demos never have to show (or script) the auth dance.
 */
export default defineConfig({
  testDir: './demos',
  // Demos are a sequence, not a suite — run them one at a time, in order.
  fullyParallel: false,
  workers: 1,
  retries: 0,
  // Generous: a demo narration beat can legitimately hold for a while.
  timeout: 5 * 60 * 1000,
  outputDir: './test-results',
  use: {
    baseURL: process.env.DEMO_BASE_URL ?? 'https://make.powerapps.com',
    storageState: '.auth/state.json',
    viewport: { width: 1280, height: 720 },
    video: {
      mode: 'on',
      size: { width: 1280, height: 720 },
    },
    trace: 'on',
    // Slow the robot down a touch so raw capture is less jarring; recast
    // re-times everything afterwards anyway, but this helps the .webm.
    launchOptions: { slowMo: 250 },
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
})
