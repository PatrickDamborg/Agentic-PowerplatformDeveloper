#!/usr/bin/env node
// Unpacks dashboard/index.html's "__bundler" single-file format into plain
// files under dashboard/.unpacked/ so its HTML/CSS/JS can be edited as text.
// Reverse of pack.mjs. Round-trip: unpack -> edit -> pack.
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { gunzipSync } from "node:zlib";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { extractJson } from "./bundler-format.mjs";

const dir = path.dirname(fileURLToPath(import.meta.url));
const srcPath = path.join(dir, "index.html");
const outDir = path.join(dir, ".unpacked");

const html = readFileSync(srcPath, "utf8");

const manifest = extractJson(html, "__bundler/manifest");
const template = extractJson(html, "__bundler/template");
const extResources = extractJson(html, "__bundler/ext_resources");

mkdirSync(outDir, { recursive: true });

const MIME_EXT = {
  "text/javascript": ".js",
  "application/javascript": ".js",
  "text/css": ".css",
  "text/html": ".html",
  "image/png": ".png",
  "image/jpeg": ".jpg",
  "image/svg+xml": ".svg",
  "font/woff2": ".woff2",
  "font/woff": ".woff",
};

const meta = { order: [], entries: {} };

for (const [uuid, entry] of Object.entries(manifest)) {
  meta.order.push(uuid);
  meta.entries[uuid] = { mime: entry.mime, compressed: !!entry.compressed };

  const raw = Buffer.from(entry.data, "base64");
  const bytes = entry.compressed ? gunzipSync(raw) : raw;

  const ext = MIME_EXT[entry.mime] || ".bin";
  const isText = ext === ".js" || ext === ".css" || ext === ".html" || ext === ".svg";
  const fileName = uuid + ext;
  writeFileSync(
    path.join(outDir, fileName),
    isText ? bytes.toString("utf8") : bytes
  );
}

writeFileSync(path.join(outDir, "manifest.meta.json"), JSON.stringify(meta, null, 2));
writeFileSync(path.join(outDir, "template.html"), template);
writeFileSync(path.join(outDir, "ext_resources.json"), JSON.stringify(extResources, null, 2));

console.log(`Unpacked ${meta.order.length} resource(s) + template.html into ${path.relative(dir, outDir)}/`);
for (const uuid of meta.order) {
  console.log(`  ${uuid}${MIME_EXT[meta.entries[uuid].mime] || ".bin"}  (${meta.entries[uuid].mime}${meta.entries[uuid].compressed ? ", gzip" : ""})`);
}
