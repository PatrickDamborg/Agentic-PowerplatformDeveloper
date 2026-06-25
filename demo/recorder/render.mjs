/**
 * render.mjs — turn the recorded trace into a polished demo video.
 *
 * Run AFTER `npm run record` has produced ./test-results/.../trace.zip (+ .webm).
 *
 *   node render.mjs                      → silent, burned-in subtitles from narrate()
 *   OPENAI_API_KEY=sk-... node render.mjs → adds AI voiceover (OpenAI TTS, voice "nova")
 *
 * The pipeline is immutable and lazy — nothing runs until .toFile().
 * Every stage maps to markers our spec already wrote into the trace:
 *   narrate()   → subtitlesFromTrace()  (and TTS, if a provider is set)
 *   highlight() → textHighlight()
 *   zoom()      → autoZoom()
 *   click()     → cursorOverlay() + clickEffect()
 */
import { existsSync, readdirSync, statSync } from 'node:fs'
import { join } from 'node:path'
import { Recast, OpenAIProvider } from 'playwright-recast'

const RESULTS_DIR = './test-results'
const OUTPUT = process.env.DEMO_OUTPUT ?? './demo.mp4'

if (!existsSync(RESULTS_DIR)) {
  console.error(`No ${RESULTS_DIR} found. Run \`npm run record\` first.`)
  process.exit(1)
}

// recast accepts the test-results dir directly; it pairs trace.zip with the
// sibling .webm for native-framerate source. Point it at the run folder.
const runDirs = readdirSync(RESULTS_DIR)
  .map((d) => join(RESULTS_DIR, d))
  .filter((p) => statSync(p).isDirectory())

if (runDirs.length === 0) {
  console.error(`No run output under ${RESULTS_DIR}. Did the recording produce a trace?`)
  process.exit(1)
}

// Most recent run wins.
const source = runDirs.sort((a, b) => statSync(b).mtimeMs - statSync(a).mtimeMs)[0]
console.log(`Rendering from: ${source}`)

let pipeline = Recast.from(source)
  .parse()
  // Keep interactions at human speed, compress the dead air.
  .speedUp({
    duringIdle: 4.0,
    duringNetworkWait: 2.5,
    duringUserAction: 1.0,
    minSegmentDuration: 500,
  })
  // Recover narration text written by narrate() → becomes subtitles (+ TTS).
  .subtitlesFromTrace()
  // zoom() / highlight() / click() overlays.
  .autoZoom()
  .textHighlight()
  .cursorOverlay({ approachMs: 600 })
  .clickEffect()

// Voiceover is opt-in: only if a key is present, so `node render.mjs` works offline.
if (process.env.OPENAI_API_KEY) {
  console.log('OPENAI_API_KEY detected → adding TTS voiceover (OpenAI, "nova").')
  pipeline = pipeline.voiceover(
    OpenAIProvider({
      voice: 'nova',
      speed: 1.1,
      instructions: 'Calm, confident product-demo narration. Slight enthusiasm.',
    }),
    { normalize: true },
  )
} else {
  console.log('No OPENAI_API_KEY → rendering with burned-in subtitles only.')
}

await pipeline
  .render({
    format: 'mp4',
    resolution: '1080p',
    fps: 60,
    burnSubtitles: true,
    subtitleStyle: {
      fontSize: 44,
      primaryColor: '#FFFFFF',
      backgroundColor: '#000000',
      backgroundOpacity: 0.6,
      padding: 18,
      bold: true,
      chunkOptions: { maxCharsPerLine: 58 },
    },
  })
  .toFile(OUTPUT)

console.log(`\n✅ Done → ${OUTPUT}`)
