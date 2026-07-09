---
name: model-driven-app
description: Rules and scripts for creating model-driven apps (AppModule + SiteMap) and updating their forms (FormXml) or views (FetchXml/LayoutXml) via the Dataverse Web API. Load when creating a model-driven app, or modifying a form or view.
---

# Model-Driven App Skill

Use this skill when creating or modifying model-driven apps (MDA) in Dataverse via the Web API.

## Scripts

| Script | Purpose |
|--------|---------|
| `create-mda.ps1` | Create AppModule + SiteMap, add entities, publish |
| `update-forms.ps1` | Update main forms for one or more tables |
| `update-views.ps1` | Update default active views for one or more tables |

---

## AppModule Creation

### Required fields (do NOT omit any of these)

| Field | Type | Correct value | Notes |
|-------|------|--------------|-------|
| `name` | String | Display name, e.g. "Fitness Training" | This is the friendly display name |
| `uniquename` | String | Short identifier, e.g. "FitnessTraining" | Auto-prefixed with publisher prefix on save (e.g. → `context_FitnessTraining`) |
| `webresourceid` | GUID | `953b9fac-1e5e-e611-80d6-00155ded156f` | Standard default icon — must be present, cannot be null |
| `clienttype` | Integer | **4** | Unified Interface. NOT 1 (classic). Without this, creation silently fails — app is not persisted. |
| `formfactor` | Integer | **1** | Tablet / Unified Interface. NOT 2. Same result as above if missing. |

### Optional fields

| Field | Type | Notes |
|-------|------|-------|
| `description` | String | Plain text description |
| `introducedversion` | String | e.g. "1.0.0.0" |

### Response

POST to `/appmodules` returns HTTP 204 with `OData-EntityId` header containing the app module URL.
Extract the GUID from the URL. **Verify the app was created** by immediately querying `/appmodules?$filter=uniquename eq '<auto-prefixed-name>'`.

> **Warning:** If `clienttype` or `formfactor` are missing, the API returns 204 with a fake `OData-EntityId` but the record is NOT persisted. Subsequent creation attempts fail with `0x80050135` because the uniquename is reserved.

### Idempotency check

Query by auto-prefixed uniquename. The prefix added matches the solution publisher prefix from `MSCRM.SolutionUniqueName` header. Example: solution publisher `context` + uniquename `FitnessTraining` → `context_FitnessTraining`.

```powershell
$existing = Invoke-RestMethod -Uri "$baseUrl/appmodules?`$filter=uniquename eq 'context_FitnessTraining'&`$select=appmoduleid" -Headers $headers
```

---

## SiteMap Creation

### Required fields

| Field | Type | Notes |
|-------|------|-------|
| `sitemapname` | String | Display name |
| `sitemapnameunique` | String | Unique identifier — required, cannot be null |
| `sitemapxml` | String | Full SiteMap XML (see below) |
| `isappaware` | Boolean | true |
| `showhome` | Boolean | false for simple apps |
| `showpinned` | Boolean | true |
| `showrecents` | Boolean | true |
| `enablecollapsiblegroups` | Boolean | false |

### SiteMap XML format

```xml
<SiteMap>
  <Area Id="area_id" Title="Area Display Name" ShowGroups="true">
    <Group Id="group_id" Title="Group Title" IsProfile="false">
      <SubArea Id="nav_entity1" Entity="context_entity1" Title="Entity Display Name" />
      <SubArea Id="nav_entity2" Entity="context_entity2" Title="Entity 2" />
    </Group>
  </Area>
</SiteMap>
```

### Response

POST to `/sitemaps` returns HTTP 204 with `OData-EntityId` header.

---

## AddAppComponents

### Adding a SiteMap component (componenttype=62)

Use `@odata.type: "Microsoft.Dynamics.CRM.sitemap"` + `sitemapid`:

```powershell
$components = @(
    [ordered]@{ '@odata.type' = 'Microsoft.Dynamics.CRM.sitemap'; sitemapid = $sitemapId }
)
$body = @{ AppId = $appId; Components = $components } | ConvertTo-Json -Depth 5
Invoke-RestMethod -Method POST -Uri "$baseUrl/AddAppComponents" -Headers $headers -Body $body
```

### Adding entity components (componenttype=1)

**This cannot be done via the REST API.** The `AddAppComponents` action rejects all known formats for entity references (`ComponentType`/`ObjectId` properties don't exist on `crmbaseentity`; `EntityMetadata` type is not assignable to `crmbaseentity`; using `Microsoft.Dynamics.CRM.entity` + `entityid` returns 204 but silently does nothing). Add entity components through the App Designer UI instead.

To update the sitemap so entities appear in navigation, PATCH the `sitemapxml` field of the sitemap record directly — the sitemap drives what's visible in the app nav bar, which is what participants need for the app to work.

### Component type codes

| Code | Type |
|------|------|
| 1 | Entity (table) — use MetadataId |
| 26 | View (SavedQuery) |
| 60 | Form (SystemForm) |
| 62 | SiteMap |

### Entity MetadataId lookup

```powershell
$meta = Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions?`$filter=LogicalName eq 'context_mytable'&`$select=MetadataId" -Headers $headers
$metadataId = $meta.value[0].MetadataId
```

---

## Querying App Modules

```powershell
# List all (managed + unmanaged)
GET /appmodules?$select=appmoduleid,name,uniquename,clienttype,formfactor,webresourceid,statuscode,ismanaged

# Find by uniquename (include auto-prefix)
GET /appmodules?$filter=uniquename eq 'context_FitnessTraining'&$select=appmoduleid,name

# Get appmoduleidunique (needed for component queries)
GET /appmodules({appmoduleid})?$select=appmoduleid,appmoduleidunique
```

---

## Updating Forms

### Find the main form for a table

```powershell
GET /systemforms?$filter=objecttypecode eq 'context_mytable' and type eq 2&$select=formid,name,formxml
```

Form type 2 = Main form.

### PATCH with new FormXml

```powershell
$patchHeaders = $headers.Clone()
$patchHeaders["If-Match"] = "*"
$body = @{ formxml = $formXml } | ConvertTo-Json
Invoke-RestMethod -Method PATCH -Uri "$baseUrl/systemforms($formId)" -Headers $patchHeaders -Body $body
```

Then publish: `POST /PublishXml` with `<importexportxml><entities><entity>context_mytable</entity></entities></importexportxml>`

### FormXml control classids (confirmed from live forms)

| Field type | ClassId GUID |
|-----------|-------------|
| String (single line) | `{4273EDBD-AC1D-40d3-9FB2-095C621B552D}` |
| Memo (multi-line) | `{E0DECE4B-6FC8-4a8f-A065-082708572369}` |
| Integer / Decimal | `{C6D124CA-7EDA-4a60-AEA9-7FB8D318B68F}` |
| Choice (Picklist) | `{3EF39988-22BB-4f0b-BBBE-64B5A3748AEE}` |
| DateTime / DateOnly | `{5B773807-9FB2-42db-97C3-7A91EFF8ADFF}` |
| Lookup | `{270BD3DB-D9AF-4782-9025-509E298DEC0A}` |
| Boolean (Yes/No) | `{67FAC785-CD58-4f9f-ABB3-4B7DDC6ED5ED}` |

### Minimal FormXml structure

```xml
<form>
  <tabs>
    <tab verticallayout="true" id="{TAB-GUID}" IsUserDefined="1">
      <labels><label description="General" languagecode="1033" /></labels>
      <columns>
        <column width="100%">
          <sections>
            <section name="sec_details" showlabel="true" showbar="false" columns="2" id="{SEC-GUID}">
              <labels><label description="Section Title" languagecode="1033" /></labels>
              <rows>
                <row>
                  <cell id="{CELL-GUID}">
                    <labels><label description="Field Label" languagecode="1033" /></labels>
                    <control id="context_fieldname" classid="{CLASSID}" datafieldname="context_fieldname" disabled="false" />
                  </cell>
                  <cell id="{CELL-GUID}" showlabel="false" /> <!-- empty cell for 2-col layout -->
                </row>
              </rows>
            </section>
          </sections>
        </column>
      </columns>
    </tab>
  </tabs>
</form>
```

---

## Updating Views

### Find the default active view

```powershell
GET /savedqueries?$filter=returnedtypecode eq 'context_mytable' and querytype eq 0&$select=savedqueryid,name,fetchxml,layoutxml&$orderby=name
```

Query type 0 = system view. Filter by name containing "Active" for the default one.

### PATCH with new fetchxml + layoutxml

```powershell
$patchHeaders = $headers.Clone()
$patchHeaders["If-Match"] = "*"
$body = @{ fetchxml = $fetchXml; layoutxml = $layoutXml } | ConvertTo-Json
Invoke-RestMethod -Method PATCH -Uri "$baseUrl/savedqueries($viewId)" -Headers $patchHeaders -Body $body
```

Views do not require PublishXml after PATCH.

### FetchXml + LayoutXml patterns

```xml
<!-- FetchXml -->
<fetch version="1.0" output-format="xml-platform" mapping="logical" distinct="false">
  <entity name="context_mytable">
    <attribute name="context_name" />
    <attribute name="context_status" />
    <attribute name="context_mytableid" />
    <order attribute="context_name" descending="false" />
    <filter type="and">
      <condition attribute="statecode" operator="eq" value="0" />
    </filter>
  </entity>
</fetch>

<!-- LayoutXml — object attribute is REQUIRED (entity type code from ObjectTypeCode field) -->
<grid name="resultset" object="10944" jump="context_name" select="1" preview="1" icon="1">
  <row name="result" id="context_mytableid">
    <cell name="context_name"   width="300" />
    <cell name="context_status" width="120" />
  </row>
</grid>
```

Get the ObjectTypeCode for a table:
```powershell
$meta = Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions?`$filter=LogicalName eq 'context_mytable'&`$select=ObjectTypeCode" -Headers $headers
$typeCode = $meta.value[0].ObjectTypeCode
```

---

## Publishing

```powershell
# Publish entity customizations (forms)
$body = @{ ParameterXml = "<importexportxml><entities><entity>context_mytable</entity></entities></importexportxml>" } | ConvertTo-Json
Invoke-RestMethod -Method POST -Uri "$baseUrl/PublishXml" -Headers $headers -Body $body

# Publish app module
$body = @{ ParameterXml = "<importexportxml><appmodules><appmodule>$appId</appmodule></appmodules></importexportxml>" } | ConvertTo-Json
Invoke-RestMethod -Method POST -Uri "$baseUrl/PublishXml" -Headers $headers -Body $body
```

---

## Known Gotchas

1. **Silent app creation failure**: If `clienttype` or `formfactor` are missing, the API returns HTTP 204 + `OData-EntityId` but the record is NOT saved. The uniquename gets reserved, blocking future attempts with `0x80050135`.

2. **Uniquename auto-prefix**: The publisher prefix from the solution is prepended automatically. Always include the prefix when querying by uniquename.

3. **webresourceid required**: Cannot be null. Use `953b9fac-1e5e-e611-80d6-00155ded156f` (default system icon). Query via `/webresourceset` not `/webresources`.

4. **appmodulecomponent filter**: Filter by `_appmoduleidunique_value eq <appmoduleidunique-guid>` (use the app's `appmoduleidunique` field, not `appmoduleid`).

5. **AddAppComponents — entity components (componenttype=1) cannot be added via REST API**: The `AddAppComponents` action accepts `Collection(crmbaseentity)`. Passing `ComponentType`/`ObjectId` properties fails ("property does not exist"), `EntityMetadata` type fails ("not assignable to crmbaseentity"), and the `entity` type with `entityid` returns HTTP 204 but silently does nothing. The only way to add entity components (componenttype=1) to an app module is via the App Designer UI. For SiteMap components (componenttype=62), use `@odata.type: "Microsoft.Dynamics.CRM.sitemap"` + `sitemapid`.

6. **LayoutXml `object` attribute is required**: Every `<grid>` element must include `object="<ObjectTypeCode>"` where ObjectTypeCode is the entity's integer type code. Missing it causes "Invalid layout xml found — The required attribute 'object' is missing." Get the code via `EntityDefinitions?$filter=LogicalName eq '...'&$select=ObjectTypeCode`.

7. **Form type**: `type eq 2` = Main form. Other types: 6 = Quick Create, 7 = Quick View, 4 = Mobile.
