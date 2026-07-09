// End-to-end verification of the built dashboard in demo mode.
// Usage: node scripts/verify-demo.mjs [url]
// Default target: file://dist/pda_agentdashboard.html?demo=1
import { chromium } from "playwright";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const target =
  process.argv[2] || `file://${join(root, "dist", "pda_agentdashboard.html")}?demo=1`;

const executablePath = process.env.CHROMIUM_PATH || "/opt/pw-browsers/chromium";

let failures = 0;
const ok = (name) => console.log(`  ✔ ${name}`);
const fail = (name, detail) => {
  failures++;
  console.error(`  ✘ ${name}${detail ? ` — ${detail}` : ""}`);
};
const check = (cond, name, detail) => (cond ? ok(name) : fail(name, detail));

const browser = await chromium.launch({ executablePath }).catch(() => chromium.launch());
const page = await browser.newPage({ viewport: { width: 1400, height: 950 } });

const consoleErrors = [];
page.on("console", (msg) => {
  // External resource failures (Google Fonts) are expected in offline sandboxes.
  if (msg.type() === "error" && !/Failed to load resource/.test(msg.text()))
    consoleErrors.push(msg.text());
});
page.on("pageerror", (e) => consoleErrors.push(String(e)));

console.log(`Target: ${target}\n`);
await page.goto(target);
await page.waitForTimeout(2500);

// ── Shell ──────────────────────────────────────────────────────────────
check(await page.getByTestId("demo-banner").isVisible(), "demo banner visible");
const cards = page.getByTestId("agent-card");
check((await cards.count()) === 4, "4 agent cards", `got ${await cards.count()}`);

const kpiValues = await page
  .getByTestId("kpi")
  .evaluateAll((els) => els.map((el) => el.querySelector("div")?.textContent));
check(kpiValues[0] === "4", "KPI: 4 autonomous agents", `got ${kpiValues[0]}`);
check(Number(kpiValues[1]) >= 1, "KPI: at least 1 running", `got ${kpiValues[1]}`);
check(Number(kpiValues[4]) >= 1, "KPI: at least 1 awaiting input", `got ${kpiValues[4]}`);

// ── Sprites animate (canvas pixel data diff over 500 ms) ──────────────
const grabFrame = () =>
  page
    .locator('[data-testid="agent-card"][data-status="running"] canvas')
    .first()
    .evaluate((c) => c.toDataURL());
const frames = new Set();
for (let i = 0; i < 8; i++) {
  frames.add(await grabFrame());
  await page.waitForTimeout(150);
}
check([...frames][0].length > 1000, "pixel worker sprite is drawn");
check(frames.size > 1, "pixel worker sprite animates");

// ── Drawer with approval flow ──────────────────────────────────────────
const waitingCard = page.locator('[data-testid="agent-card"][data-status="waiting-input"]').first();
check((await waitingCard.count()) === 1, "one agent waiting for input");
await waitingCard.click();
await page.waitForTimeout(800);
check(await page.getByTestId("agent-drawer").isVisible(), "drawer opens on card click");
check(await page.getByTestId("approval-panel").isVisible(), "approval panel shown");

await page.getByTestId("approval-input").fill("Approved from verify script");
await page.getByTestId("approve-button").click();
await page.waitForTimeout(2500);
check(
  (await page.getByTestId("approval-panel").count()) === 0,
  "approval resolves after Approve"
);
const timelineRows = await page.getByTestId("action-row").count();
check(timelineRows >= 3, "follow-up steps stream into timeline", `got ${timelineRows} rows`);
await page.getByTestId("drawer-close").click();
await page.waitForTimeout(400);

// ── Fire flow on the idle agent (via the project picker) ───────────────
const idleCard = page.locator('[data-testid="agent-card"][data-status="idle"]').first();
const idleName = await idleCard.getAttribute("data-agent-name");
await idleCard.getByTestId("fire-button").click();
await page.waitForTimeout(600);
check(
  (await page.getByTestId("project-picker-row").count()) > 0,
  "project picker shows records"
);
await page.getByTestId("project-picker-row").first().click();
await page.getByTestId("project-picker-confirm").click();
await page.waitForTimeout(1200);
check(await page.getByTestId("agent-drawer").isVisible(), "drawer auto-opens on fire");
await page.waitForTimeout(4500);
const firedRows = await page.getByTestId("action-row").count();
check(firedRows >= 2, `fired run streams actions for ${idleName}`, `got ${firedRows} rows`);
const fired = page.locator(
  `[data-testid="agent-card"][data-agent-name="${idleName}"]`
);
check(
  (await fired.getAttribute("data-status")) === "running",
  "fired agent card flips to running"
);
await page.getByTestId("drawer-close").click();

// ── Console errors ─────────────────────────────────────────────────────
check(consoleErrors.length === 0, "no console errors", consoleErrors.slice(0, 3).join(" | "));

await page.screenshot({ path: join(root, "dist", "verify-screenshot.png"), fullPage: true });
await browser.close();

console.log(failures ? `\n${failures} check(s) FAILED` : "\nAll checks passed");
process.exit(failures ? 1 : 0);
