# 1Password Secrets Skill — Requirements Spec

> **Status:** Requirements/design document only. Nothing in this spec has been
> implemented. Hand this document to a coding agent (or implement it directly)
> to build the skill described below.
>
> **Scope note:** This skill is a **general personal utility** for the user
> across any project/session — it is not specific to the MDA-Agent-Dashboard
> app in this repository, which has no secrets-management code or `.claude/`
> tooling of its own today. This document lives in this repo only because
> that's where the research request originated.

## 0. Summary

A Claude Code **Skill** (not an MCP server, not an SDK integration) that wraps
the official 1Password CLI (`op`) to let the agent retrieve secrets, list
vault contents, and inject credentials into files/env vars on the user's
behalf. It is installed at the **user level**
(`~/.claude/skills/1password/`, not inside any single project's `.claude/`),
authenticates **headlessly** via a scoped 1Password **Service Account**
token, never depends on biometric unlock or an interactive desktop session,
and enforces least-privilege vault scoping throughout.

---

## 1. Auth Architecture

### 1.1 Recommended approach: Service Account token

Use a **1Password Service Account**, not personal `op signin`.

- Service accounts authenticate via a single bearer token exported as
  `OP_SERVICE_ACCOUNT_TOKEN` in the process environment. Once that variable is
  set, every `op` invocation in that shell is already authenticated — no
  `op signin`, no biometric prompt, no session-token refresh, no desktop app
  requirement.
- This is the only 1Password auth mode that works in a headless/ephemeral
  container (e.g. Claude Code on the web), because interactive `op signin`
  requires either biometric hardware (Touch ID/Windows Hello via the desktop
  app integration) or manually re-entering the secret key + master password
  to mint a session token that expires and needs periodic renewal — none of
  which survive in a disposable container or work without a human at a
  keyboard.
- Service accounts are created, named, and revoked independently from the
  1Password web console (Settings → Service Accounts) without touching the
  user's own account credentials or 2FA.

### 1.2 Vault scoping (least privilege)

- Create a **dedicated vault** (default suggestion: `Agent-Secrets` — confirm
  exact naming with the user before hardcoding it anywhere, see §10)
  containing *only* the items the user explicitly wants Claude to be able to
  read. Never the user's personal/banking/health/full vault.
- When creating the Service Account, grant it access to **only that one
  vault**, with only the **"Read items"** permission (1Password service
  accounts support per-vault, per-permission scoping: read / write / manage).
  Do not grant write/manage unless the user explicitly wants the skill to
  create/update items — default is strictly read-only.
- Blast radius containment: if the skill ever runs an unexpected `op`
  command (bug, prompt injection, etc.), the worst case is reading an item in
  this one small curated vault — never the user's full 1Password account.
- The helper script must **hard-fail**, never silently broaden scope, when a
  requested item/vault isn't accessible to the token (§4).

### 1.3 Where the token itself lives

Ranked by preference:

1. **Claude Code environment secret / shell profile env var (primary path)**
   — for Claude Code on the web, configure `OP_SERVICE_ACCOUNT_TOKEN` as an
   environment secret in the environment's settings (never written into any
   repo). For local use, export it from `~/.zshrc`/`~/.bashrc`/`~/.profile`.
   This works identically whether the session is local or cloud, and is what
   the skill should assume/check for.
2. **OS keychain (local-only enhancement)** — on a local machine, store the
   token in the OS keychain (`security` on macOS, `secret-tool` on Linux) and
   read it into the env at session start. Never touches disk in plaintext,
   but unavailable in cloud containers — optional, not the primary path.
3. **Gitignored local `.env` (fallback)** — acceptable for local-only use if
   the user prefers a per-machine file, e.g. `~/.claude/skills/1password/.env`
   — **must** live outside any git-tracked project folder. The skill's own
   directory must `.gitignore` this file as defense-in-depth even though it
   isn't meant to be committed at all.
4. **Never**: hardcoded in `SKILL.md`, hardcoded in any helper script,
   committed to any repo, printed to stdout/logs, or pasted into the chat
   conversation as a workaround.

**Rotation/revocation guidance:**
- Rotate the token periodically (e.g. every 90 days) or immediately on
  suspected leak, by generating a new token for the same service account in
  the 1Password console and updating it wherever it's stored (§1.3).
- Revoke instantly by deleting/suspending the Service Account in the console
  — this invalidates the token immediately, no client-side action needed.
- Because the account is scoped to one small vault, rotation/revocation blast
  radius is inherently small.

### 1.4 Interactive `op signin` fallback — decision: not supported in v1

- **Pros of adding it**: lets a user with the 1Password desktop app skip
  creating a service account, using their full existing account.
- **Cons**: requires biometric unlock or session-token re-entry every ~30
  days — incompatible with headless/cloud sessions, inconsistent behavior
  between local and web Claude Code, and grants the skill access to the
  *entire* account rather than a scoped vault (violates least privilege). It
  also reintroduces mid-task interactive unlock prompts, the exact friction
  the service-account design avoids.
- **Decision**: v1 supports Service Account auth only, uniformly across local
  and cloud sessions. This is a firm design choice, not left ambiguous — flag
  it to the user as confirmed (§10) before treating it as settled.

---

## 2. Skill File Layout

Install at the **user level** so it's available across all projects/sessions:

```
~/.claude/skills/1password/
├── SKILL.md                 # frontmatter + agent-facing instructions (what Claude reads)
├── scripts/
│   └── op-helper.sh         # thin wrapper around `op`; sole subprocess boundary
├── REFERENCE.md             # detailed command reference + install/setup steps
└── .gitignore                # excludes any local .env / cache from accidental version control
```

(If the user later wants it project-scoped for a specific team/repo, the same
layout works under `<repo>/.claude/skills/1password/` — but the default
target is the user-level path above.)

### 2.1 `SKILL.md` — frontmatter and body

Follow standard Claude Code Skill conventions: YAML frontmatter with `name`
and `description` only, then a plain markdown instructional body.

```markdown
---
name: 1password
description: Retrieve passwords, API keys, client secrets, and other credentials stored in 1Password on the user's behalf, via the 1Password CLI (op). Use this whenever the user asks for a password, secret, API key, credential, or token that might be stored in 1Password (e.g. "what's my AWS secret key", "get me the DB password for staging", "look up my GitHub token"), or asks to list/search what's available in their Agent-Secrets vault. Never fabricate credentials — always retrieve them live via this skill.
---

# 1Password Secrets Retrieval

## Preconditions (check before first use)
1. Verify the `op` CLI is installed and on PATH (`op --version`). If missing,
   stop and show install instructions (see REFERENCE.md) — do not attempt to
   install it silently.
2. Verify `OP_SERVICE_ACCOUNT_TOKEN` is set in the environment. If not set,
   stop and explain the one-time setup (REFERENCE.md "Setup") — do not
   prompt the user to paste a token into the conversation, and never accept
   a token via chat.
3. Never ask the user to type a secret, password, or token directly into the
   conversation as a workaround.

## How to retrieve a secret
Use `scripts/op-helper.sh` for all `op` invocations — never call `op`
directly with unsanitized/interpolated item or vault names from user text
(see "Shell-injection safety rule" below).

- Get a specific field: `scripts/op-helper.sh get-field <vault> <item> <field>`
- Search for an item by (partial) title: `scripts/op-helper.sh find-item <vault> <query>`
- List item titles in the scoped vault (metadata only, never values):
  `scripts/op-helper.sh list-items <vault>`
- List vaults the service account can see: `scripts/op-helper.sh list-vaults`
- Get a one-time password / TOTP code: `scripts/op-helper.sh get-otp <vault> <item>`

Map the user's natural-language request to these primitives. Example: "get me
my AWS secret key" → `find-item` to disambiguate the exact item title if not
exact, then `get-field` for the field literally holding the secret key. If
more than one item matches a search, list the candidate titles and ask the
user which one before retrieving any field value. If no vault is named,
default to the single configured vault (see REFERENCE.md "Configuration").

## Presenting results
- Only surface the specific field(s) the user asked for — never dump full
  item JSON into the conversation.
- Never write a retrieved secret to any file, shell history, or persistent
  note as a side effect. If the user asks to inject a secret into a file
  (e.g. a `.env` for a running process), use `op inject` via the helper
  script so the value is templated directly into the target file by `op`
  itself, never echoed through the model's own output — confirm only
  success/failure and the file path back to the user.
- Do not log secret values anywhere beyond what's unavoidably shown to the
  user in direct response to their explicit request for that value.

## Error handling
Surface `op`'s own error text; never retry with broader scope, never fall
back to another vault or to interactive signin silently. See REFERENCE.md
"Error handling" for the specific failure modes to expect.
```

### 2.2 Helper script (`scripts/op-helper.sh`)

- A POSIX-ish `bash` script (zero extra runtime dependency — do not require
  Node just for this) that is the **only** thing allowed to shell out to
  `op`. Claude never constructs raw `op` command strings itself; it calls
  this script with positional arguments.
- Responsibilities:
  - Pre-flight checks: `op` on PATH, `OP_SERVICE_ACCOUNT_TOKEN` set and
    non-empty.
  - All user-derived values (vault name, item name/title, field name, search
    query) passed as **separate argv elements**, never interpolated into a
    shell string — this is the injection defense (§3).
  - Prefer `op read "op://<vault>/<item>/<field>"` for single-field fetches —
    it returns exactly the field value on stdout with nothing else, avoiding
    JSON parsing and avoiding accidentally exposing other fields.
  - For search/list, use `op item list --vault <vault> --format json` and
    `op item get <item> --vault <vault> --format json`, extracting only
    titles/field-labels — never dump raw JSON containing secret values
    unless a specific field was requested.
  - Exit non-zero with `op`'s own stderr surfaced verbatim on any failure
    (not-found, no-access, not-authenticated, `op` missing) — no "friendly"
    message that hides *why* it failed, and no automatic retry against a
    different/broader vault.
  - Never write anything to disk (no temp files, no cache dir) and never
    write secret values to stdout except as the direct, requested return
    value of a `get-field`/`get-otp` call.

### 2.3 Install / setup steps (for `REFERENCE.md`)

1. Install the `op` CLI binary (`brew install --cask 1password-cli` on
   macOS; official `.deb`/`.rpm`/tarball per 1Password's docs on Linux;
   Windows installer on Windows) — a one-time host/container setup step,
   ideally baked into any reusable Claude Code environment/container image,
   or documented as a `SessionStart` step for Claude Code on the web (see
   this environment's existing `session-start-hook` skill pattern — confirm
   with the user whether that's wanted, §10).
2. In the 1Password web console: create the vault (e.g. `Agent-Secrets`),
   add only the specific items the user wants Claude to access.
3. Create a Service Account, grant it **read-only** access scoped to only
   that vault, copy the generated token once (1Password only shows it once).
4. Store the token per §1.3 (environment secret for Claude Code on the web,
   or shell profile / OS keychain locally).
5. Verify with `op vault list` / `op whoami` using only the service-account
   token — no `op signin` step at all.

---

## 3. Tool Capabilities / Commands to Support

| Capability | `op` command used | Notes |
|---|---|---|
| List accessible vaults | `op vault list --format json` | Metadata only (name/id), no items. |
| List item titles in a vault | `op item list --vault <vault> --format json` | Titles/categories only; never bulk-fetch field values. |
| Search items by title | `op item list --vault <vault> --format json`, filtered client-side by substring match on title | Avoids depending on a fuzzy-search flag that may not exist. |
| Get a specific field | `op read "op://<vault>/<item>/<field>"` | Preferred: returns exactly one value, nothing else. |
| Get a specific field (fallback) | `op item get <item> --vault <vault> --fields label=<field> --format json` | Use if the secret-reference syntax doesn't resolve (e.g. ambiguous title). |
| Get OTP/2FA code | `op item get <item> --vault <vault> --otp` | Time-sensitive; fetch fresh every time, never cache. |
| Inject secret into a file/template | `op inject -i <template> -o <output>` | For "put this secret into a `.env` for my app to run" — secret flows straight from `op` to the output file, bypassing the model's context. |

**Shell-injection safety rule (mandatory):** vault names, item titles, field
names, and search queries all originate from user chat text and must be
treated as untrusted input. The helper script must:
- Pass every such value as a **separate argv element** to `op` (e.g. quoted
  bash variables passed individually — never built via string concatenation
  with unescaped user text, never passed through `eval`, `sh -c "…$input…"`,
  or backticks).
- Reject or escape characters that would be meaningful to `op://` URI parsing
  (e.g. reject values containing unescaped `/` where a single path segment is
  expected), or use `op item get` with discrete `--vault`/`--fields` args
  instead of building the `op://` URI when a name could plausibly contain
  slashes.
- Never construct commands by string-interpolating raw user text into
  anything passed to `bash -c`, `sh -c`, `system()`, or similar.

---

## 4. Security Requirements Checklist

- [ ] Service account scoped to exactly one dedicated vault, read-only
      unless the user explicitly opts into write access.
- [ ] Token never hardcoded in `SKILL.md`, helper scripts, or any file inside
      a git-tracked project.
- [ ] Token sourced only from the environment (`OP_SERVICE_ACCOUNT_TOKEN`) —
      the skill checks for its presence and fails clearly; never prompts the
      user to paste it into chat.
- [ ] If a local `.env` fallback is used, it lives outside any project repo,
      and `~/.claude/skills/1password/.gitignore` includes `.env` and any
      cache directory as defense-in-depth.
- [ ] No secret values are ever written to disk by the skill itself (no
      caching, no debug dumps, no temp files) — the only disk write
      permitted is the user's own explicit `op inject` target file.
- [ ] No secret values are logged: the helper script must not `echo`/print
      full `op item get` JSON responses, must not enable `set -x` while
      secret values are in scope, and must not surface secrets via any
      persistent, history-visible command (script args are titles/vault
      names/field names, not secret values — only `op read`'s *output*
      carries the secret, not its invocation).
- [ ] Helper script exits non-zero and surfaces `op`'s real error text
      unmodified on: `op` not installed, token missing/invalid, item/vault
      not found, insufficient permissions. No silent fallback to a broader
      vault or to interactive `op signin`.
- [ ] 1Password's own item-access audit log (visible in the 1Password
      console) is the source of truth for what was accessed and when — no
      separate audit log needs to be built by this skill.
- [ ] The skill never fabricates or guesses a credential value on retrieval
      failure — it reports failure, it does not hallucinate a
      plausible-looking secret.

---

## 5. Testing / Verification Plan

1. **Happy path** — create a dummy item (e.g. title `Test Item`, field
   `password` = a throwaway value) in the scoped vault. Ask "what's my Test
   Item password" and confirm the skill returns exactly that value via
   `op read`, with no extra JSON/noise.
2. **Search/disambiguation path** — create two items with similar titles;
   ask a vague query; confirm the skill lists both candidates and asks which
   one before retrieving any value.
3. **List path** — confirm `list-items`/`list-vaults` return titles/names
   only; manually inspect the transcript to confirm no field values leaked.
4. **Missing `op` binary** — temporarily remove `op` from PATH and confirm a
   clear "op CLI not installed" error, not a crash or silent no-op.
5. **Missing/invalid token** — unset `OP_SERVICE_ACCOUNT_TOKEN` and confirm a
   clear "not authenticated" error, with no fallback to interactive signin.
6. **Out-of-scope access** — ask for an item that exists in the user's
   personal vault but *not* shared with the service account, and confirm the
   skill reports "not found / no access" rather than escalating or guessing.
7. **Injection attempt** — create a test item whose title contains shell
   metacharacters (e.g. `test; whoami`, `` test`id` ``, `test$(id)`) and
   confirm the helper script treats it as a literal string with no command
   execution side effects.
8. **Log/history leak check** — after a real secret retrieval, grep the
   shell history, any session transcript/log files, and the helper script's
   own stdout/stderr capture to confirm the secret value only appears in the
   final user-facing answer, nowhere else.
9. **OTP freshness** — request a TOTP twice a few seconds apart and confirm
   the value is fetched fresh each time (not cached/stale).
10. **Inject-to-file path** — use `op inject` to populate a scratch
    `.env`/config file from a template; confirm the file contains the
    correct value and the secret itself was never echoed into the
    conversation during that flow (only success/path confirmation was).

---

## 6. Open Questions for the Implementing Agent to Confirm

1. **Vault naming convention** — is `Agent-Secrets` the desired name, or
   does the user want something else, or support for multiple curated
   vaults (e.g. per-project vaults)? Confirm before hardcoding a default
   name anywhere in `SKILL.md`/`REFERENCE.md`.
2. **Multiple 1Password accounts** — does the user have more than one
   account (e.g. personal + work)? If so, should the skill support selecting
   between multiple service-account tokens (e.g.
   `OP_SERVICE_ACCOUNT_TOKEN_PERSONAL` / `_WORK`), or is a single
   account/token sufficient for v1?
3. **OTP/2FA support** — confirm whether `op item get --otp` support (§3)
   is in scope for v1 or a later addition — it has a different trust
   profile (short-lived, time-sensitive) worth explicit opt-in.
4. **Write access** — should the skill ever support creating/updating items
   (e.g. "save this new API key to 1Password for me"), or is v1 strictly
   read-only? This changes the service account's permission grant (§1.2).
5. **`op inject` scope** — confirm exactly which use cases warrant file
   injection vs. direct chat display — e.g. should the skill *default* to
   injection whenever a secret is being used to configure/start a running
   process, and only display in chat when the user's literal ask is "what
   is my password"?
6. **Environment bootstrapping** — for Claude Code on the web, does the user
   want a `SessionStart` hook (see the existing `session-start-hook` skill
   pattern) that verifies `op` is installed and the token is present at the
   start of every session, surfacing setup instructions immediately if not?
   Confirm whether that's in scope for this skill or a separate concern.
7. **Interactive fallback** — confirm the §1.4 decision (service-account-only,
   no `op signin` fallback) is acceptable, or whether the user wants an
   optional local-desktop interactive mode added later as a secondary path.
8. **Team/shared vaults** — if the user's 1Password account is a
   Business/Teams account rather than an individual account, confirm there's
   no conflicting admin-enforced vault-permission policy that would block a
   personal service account from being scoped as described.

---

## 7. Critical Files for Implementation

- `~/.claude/skills/1password/SKILL.md` — frontmatter + agent-facing behavior
  contract (§2.1)
- `~/.claude/skills/1password/scripts/op-helper.sh` — sole subprocess
  boundary to `op`, injection-safe argument handling (§2.2, §3)
- `~/.claude/skills/1password/REFERENCE.md` — command reference,
  setup/install steps, error-handling table (§2.3)
- `~/.claude/skills/1password/.gitignore` — excludes any local `.env`/cache
  as defense-in-depth (§4)
- *(Environment-level, not in this directory)* Claude Code on the web
  environment secret configuration, or shell profile entry, for
  `OP_SERVICE_ACCOUNT_TOKEN` (§1.3)
