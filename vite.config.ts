import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { viteSingleFile } from "vite-plugin-singlefile";

// Emits a single self-contained HTML file (dist/index.html, renamed to
// dist/pda_agentdashboard.html by scripts/rename-output.mjs) so the whole
// app deploys as one Dataverse web resource. Sprite PNGs inline as data URLs.
export default defineConfig({
  plugins: [react(), viteSingleFile()],
  build: {
    target: "es2020",
    assetsInlineLimit: 100_000_000,
    cssCodeSplit: false,
    chunkSizeWarningLimit: 4000
  }
});
