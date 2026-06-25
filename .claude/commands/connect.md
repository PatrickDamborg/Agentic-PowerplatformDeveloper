# /connect — Initialize Dataverse Session

Establish an authenticated Dataverse session for the current engagement. Run this at the start of every session before any Dataverse work.

## Usage
- `/connect` — list available environments and choose
- `/connect dev` — connect directly to the dev environment (root `.env`)
- `/connect <name>` — connect directly to a customer environment in `customers/<name>/`
- `/connect new` — add a new customer environment and connect

---

## Step 1 — Select Environment

If no argument was given, scan the `customers/` directory (skip `_template`) and present:

```
Available environments:
  [dev]   root .env  (developer environment)
  [1]     contoso    customers/contoso/
  [2]     fabrikam   customers/fabrikam/
  [+]     Add new customer environment

Which environment?
```

Wait for the user's selection before continuing.

---

## Step 2 — Load Credentials

**Dev environment:**
- Read root `.env`
- Verify all four fields are present and non-empty: `DATAVERSE_URL`, `TENANT_ID`, `CLIENT_ID`, `CLIENT_SECRET`
- If any field is missing, show which ones are missing and stop

**Customer environment (existing):**
- Show `customers/<name>/notes.md` if it exists (gives context before asking for credentials)
- Prompt: _"Please provide the connection strings for `<name>`:"_
- Collect: `DATAVERSE_URL`, `TENANT_ID`, `CLIENT_ID`, `CLIENT_SECRET`
- Write them to `customers/<name>/.env` (this file is gitignored)

**New customer environment (`[+]` or `/connect new`):**
- Prompt: _"Name for this environment (used as folder name):"_
- Create `customers/<name>/` directory
- Copy `customers/_template/notes.md` → `customers/<name>/notes.md`
- Then follow the customer credentials flow above

---

## Step 3 — Authenticate

**Check token cache first.** If `.token` exists and is less than 55 minutes old, skip re-authentication entirely — reuse the cached token. Token lifetime is 1 hour; 55 min gives a safe buffer.

```powershell
$tokenFile = ".token"   # or "customers/<name>/.token" for customer envs
$tokenAge  = if (Test-Path $tokenFile) { (Get-Date) - (Get-Item $tokenFile).LastWriteTime } else { $null }
$tokenFresh = $tokenAge -and $tokenAge.TotalMinutes -lt 55
```

- **Token is fresh** → skip `connect.ps1`, read the existing token from `.token`.
- **Token is missing or stale** → run `connect.ps1` (or the customer variant) to acquire a new one.

```powershell
# Only when token is stale/missing:
pwsh -File connect.ps1                               # dev
pwsh -File connect.ps1 -EnvPath "customers/<name>/.env"  # customer
```

If authentication fails, surface the full error and stop. Do not continue to Step 4.

---

## Step 4 — Select Solution (with publisher included)

Fetch solutions **and** their publisher in a single query using `$expand`:

```powershell
$url = "$baseUrl/solutions?`$filter=ismanaged eq false and uniquename ne 'Default'" +
       "&`$select=uniquename,friendlyname,version" +
       "&`$expand=publisherid(`$select=customizationprefix,friendlyname)" +
       "&`$orderby=friendlyname"
```

Present the list and ask: _"Which solution should I target for this session?"_

Wait for the user's choice. The publisher prefix is already in the response — no further API call needed.

---

## Step 5 — Derive Publisher Prefix

Read the prefix directly from the Step 4 response for the chosen solution:

```powershell
$prefix = $chosenSolution.publisherid.customizationprefix
```

No additional API call. This is the publisher prefix for the session — use it for all SchemaName values (tables, columns, etc.). Do not ask the user for the prefix.

---

## Step 6 — Session Summary

Print a confirmation block:

```
╔══════════════════════════════════════════════╗
  Connected
  Environment : https://<org>.api.crm.dynamics.com
  Solution    : <friendlyname> (<uniquename>)
  Publisher   : <prefix>
  Org ID      : <guid>
╚══════════════════════════════════════════════╝
```

The session is ready. All subsequent Dataverse work uses the authenticated connection and the derived prefix.
