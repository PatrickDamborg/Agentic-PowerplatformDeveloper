// Shared helpers for unpack.mjs / pack.mjs.
//
// dashboard/index.html embeds three JSON values inside
// <script type="__bundler/..."> tags. Those JSON values can legitimately
// contain literal "</script>" text (e.g. the template's own
// <script src="...">...</script> markup) — so locating where the JSON value
// ends CANNOT be done by searching for the literal string "</script>"
// (that finds the first occurrence, which may be nested *inside* the JSON
// string, truncating it). Instead this scans the JSON value itself
// (tracking string/escape state, ignoring "<"/">" entirely) to find its
// true end, exactly like a JSON parser would.
//
// Separately: browsers parse <script> content as raw text and *do* stop at
// the first literal "</script" they see, regardless of type or JSON
// escaping. So any producer of this format must escape "</" as "</"
// inside the JSON value before writing it into the file, or the page itself
// breaks when loaded — not just this tooling. escapeSlashes()/parse() below
// enforce that round-trip.

/** Find the [start, end) span of the JSON value inside <script type="TYPE">...VALUE...</script>. */
export function findJsonValueSpan(html, type) {
  const openTag = `<script type="${type}">`;
  const tagStart = html.indexOf(openTag);
  if (tagStart === -1) throw new Error(`Could not find <script type="${type}">`);
  let i = tagStart + openTag.length;
  while (/\s/.test(html[i])) i++;

  const start = i;
  const first = html[i];

  if (first === '"') {
    i++;
    while (true) {
      if (i >= html.length) throw new Error(`Unterminated JSON string for <script type="${type}">`);
      const c = html[i];
      if (c === "\\") { i += 2; continue; }
      if (c === '"') { i++; break; }
      i++;
    }
    return { start, end: i };
  }

  if (first === "{" || first === "[") {
    const open = first;
    const close = open === "{" ? "}" : "]";
    let depth = 0;
    let inString = false;
    do {
      const c = html[i];
      if (inString) {
        if (c === "\\") { i += 2; continue; }
        if (c === '"') inString = false;
      } else {
        if (c === '"') inString = true;
        else if (c === open) depth++;
        else if (c === close) depth--;
      }
      i++;
    } while (depth > 0);
    return { start, end: i };
  }

  throw new Error(`Unexpected JSON value start '${first}' for <script type="${type}">`);
}

export function extractJson(html, type) {
  const { start, end } = findJsonValueSpan(html, type);
  return JSON.parse(html.slice(start, end));
}

export function spliceJson(html, type, value) {
  const { start, end } = findJsonValueSpan(html, type);
  const json = escapeSlashes(JSON.stringify(value));
  return html.slice(0, start) + json + html.slice(end);
}

// Escape every "</" as "</" so the raw text this JSON sits in never
// contains a literal "</script>" (or "</anything>") — matches the encoding
// already used elsewhere in this file (verified against index.prev.html).
export function escapeSlashes(jsonText) {
  return jsonText.replace(/<\//g, "<\\u002F");
}
