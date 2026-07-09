// One-time: pull the six base64 PNG spritesheets out of the legacy
// agent-monitor.html (CHAR_SRCS array) and write them as real PNG files
// under src/sprites/. Vite re-inlines them at build time.
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const html = readFileSync(join(root, "agent-monitor", "agent-monitor.html"), "utf8");

const start = html.indexOf("const CHAR_SRCS");
if (start < 0) throw new Error("CHAR_SRCS not found");
const end = html.indexOf("];", start);
const block = html.slice(start, end);

const matches = [...block.matchAll(/data:image\/png;base64,([A-Za-z0-9+/=]+)/g)];
if (matches.length !== 6) throw new Error(`expected 6 spritesheets, found ${matches.length}`);

const outDir = join(root, "src", "sprites");
mkdirSync(outDir, { recursive: true });
matches.forEach((m, i) => {
  const file = join(outDir, `char_${i}.png`);
  writeFileSync(file, Buffer.from(m[1], "base64"));
  console.log(`${file} (${m[1].length} b64 chars)`);
});
