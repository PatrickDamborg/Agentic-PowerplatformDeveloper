---
name: security-roles
description: Sequence for creating a new custom Dataverse security role — always copy Basic User first, then customize. Load when creating a new security role or granting/revoking table privileges on an existing one.
---

# Security Role Management

## Creating a new custom security role

**Always start by copying the `Basic User` system role — never build a custom role from scratch.**

Why: `Basic User` ships with the baseline privileges every interactive user needs (read/write their own records on core system tables, run the app, see their own user settings, etc.). A role built from zero looks fine in isolation but silently breaks basic app functionality for anyone assigned it — they can't open forms, see their own record, etc.

### Sequence

1. **Copy `Basic User`** — Power Platform admin center (or classic Settings > Security > Security Roles) → find `Basic User` → **Copy Role**. Do this via the maker/admin portal UI. There is no confirmed single-call Web API equivalent for "Copy Role" (see limitation below).
2. **Rename** the copy to its final name immediately, before making any other change, so it isn't confused with other in-flight copies.
3. **Customize privileges** on the *new* (copied) role only — add/remove table-level privileges (Create/Read/Write/Delete/Append/AppendTo/Assign/Share) for the specific tables the role needs, at the correct depth. Never modify `Basic User` itself.
4. **Assign the new role** to the relevant users/teams.

### Known limitation: no single-call "Copy Role" via Web API

The portal's "Copy Role" button isn't exposed as a documented bound/unbound Web API action. If scripting is the only option (no portal access), approximate it by replaying every privilege from the source role onto a freshly created role record:

```powershell
# 1. Read every privilege+depth on the source role (e.g. Basic User in the root business unit)
$sourceRoleId = "<basic-user-roleid>"
$source = Invoke-RestMethod -Uri "$baseUrl/RetrieveRolePrivilegesRole(RoleId=$sourceRoleId)" -Headers $headers

# 2. Create the new role record in the same business unit
$newRoleBody = @{ name = "xPM Dashboard User"; "businessunitid@odata.bind" = "/businessunits($buId)" } | ConvertTo-Json
$resp = Invoke-WebRequest -Method Post -Uri "$baseUrl/roles" -Headers $headers -Body $newRoleBody -UseBasicParsing
$newRoleId = [regex]::Match($resp.Headers['OData-EntityId'], '[0-9a-f-]{36}').Value

# 3. Replay every privilege from the source role onto the new role
$privileges = $source.RolePrivileges | ForEach-Object { @{ PrivilegeId = $_.PrivilegeId; Depth = $_.Depth } }
$body = @{ Privileges = $privileges } | ConvertTo-Json -Depth 5
Invoke-WebRequest -Method Post -Uri "$baseUrl/roles($newRoleId)/Microsoft.Dynamics.CRM.AddPrivilegesRole" -Headers $headers -Body $body -UseBasicParsing
```

This replicates privilege *content* but may miss non-privilege settings the portal's Copy Role also carries over. Prefer the portal button when it's available; use the script only when Web API is the only option.

## Adding/removing specific privileges on an existing role

Confirmed live-tested pattern (used to grant read on `pda_monitoredagent`/`workflow`/`flowrun` and read+write on `pda_agentaction` to `Projectum xPM Project Manager`, 2026-07-06):

```powershell
# Find a privilege's GUID by naming convention prv{Type}{entitylogicalname}
$priv = Invoke-RestMethod -Uri "$baseUrl/privileges?`$filter=name eq 'prvReadpda_agentaction'" -Headers $headers
$privilegeId = $priv.value[0].privilegeid

# Grant it at Global depth
$body = @{ Privileges = @(@{ PrivilegeId = $privilegeId; Depth = "Global" }) } | ConvertTo-Json -Depth 5
Invoke-WebRequest -Method Post -Uri "$baseUrl/roles($roleId)/Microsoft.Dynamics.CRM.AddPrivilegesRole" -Headers $headers -Body $body -UseBasicParsing

# Verify (do NOT try to $select/$filter the roleprivileges_association navigation directly — it 400s;
# use the RetrieveRolePrivilegesRole function instead)
$check = Invoke-RestMethod -Uri "$baseUrl/RetrieveRolePrivilegesRole(RoleId=$roleId)" -Headers $headers
$check.RolePrivileges | Where-Object { $_.PrivilegeId -eq $privilegeId }
```

To revoke, use `Microsoft.Dynamics.CRM.RemovePrivilegeRole` with `{ "PrivilegeId": "<guid>" }`.

Privilege naming convention: `prv{Create|Read|Write|Delete|Append|AppendTo|Assign|Share}{entitylogicalname}` (e.g. `prvWritepda_agentaction`).

Depth values, narrowest to widest: `Basic` (User) → `Local` (Business Unit) → `Deep` (Parent:Child BU) → `Global` (Organization). Organization-owned tables effectively only support `Global`.

### Finding a system role's ID

Every business unit has its own copy of each system role (including `Basic User`), so filter by business unit if the environment has more than one:

```powershell
$basicUser = Invoke-RestMethod -Uri "$baseUrl/roles?`$select=roleid,name&`$filter=name eq 'Basic User' and _businessunitid_value eq $rootBuId" -Headers $headers
```
