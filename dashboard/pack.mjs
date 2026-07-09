#!/usr/bin/env node
// Repacks dashboard/.unpacked/ (produced by unpack.mjs, possibly hand-edited)
// back into dashboard/index.html's "__bundler" single-file format.
// Only the three __bundler/* <script> tag bodies are replaced; every other
// byte of the wrapper HTML (the loader, DOCTYPE, etc.) is left untouched.
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { gzipSync } from "node:zlib";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spliceJson } from "./bundler-format.mjs";

const dir = path.dirname(fileURLToPath(import.meta.url));
const srcPath = path.join(dir, "index.html");
const inDir = path.join(dir, ".unpacked");

let html = readFileSync(srcPath, "utf8");

const meta = JSON.parse(readFileSync(path.join(inDir, "manifest.meta.json"), "utf8"));
const template = readFileSync(path.join(inDir, "template.html"), "utf8");
const extResources = JSON.parse(readFileSync(path.join(inDir, "ext_resources.json"), "utf8"));

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

const manifest = {};
for (const uuid of meta.order) {
  const entry = meta.entries[uuid];
  const ext = MIME_EXT[entry.mime] || ".bin";
  const filePath = path.join(inDir, uuid + ext);
  if (!existsSync(filePath)) throw new Error(`Missing unpacked resource: ${filePath}`);

  const isText = ext === ".js" || ext === ".css" || ext === ".html" || ext === ".svg";
  const raw = isText ? Buffer.from(readFileSync(filePath, "utf8"), "utf8") : readFileSync(filePath);
  const bytes = entry.compressed ? gzipSync(raw) : raw;

  manifest[uuid] = { data: bytes.toString("base64"), compressed: entry.compressed, mime: entry.mime };
}

html = spliceJson(html, "__bundler/manifest", manifest);
html = spliceJson(html, "__bundler/template", template);
html = spliceJson(html, "__bundler/ext_resources", extResources);

writeFileSync(srcPath, html);
console.log(`Repacked ${meta.order.length} resource(s) + template.html into index.html`);
