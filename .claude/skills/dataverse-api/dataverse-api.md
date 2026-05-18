---
name: dataverse-api
description: Rules for making Dataverse Web API calls. Load when writing or debugging any REST/OData call to Dataverse.
---

# Dataverse API Usage

Before making ANY Dataverse Web API call:

1. **Check in-repo skill docs first** — `model-driven-app/model-driven-app.md`, `data-model/`, and this file contain confirmed patterns from live API calls. Use the Microsoft Learn MCP only for operations not yet covered here.

2. **Verify entity logical names** — Before referencing any table in a relationship, lookup, or query, confirm the exact logical name by querying `EntityDefinitions` (e.g., filter by `LogicalName` containing the expected prefix). Do not assume spelling — names may differ from what the user says (e.g., `pum_resource` not `pum_ressource`).

3. **Publisher prefix is immutable** — The publisher prefix is baked into SchemaName at creation time and cannot be changed afterward. If the wrong prefix is used, the only fix is to delete and recreate. Always confirm the prefix before creating any component.

---

## Confirmed API patterns (live-tested, May 2026)

### OData-EntityId extraction after POST

POST to entity collections (e.g. `/appmodules`, `/sitemaps`) returns HTTP 204 with an `OData-EntityId` header containing a URL. Extract the GUID:

```powershell
$id = [regex]::Match($resp.Headers['OData-EntityId'], '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}').Value
```

Always verify the record was persisted immediately after creation — some endpoints (e.g. `appmodules`) return a fake EntityId on silent failure. See `model-driven-app.md` for details.

### PATCH with `If-Match: *`

Required for all PATCH operations to avoid optimistic concurrency conflicts:

```powershell
$patchHeaders = $conn.Headers.Clone()
$patchHeaders["If-Match"] = "*"
Invoke-RestMethod -Method PATCH -Uri "$baseUrl/entity($id)" -Headers $patchHeaders -Body $body
```

### ObjectTypeCode lookup

Each custom table has an integer `ObjectTypeCode` needed for LayoutXml `object` attributes in views. Fetch once and cache:

```powershell
$meta = Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions?`$filter=LogicalName eq 'context_mytable'&`$select=ObjectTypeCode" -Headers $headers
$typeCode = $meta.value[0].ObjectTypeCode
```

### Solution membership via `MSCRM.SolutionUniqueName` header

Add `MSCRM.SolutionUniqueName: <solution>` to the request headers when creating any component (table, column, app module, etc.) to automatically add it to the target solution:

```powershell
$headers["MSCRM.SolutionUniqueName"] = "ContextFitnessAgent"
```

### internal `entities` table

The internal Dataverse `entities` table (endpoint: `/entities`) is accessible via OData and stores entity definitions. Its primary key `entityid` equals the `MetadataId` from `EntityDefinitions`. Useful for:

```powershell
# Lookup entityid by logical name
$r = Invoke-RestMethod -Uri "$baseUrl/entities?`$filter=name eq 'context_trainingprogramme'&`$select=entityid,name" -Headers $headers
```

### `AddAppComponents` — confirmed working format

Only the SiteMap component type works reliably via the REST API:

```powershell
# Add a SiteMap (componenttype=62) — WORKS
$components = @([ordered]@{ '@odata.type' = 'Microsoft.Dynamics.CRM.sitemap'; sitemapid = $sitemapId })
$body = @{ AppId = $appId; Components = $components } | ConvertTo-Json -Depth 5
Invoke-RestMethod -Method POST -Uri "$baseUrl/AddAppComponents" -Headers $headers -Body $body
```

Entity components (componenttype=1) cannot be added via `AddAppComponents` — all known formats silently fail or error. See `model-driven-app.md` Known Gotchas #5.
