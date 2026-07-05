import { renameSync, statSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const src = join(root, "dist", "index.html");
const dest = join(root, "dist", "pda_agentdashboard.html");

renameSync(src, dest);
const kb = Math.round(statSync(dest).size / 1024);
console.log(`dist/pda_agentdashboard.html (${kb} KB)`);
if (kb > 5 * 1024) {
  console.error("ERROR: bundle exceeds the 5 MB Dataverse web resource limit");
  process.exit(1);
}
