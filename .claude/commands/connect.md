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

Run `connect.ps1` with the appropriate env file:

```powershell
# Dev
pwsh -File connect.ps1

# Customer
pwsh -File connect.ps1 -EnvPath "customers/<name>/.env"
```

If authentication fails, surface the full error and stop. Do not continue to Step 4.

---

## Step 4 — Select Solution

Query available unmanaged solutions:

```powershell
$url = "$baseUrl/solutions?`$filter=ismanaged eq false and uniquename ne 'Default'&`$select=uniquename,friendlyname,version&`$orderby=friendlyname"
```

Present the list and ask: _"Which solution should I target for this session?"_

Wait for the user's choice.

---

## Step 5 — Derive Publisher Prefix

Query the selected solution's publisher:

```powershell
$url = "$baseUrl/solutions?`$filter=uniquename eq '<chosen>'&`$expand=publisherid(`$select=customizationprefix,friendlyname)&`$select=uniquename"
$prefix = $resp.value[0].publisherid.customizationprefix
```

This is the publisher prefix for the session. Store it and use it for all SchemaName values (tables, columns, etc.). Do not ask the user for the prefix.

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
