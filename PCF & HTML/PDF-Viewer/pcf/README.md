# PdfViewer PCF — SharePoint document/library viewer (Microsoft Graph)

A PowerApps Component Framework (PCF) field control for model-driven apps. It is bound to a
text/URL column holding a **SharePoint document, folder, or document library URL** and renders a
card with:

- **Inline preview** of a single document inside the form (via MSAL + Microsoft Graph), enforcing
  the **signed-in user's own SharePoint permissions**;
- **Folder/library browsing** — when the bound URL points at a folder or library, a SharePoint-like
  breadcrumb + file list is rendered by the control itself (never a raw SharePoint page in an
  iframe — see "Security model"), with a split view (file list left, preview right) that collapses
  to a drill-in view on narrow form sections; and
- **Open in window / New tab / Download** actions that open the document in SharePoint (also
  permission-enforced) — and serve as the fallback when inline preview isn't configured.

- Control: `context_ContextAnd.PdfViewer` (namespace `ContextAnd`, constructor `PdfViewer`)
- Solution: `ContextAndPdfViewer` (publisher `ContextAnd`, prefix `context`)
- Version: `1.5.0`

> The legacy standalone `../pdf-viewer.html` is a separate artifact and is **not** part of this
> project. Leave it untouched.

## Security model (read this first)

The goal is that **only users who actually have SharePoint access to a document can see it**, even
inline in the form. The original bug was an embedded *sharing link* that let an unauthorized
colleague view a document. Two facts shaped the design:

1. **A plain iframe of a SharePoint URL can't both render and enforce per-user permissions.** A
   sharing link embeds but bypasses the viewer's ACL (the leak); a canonical URL is blocked by
   `X-Frame-Options: SAMEORIGIN` cross-domain — this applies to folder/library pages too, which is
   why folder browsing is a **custom UI rendered by the control**, not an embedded SharePoint page.
2. **The only way to inline-render a SharePoint file (or list its folder contents) with per-user
   enforcement is Microsoft Graph** with a *delegated* token (there is no first-party Graph token
   in the PCF `context`).

So inline preview uses **MSAL.js** to get a delegated Graph token for the signed-in user, then
resolves the bound URL and branches on whether it's a file or a folder:

```
encode URL -> GET /shares/{u!encoded}/driveItem?$select=...,folder   (403/404 if the user lacks access)

  file   -> POST /drives/{driveId}/items/{itemId}/preview   -> { getUrl }
         -> iframe.src = getUrl + "&nb=true"        (document-only, no breadcrumb)

  folder -> GET /drives/{driveId}/items/{itemId}/children   -> file/folder list (paged)
         -> user clicks a file -> POST .../preview -> iframe.src, same as above
```

Graph evaluates the **signed-in user's** permissions at every call: an unauthorized user gets
403/404 and the control shows "you don't have access" — nothing renders. The `/preview` `getUrl` is
caller-scoped and short-lived, so it's re-fetched on every file open and never cached. Folder
**listings** (`/children`) *are* cached per folder for the lifetime of the browser session (so
breadcrumb back-navigation is instant with no extra Graph call) — reopen the control to see files
added to SharePoint mid-session.

**Fallback / no-config behaviour:** if inline preview isn't configured (no `clientId`) or fails,
the control falls back to **Open in window / New tab / Download** (top-level navigation, where
SharePoint forces sign-in and enforces the ACL). The control is fully usable with zero auth setup.

### Sharing-link classification (defense-in-depth only)

`_classifySharePointUrl` tags the bound URL `canonical` / `unsafe` / `unknown` and shows a soft
warning + blocks Download for sharing links (this applies to folder sharing links too, e.g.
`/:f:/...?e=...`). With Graph this is no longer the security boundary (Graph enforces the user's
*effective* access) — folder browsing still works for a sharing link, it just shows the warning.
Note an org-wide sharing link legitimately grants access to org users — that's correct, not a leak.
Prefer **canonical/direct file or folder URLs**.

## Folder / library browsing

When the bound URL resolves to a folder (or a document library root), Preview renders a file
browser instead of a single-document iframe:

- **Breadcrumb** across the top; clicking an earlier crumb truncates back to that folder (served
  from the in-memory cache, no Graph call).
- **Split view**: file list on the left (folders first, then files, alphabetical within each
  group), preview pane on the right. Below `previewHeight`-driven width thresholds (~640px
  allocated width) it collapses to a **drill-in** view — full-width list, then full-width preview
  with a "Back to files" button — so it stays usable in a narrow form section.
- **Paging**: folders load `browserPageSize` items at a time (default 100); a "Load more" row
  appends the next page.
- Clicking a file shows a preview in the right/full pane the same way single-document mode does;
  file types Graph can't preview show an "Open in SharePoint" fallback using the item's own
  `webUrl` (still permission-enforced).
- All file types are listed (like SharePoint itself); only preview support is limited by what
  Graph's `/preview` action can render (PDFs and Office documents are well supported).

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `boundValue` | `SingleLine.URL` / `.Text` (bound) | — | The SharePoint document, folder, or library URL. |
| `showInlinePreview` | TwoOptions | `1` | Show the Preview button. Gated by `clientId`: blank ⇒ Preview hidden, control still opens/downloads. |
| `clientId` | SingleLine.Text | — | Entra app (client) ID for inline preview. Blank disables inline preview. |
| `tenantId` | SingleLine.Text | — | Blank ⇒ authority `organizations` (multi-tenant). A tenant GUID/domain ⇒ single-tenant. A full `https://…` value is used verbatim as the authority. |
| `redirectUri` | SingleLine.Text | — | Blank ⇒ `window.location.origin`. Must be a registered SPA redirect URI. |
| `autoExpand` | TwoOptions | `0` | Opens the preview/browser automatically without clicking Preview. Silent if the user already has an active M365 session in the browser; otherwise the browser blocks the automatic sign-in pop-up and the user must click Preview once. Requires `clientId`. |
| `previewHeight` | Whole.None | `600` | Height in px of the inline preview or the folder browser (clamped 200–2000). |
| `browserPageSize` | Whole.None | `100` | Files/folders loaded per page when browsing a library (clamped 25–200). |
| `blockSharePointSharingLinks` | TwoOptions | `1` | Block Download for detected sharing links (bound URL only). |
| `showOpenInWindow` / `showNewTab` / `showDownload` | TwoOptions | `1` | Action-button visibility. |

## Build

```bash
npm install
npm run build                              # debug build
npx pcf-scripts build --buildMode production   # minified (recommended for deploy; ~300 KB with MSAL)
```

Node 18+, npm. Toolchain is `pcf-scripts` (no `@microsoft/` scope). `@azure/msal-browser` (^3.x) is
a runtime dependency and bundles into `bundle.js`. Keep all string literals in `PdfViewer/*.ts`
**ASCII** — smart quotes break the build.

### Source layout

`index.ts` is the only file listed in the manifest's `<resources>`; `pcf-scripts` bundles the rest
via imports:

| File | Contents |
|---|---|
| `index.ts` | Control lifecycle, card UI, single-document preview, mode branch (file vs. folder) |
| `auth.ts` | Page-shared MSAL `PublicClientApplication` registry |
| `graph.ts` | Graph fetch helpers: resolve URL, list folder children, get preview URL, 429/503 retry |
| `browser.ts` | `FileBrowser` — breadcrumb, file list, paging, cache, preview pane, narrow collapse |
| `styles.ts` | Injected CSS (single `<style>` tag; versioned id so old/new control instances on the same page don't collide) |

## Package & deploy (no `pac` CLI)

> Deploy via the Dataverse Web API `ImportSolutionAsync` using a service-principal
> (client-credentials) token. Credentials come from a gitignored `.env`
> (`DATAVERSE_URL`, `TENANT_ID`, `CLIENT_ID`, `CLIENT_SECRET`, `DATAVERSE_SCOPE`).

The solution zip must contain exactly:

```
[Content_Types].xml
solution.xml                 (lowercase; Version, publisher ContextAnd, prefix context,
                              CustomizationOptionValuePrefix 23615, RootComponent type=66)
customizations.xml           (lowercase; <CustomControl><Name>…</Name><FileName>…</FileName>)
Controls/context_ContextAnd.PdfViewer/ControlManifest.xml   (compiled, no XML declaration)
Controls/context_ContextAnd.PdfViewer/bundle.js
```

Do **not** add `css/` or `resx` files into `Controls/` — they register as type-50 web resources and
fail the import. CSS is inlined in `index.ts` (`_injectStyles`) to keep the package to `bundle.js` +
`ControlManifest.xml`.

Both `solution.xml` and `customizations.xml`'s `<ImportExportXml>` root element need a
`SolutionPackageVersion="<org version>"` attribute set to the **target org's** Dataverse version
(fetch via `GET …/api/data/v9.2/RetrieveVersion`). Without it, import fails with *"The solution
package you are importing was generated on a version of Microsoft Dynamics 365 that cannot be
imported into this system... Package Version: On-Premises"* — the importer defaults to assuming an
incompatible on-premises package when this attribute is missing.

Deploy = POST the base64 zip to `…/api/data/v9.2/ImportSolutionAsync` with
`OverwriteUnmanagedCustomizations=true`, poll `asyncoperations(<id>)` until `statecode=3 /
statuscode=30`.

> **Critical — call `PublishAllXml` after import** (`POST …/api/data/v9.2/PublishAllXml`, body `{}`),
> then verify with
> `GET customcontrols?$select=version,modifiedon&$filter=name eq 'context_ContextAnd.PdfViewer'`
> — `modifiedon` should move and `version` should match the manifest. **Increment the control
> `version`** in `ControlManifest.Input.xml` on every change. (A polling loop that `continue`s on a
> transient error must still advance its timeout, or it hangs forever — fix noted from experience.)

### Property labels without a resx

No `.resx` is shipped. PCF renders `display-name-key`/`description-key` **verbatim** when no resx
resolves them, so the manifest puts friendly text directly in those attributes (e.g.
`display-name-key="SharePoint document URL"`). That is why the config pane shows readable labels.

## App registration (required for inline preview)

Inline preview needs an Entra (Azure AD) app registration. Until it exists and `clientId` is set on
the form, the Preview button stays hidden and the control behaves as open/download only — no errors.

**Single-tenant (one org / demo):**
1. Entra admin center → **App registrations → New registration**. Single tenant.
2. **Add a platform → Single-page application (SPA)**. Redirect URI = the app origin, e.g.
   `https://<org>.crm.dynamics.com` (exact `window.location.origin`; add regional hosts if used).
3. **API permissions → Microsoft Graph → Delegated**: add `Files.Read.All` and `User.Read`.
4. **Grant admin consent** (Files.Read.All is admin-consent-tier).
5. **Authentication → Allow public client flows = Yes** (defensive).
6. Copy the **Application (client) ID** → set as the control's `clientId`; set `tenantId` to the
   Directory (tenant) ID.

**Multi-tenant (vendor distribution):** register as multitenant, leave `tenantId` blank (authority
`organizations`); each customer admin grants consent via
`https://login.microsoftonline.com/{tenant}/adminconsent?client_id={clientId}`.
**Caveat:** SPA redirect URIs are exact-match (no wildcards), so each customer org origin must be
registered on the app — the one weak point of the "single shared app" story.

## Configure on a form

1. Add the control to the text/URL column that stores the SharePoint URL; bind `boundValue`.
2. Set **Show inline preview = On**, paste **Client ID**, set **Tenant** (GUID for single-tenant;
   blank for multi-tenant), optionally Redirect URI / Preview height / Folder browser page size.
3. Save & publish the form. Store a **canonical/direct file, folder, or library URL** in the column.

## Verify

- **Authorized user, single document:** click **Preview** → popup sign-in (first time) → document
  renders inline, document-only (no breadcrumb). Second click/reload → silent token (no popup).
  Open/New-tab/Download also work.
- **Authorized user, folder/library:** click **Preview** → split view opens with breadcrumb + file
  list (folders first); clicking a folder drills in, clicking a crumb goes back instantly (cached,
  no new Graph call); clicking a file previews it in the right pane. Shrink the form section/window
  → collapses to drill-in (list, then full-width preview with **Back to files**).
- **Unauthorized colleague** (signed into M365 in **their own/incognito** session): Preview → signs
  in as themselves → graceful **"You don't have access"** (Graph 403/404) for both a document and a
  folder; nothing renders. ← core security proof. (Dataverse-level impersonation does not change the
  SharePoint identity — test with a real second sign-in.)
- **Not configured:** blank `clientId` → Preview hidden, control fully usable.

## Limitations

- MSAL adds ~300 KB (minified) to the bundle; first sign-in is a popup, silent thereafter.
- Auth flow uses **popup** (silent → popup); redirect flows are blocked inside the model-driven app
  iframe. Third-party-cookie blocking can fail silent acquisition — the popup fallback covers it.
- SPA redirect URIs are per-origin/exact-match (multi-tenant caveat above).
- Some file types/large files aren't previewable via Graph `/preview` → fallback to open/download
  (PDFs are well supported); the folder browser shows an "Open in SharePoint" fallback per file.
- Folder listings are cached for the life of the browsing session (fast back-navigation); files
  added in SharePoint mid-session won't appear until the control is reopened.
- Graph throttling (429/503) is retried once honoring `Retry-After`; repeated throttling surfaces
  as "SharePoint is busy - try again shortly."
- Relies on the org's default CSP allowing `login.microsoftonline.com`, `graph.microsoft.com`, and
  the SharePoint/OneDrive embed origin in an iframe — an environment prerequisite, not a control bug.
