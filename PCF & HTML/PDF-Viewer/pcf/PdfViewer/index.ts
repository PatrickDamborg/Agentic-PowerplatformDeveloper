import { IInputs, IOutputs } from "./generated/ManifestTypes";
import { PublicClientApplication } from "@azure/msal-browser";

type UrlKind = "unsafe" | "canonical" | "unknown";

// Reason codes used to drive graceful-degradation messages.
type FallbackReason =
    | "not-configured"
    | "popup-blocked"
    | "cancelled"
    | "consent-required"
    | "no-access"
    | "unsupported"
    | "graph-error"
    | "auth-error";

// Thrown by the Graph helpers / token acquisition; carries a FallbackReason.
class PreviewError extends Error {
    public reason: FallbackReason;
    constructor(reason: FallbackReason) {
        super(reason);
        this.reason = reason;
    }
}

// ---- Page-shared MSAL registry -------------------------------------------------
// One PublicClientApplication per (clientId|authority|redirectUri), shared across
// all control instances on the page so the token cache and active account are shared.
interface MsalEntry { app: PublicClientApplication; ready: Promise<void>; }
const _msalRegistry: Map<string, MsalEntry> = new Map();

function _getMsal(clientId: string, authority: string, redirectUri: string): MsalEntry {
    const key = clientId + "|" + authority + "|" + redirectUri;
    let entry = _msalRegistry.get(key);
    if (!entry) {
        const config = {
            auth: { clientId: clientId, authority: authority, redirectUri: redirectUri },
            cache: { cacheLocation: "localStorage", storeAuthStateInCookie: false }
        };
        const app = new PublicClientApplication(config as never);
        entry = { app: app, ready: app.initialize() };
        _msalRegistry.set(key, entry);
    }
    return entry;
}

// ---- Microsoft Graph helpers (pure fetch) --------------------------------------

function _encodeShareUrl(url: string): string {
    // u! + unpadded base64url of the full URL (UTF-8 safe).
    const b64 = btoa(unescape(encodeURIComponent(url)));
    return "u!" + b64.replace(/=+$/, "").replace(/\//g, "_").replace(/\+/g, "-");
}

async function _graphResolveDriveItem(
    token: string,
    url: string
): Promise<{ driveId: string; itemId: string; name: string }> {
    const enc = _encodeShareUrl(url);
    const api = "https://graph.microsoft.com/v1.0/shares/" + enc +
        "/driveItem?$select=id,name,parentReference,file,size,webUrl";
    const r = await fetch(api, { headers: { Authorization: "Bearer " + token } });
    if (r.status === 403 || r.status === 404) throw new PreviewError("no-access");
    if (!r.ok) throw new PreviewError("graph-error");
    const j = await r.json();
    const driveId = j && j.parentReference ? j.parentReference.driveId : null;
    if (!driveId || !j.id) throw new PreviewError("graph-error");
    return { driveId: driveId, itemId: j.id, name: j.name || "" };
}

async function _graphGetPreviewUrl(token: string, driveId: string, itemId: string): Promise<string> {
    const api = "https://graph.microsoft.com/v1.0/drives/" + driveId + "/items/" + itemId + "/preview";
    const r = await fetch(api, {
        method: "POST",
        headers: { Authorization: "Bearer " + token, "Content-Type": "application/json" },
        body: "{}"
    });
    if (r.status === 403 || r.status === 404) throw new PreviewError("no-access");
    if (!r.ok) throw new PreviewError("unsupported");
    const j = await r.json();
    if (!j || !j.getUrl) throw new PreviewError("unsupported");
    return j.getUrl as string;
}

export class PdfViewer implements ComponentFramework.StandardControl<IInputs, IOutputs> {

    // Framework references
    private _context!: ComponentFramework.Context<IInputs>;
    private _container!: HTMLDivElement;

    // DOM elements (class-named to allow multiple instances on one form)
    private _filenameEl!: HTMLDivElement;
    private _subtextEl!: HTMLDivElement;
    private _statusEl!: HTMLDivElement;
    private _btnPreview!: HTMLButtonElement;
    private _btnOpenWindow!: HTMLButtonElement;
    private _btnNewTab!: HTMLButtonElement;
    private _btnDownload!: HTMLButtonElement;
    private _previewWrap!: HTMLDivElement;
    private _iframe: HTMLIFrameElement | null = null;

    // State
    private _url = "";
    private _lastUrl = "";
    private _kind: UrlKind = "unknown";
    private _downloadName = "document.pdf";
    private _previewActive = false;

    // Inline-preview config / MSAL
    private _inlineEnabled = false;
    private _previewHeight = 600;
    private _msal: PublicClientApplication | null = null;
    private _msalReady: Promise<void> | null = null;
    private _msalKey = "";
    private _account: import("@azure/msal-browser").AccountInfo | null = null;

    // Regexes for URL classification (declared once, reused) ----------------------
    private static readonly SP_HOST   = /(^|\.)sharepoint\.(com|de|us|cn)$/i;
    // Tenant sharing short-codes: /:f:/ /:b:/ /:w:/ /:x:/ /:p:/ /:u:/ /:o:/ /:v:/ /:t:/
    private static readonly SP_SHORT  = /\/:[a-z]:\//i;
    // Guest-access / embed / WopiFrame / GetSharingLink layout pages
    private static readonly SP_GUEST  = /(guestaccess\.aspx|\/_layouts\/15\/(embed|wopiframe|getsharinglink)\.aspx)/i;
    // Sharing tokens / artifacts in the query string
    private static readonly SP_TOKENS = /[?&](e|share|csf|web|at|guestaccess|guestaccesstoken)=/i;

    // ---- Lifecycle ----------------------------------------------------------

    public init(
        context: ComponentFramework.Context<IInputs>,
        _notifyOutputChanged: () => void,
        _state: ComponentFramework.Dictionary,
        container: HTMLDivElement
    ): void {
        this._context = context;
        this._container = container;
        context.mode.trackContainerResize(true);
        this._buildDOM();
    }

    public updateView(context: ComponentFramework.Context<IInputs>): void {
        this._context = context;
        const p = context.parameters;

        // Button visibility (action buttons)
        this._btnOpenWindow.style.display = p.showOpenInWindow.raw === false ? "none" : "";
        this._btnNewTab.style.display     = p.showNewTab.raw === false      ? "none" : "";
        this._btnDownload.style.display   = p.showDownload.raw === false    ? "none" : "";

        // Read and classify the bound SharePoint URL (cheap; classify every pass)
        this._url  = ((p.boundValue.raw as string) || "").trim();
        this._kind = this._classifySharePointUrl(this._url);

        // Tear down a stale preview if the document changed.
        if (this._url !== this._lastUrl) {
            this._teardownPreview();
            this._lastUrl = this._url;
        }

        // Inline-preview config
        const clientId = ((p.clientId.raw as string) || "").trim();
        this._inlineEnabled = p.showInlinePreview.raw !== false && clientId !== "";
        this._previewHeight = this._clampHeight(p.previewHeight.raw);

        if (this._inlineEnabled) {
            const authority   = this._buildAuthority(((p.tenantId.raw as string) || "").trim());
            const redirectUri = ((p.redirectUri.raw as string) || "").trim() || window.location.origin;
            const key = clientId + "|" + authority + "|" + redirectUri;
            if (!this._msal || this._msalKey !== key) {
                const entry = _getMsal(clientId, authority, redirectUri);
                this._msal = entry.app;
                this._msalReady = entry.ready;
                this._msalKey = key;
                // Update the button label once MSAL is initialized (non-interactive).
                this._msalReady
                    .then(() => { if (!this._previewActive) this._btnPreview.textContent = this._previewBtnLabel(); })
                    .catch(() => { /* leave default label */ });
            }
        } else {
            this._msal = null;
            this._msalReady = null;
            this._msalKey = "";
            this._teardownPreview();
        }

        // Preview button shows only when inline is enabled and a URL is present.
        this._btnPreview.style.display = (this._inlineEnabled && this._url) ? "" : "none";

        // Card text / state
        if (!this._url) {
            this._filenameEl.textContent = "No URL configured";
            this._subtextEl.textContent  = "Paste a SharePoint document URL into the column.";
            this._disableActions(true);
            this._setStatus("", false);
            return;
        }

        this._disableActions(false);
        this._filenameEl.textContent = this._deriveFilename(this._url, this._kind);
        this._downloadName = this._filenameEl.textContent || "document.pdf";

        if (this._kind === "unsafe") {
            this._subtextEl.textContent = "Sharing link - prefer the direct file URL";
            this._setStatus(
                "Sharing link detected - for reliable per-user permissions, bind the direct file URL (.../sites/.../Shared Documents/file.pdf).",
                false
            );
        } else {
            this._subtextEl.textContent = this._inlineEnabled
                ? "Preview or open - your SharePoint permissions apply"
                : "Opens in SharePoint - your permissions apply";
            this._setStatus("", false);
        }
    }

    public getOutputs(): IOutputs {
        return {};
    }

    public destroy(): void {
        this._teardownPreview();
        // Removing the subtree detaches the click listeners. MSAL is page-shared; leave it.
        if (this._container) this._container.replaceChildren();
    }

    // ---- DOM construction ---------------------------------------------------

    private _buildDOM(): void {
        this._injectStyles();
        const root = this._el("div", "pv-root");

        // Card
        const card    = this._el("div", "pv-card");
        const icon    = this._el("div", "pv-icon");
        icon.textContent = "PDF";

        const meta    = this._el("div", "pv-meta");
        this._filenameEl = this._el("div", "pv-filename") as HTMLDivElement;
        this._filenameEl.textContent = "SharePoint document";
        this._subtextEl  = this._el("div", "pv-subtext") as HTMLDivElement;
        this._subtextEl.textContent  = "Opens in SharePoint - your permissions apply";
        meta.append(this._filenameEl, this._subtextEl);

        const actions = this._el("div", "pv-actions");
        this._btnPreview    = this._makeBtn("Preview",        true);
        this._btnOpenWindow = this._makeBtn("Open in window", false);
        this._btnNewTab     = this._makeBtn("New tab",        false);
        this._btnDownload   = this._makeBtn("Download",       false);
        this._btnPreview.style.display = "none"; // shown when inline enabled
        actions.append(this._btnPreview, this._btnOpenWindow, this._btnNewTab, this._btnDownload);

        card.append(icon, meta, actions);

        // Status line
        const statusWrap = this._el("div", "pv-status");
        const statusText = this._el("span", "pv-status-text");
        statusWrap.append(statusText);
        this._statusEl = statusWrap as HTMLDivElement;

        // Inline preview container (hidden until active)
        this._previewWrap = this._el("div", "pv-preview-wrap") as HTMLDivElement;

        root.append(card, this._statusEl, this._previewWrap);
        this._container.appendChild(root);

        // Event handlers
        this._btnPreview.addEventListener("click",    () => { void this._onPreviewClick(); });
        this._btnOpenWindow.addEventListener("click", () => this._onOpenWindow());
        this._btnNewTab.addEventListener("click",     () => this._onNewTab());
        this._btnDownload.addEventListener("click",   () => this._onDownload());
    }

    private _injectStyles(): void {
        const STYLE_ID = "pv-styles-context";
        if (document.getElementById(STYLE_ID)) return;
        const s = document.createElement("style");
        s.id = STYLE_ID;
        s.textContent = [
            ".pv-root{font-family:\"Segoe UI\",Tahoma,sans-serif;font-size:14px;color:#323130;display:flex;flex-direction:column;gap:8px;width:100%;box-sizing:border-box}",
            ".pv-card{display:flex;flex-direction:row;align-items:center;gap:12px;background:#fff;border:1px solid #e1dfdd;border-radius:4px;padding:10px 14px;flex-shrink:0;flex-wrap:wrap}",
            ".pv-icon{background:#a4262c;color:#fff;font-size:11px;font-weight:700;letter-spacing:.5px;width:36px;height:44px;border-radius:3px;display:flex;align-items:center;justify-content:center;flex-shrink:0}",
            ".pv-meta{flex:1;min-width:0}",
            ".pv-filename{font-weight:600;font-size:14px;color:#323130;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}",
            ".pv-subtext{font-size:12px;color:#605e5c;margin-top:2px}",
            ".pv-actions{display:flex;flex-direction:row;gap:8px;flex-shrink:0;flex-wrap:wrap}",
            ".pv-btn{background:#fff;color:#323130;border:1px solid #8a8886;padding:5px 13px;border-radius:3px;font-size:13px;font-family:inherit;cursor:pointer;white-space:nowrap;line-height:1.4}",
            ".pv-btn:hover:not(:disabled){background:#f3f2f1}",
            ".pv-btn:disabled{color:#a19f9d;cursor:not-allowed}",
            ".pv-btn-primary{background:#0078d4;color:#fff;border:none;font-weight:600}",
            ".pv-btn-primary:hover:not(:disabled){background:#106ebe}",
            ".pv-btn-primary:disabled{background:#c7e0f4;color:#fff;cursor:not-allowed}",
            ".pv-status{font-size:13px;color:#605e5c;min-height:18px;padding:0 2px;display:flex;align-items:center;gap:6px}",
            ".pv-status.is-error{color:#a4262c}",
            ".pv-preview-wrap{display:none;border:1px solid #e1dfdd;border-radius:4px;overflow:hidden;background:#f5f5f5}",
            ".pv-iframe{width:100%;border:0;display:block;height:600px}"
        ].join("\n");
        document.head.appendChild(s);
    }

    private _el(tag: string, cls: string): HTMLElement {
        const el = document.createElement(tag);
        el.className = cls;
        return el;
    }

    private _makeBtn(label: string, primary: boolean): HTMLButtonElement {
        const btn = document.createElement("button");
        btn.textContent = label;
        btn.className = primary ? "pv-btn pv-btn-primary" : "pv-btn";
        return btn;
    }

    // ---- Helpers ------------------------------------------------------------

    private _disableActions(disabled: boolean): void {
        for (const btn of [this._btnPreview, this._btnOpenWindow, this._btnNewTab, this._btnDownload]) {
            btn.disabled = disabled;
        }
    }

    private _setStatus(text: string, isError = false): void {
        const textNode = this._statusEl.querySelector(".pv-status-text");
        if (textNode) textNode.textContent = text;
        this._statusEl.classList.toggle("is-error", isError);
    }

    private _clampHeight(raw: number | null): number {
        const n = (typeof raw === "number" && isFinite(raw)) ? Math.round(raw) : 600;
        return Math.max(200, Math.min(2000, n || 600));
    }

    private _buildAuthority(tenant: string): string {
        if (/^https:\/\//i.test(tenant)) return tenant;
        return "https://login.microsoftonline.com/" + (tenant || "organizations");
    }

    private _previewBtnLabel(): string {
        try {
            if (this._msal && this._msal.getAllAccounts().length > 0) return "Preview";
        } catch (_) { /* before init */ }
        return "Sign in & preview";
    }

    /**
     * Classify a SharePoint URL (defense-in-depth for messaging only; with Graph the
     * security boundary is the per-user delegated token, not this classifier).
     */
    private _classifySharePointUrl(raw: string): UrlKind {
        if (!raw) return "unknown";
        let u: URL;
        try {
            u = new URL(raw);
        } catch (_) {
            return "unknown";
        }

        if (!PdfViewer.SP_HOST.test(u.hostname)) return "unknown";

        const path   = u.pathname.toLowerCase();
        const search = u.search.toLowerCase();

        if (PdfViewer.SP_SHORT.test(path))  return "unsafe";
        if (PdfViewer.SP_GUEST.test(path))  return "unsafe";
        if (path.indexOf("/download.aspx") !== -1 && search.indexOf("sourceurl=") !== -1) return "unsafe";
        if (PdfViewer.SP_TOKENS.test(search)) return "unsafe";

        if (/\/sites\//.test(path) || /\/teams\//.test(path) || /\/personal\//.test(path)) return "canonical";
        if (path.indexOf("/doc.aspx") !== -1 && search.indexOf("sourcedoc=") !== -1)        return "canonical";

        return "unknown";
    }

    /** Best-effort display name from the URL's last path segment. */
    private _deriveFilename(raw: string, kind: UrlKind): string {
        if (kind === "unsafe") return "SharePoint document";
        try {
            const u = new URL(raw);
            const segs = u.pathname.split("/").filter(Boolean);
            const last = segs.length ? decodeURIComponent(segs[segs.length - 1]) : "";
            if (last && /\.[a-z0-9]{2,5}$/i.test(last)) return last;
        } catch (_) { /* fall through */ }
        return "SharePoint document";
    }

    // ---- Inline preview (MSAL + Graph) --------------------------------------

    private async _onPreviewClick(): Promise<void> {
        if (this._previewActive) { this._teardownPreview(); return; }
        if (!this._url) { this._setStatus("No URL is configured.", true); return; }
        if (!this._inlineEnabled || !this._msal) { this._fallbackToOpen("not-configured"); return; }

        this._btnPreview.disabled = true;
        this._setStatus("Preparing preview...", false);
        try {
            if (this._msalReady) await this._msalReady;
            const token  = await this._acquireGraphToken();
            const di     = await _graphResolveDriveItem(token, this._url);
            if (di.name) { this._filenameEl.textContent = di.name; this._downloadName = di.name; }
            const getUrl = await _graphGetPreviewUrl(token, di.driveId, di.itemId);
            this._renderPreview(getUrl);
            this._setStatus("", false);
        } catch (e) {
            const reason: FallbackReason = (e instanceof PreviewError) ? e.reason : "graph-error";
            this._fallbackToOpen(reason);
        } finally {
            this._btnPreview.disabled = false;
        }
    }

    private async _acquireGraphToken(): Promise<string> {
        const msal = this._msal as PublicClientApplication;
        const scopes = ["Files.Read.All", "User.Read"];
        const accounts = msal.getAllAccounts();
        const active = msal.getActiveAccount() || this._account || (accounts.length ? accounts[0] : null);

        if (active) {
            try {
                const r = await msal.acquireTokenSilent({ scopes: scopes, account: active });
                this._rememberAccount(r);
                return r.accessToken;
            } catch (_) {
                // In a user gesture: fall through to interactive popup.
            }
        }

        try {
            const req: Record<string, unknown> = { scopes: scopes };
            if (active) req.loginHint = active.username;
            else if (accounts.length > 1) req.prompt = "select_account";
            const r = await msal.acquireTokenPopup(req as never);
            this._rememberAccount(r);
            return r.accessToken;
        } catch (e) {
            const err = e as { errorCode?: string; message?: string };
            const code = err.errorCode || "";
            const msg  = err.message || "";
            if (code === "popup_window_error" || code === "empty_window_error" || /popup/i.test(msg)) {
                throw new PreviewError("popup-blocked");
            }
            if (code === "user_cancelled") throw new PreviewError("cancelled");
            if (code === "consent_required" || /AADSTS65001/.test(msg)) throw new PreviewError("consent-required");
            throw new PreviewError("auth-error");
        }
    }

    private _rememberAccount(r: import("@azure/msal-browser").AuthenticationResult): void {
        if (r && r.account) {
            this._account = r.account;
            if (this._msal) this._msal.setActiveAccount(r.account);
        }
    }

    private _renderPreview(getUrl: string): void {
        const sep = getUrl.indexOf("?") === -1 ? "?" : "&";
        const src = getUrl + sep + "nb=true";
        if (!this._iframe) {
            this._iframe = document.createElement("iframe");
            this._iframe.className = "pv-iframe";
            this._iframe.setAttribute("title", "Document preview");
            this._iframe.setAttribute("referrerpolicy", "no-referrer");
            this._previewWrap.appendChild(this._iframe);
        }
        this._iframe.style.height = this._previewHeight + "px";
        this._iframe.src = src;
        this._previewWrap.style.display = "";
        this._previewActive = true;
        this._btnPreview.textContent = "Hide preview";
    }

    private _teardownPreview(): void {
        if (this._iframe) {
            this._iframe.src = "about:blank";
            this._iframe.remove();
            this._iframe = null;
        }
        if (this._previewWrap) this._previewWrap.style.display = "none";
        this._previewActive = false;
        if (this._btnPreview) this._btnPreview.textContent = this._previewBtnLabel();
    }

    private _fallbackToOpen(reason: FallbackReason): void {
        this._teardownPreview();
        let msg: string;
        switch (reason) {
            case "not-configured":
                msg = "Inline preview isn't set up yet. Use Open in window or New tab to view the document in SharePoint.";
                break;
            case "popup-blocked":
                msg = "Sign-in popup was blocked. Allow popups for this site and click Preview again, or use Open in window.";
                break;
            case "cancelled":
                msg = "Sign-in was cancelled. Click Preview to try again, or use Open in window.";
                break;
            case "consent-required":
                msg = "Your administrator hasn't granted permission for inline preview yet. Use Open in window for now.";
                break;
            case "no-access":
                msg = "You don't have access to this document, or it has moved. Use Open in window to confirm in SharePoint.";
                break;
            case "unsupported":
                msg = "This file can't be previewed inline. Use Open in window or Download.";
                break;
            default:
                msg = "Couldn't load the preview right now. Use Open in window or Download.";
        }
        this._setStatus(msg, reason === "no-access");
    }

    // ---- Action handlers (top-level navigation = permission-respecting path) -

    private _onOpenWindow(): void {
        if (!this._url) { this._setStatus("No URL is configured.", true); return; }
        if (this._kind === "unsafe") {
            this._setStatus("Warning: this is a sharing link. Bind the direct file URL so SharePoint enforces permissions.", true);
        }
        const win = window.open("", "_blank", "width=900,height=1000,scrollbars=yes,resizable=yes");
        if (!win) { this._setStatus("Pop-up blocked. Allow pop-ups for this site, or use New tab.", true); return; }
        win.location.href = this._url;
    }

    private _onNewTab(): void {
        if (!this._url) { this._setStatus("No URL is configured.", true); return; }
        if (this._kind === "unsafe") {
            this._setStatus("Warning: this is a sharing link. Bind the direct file URL so SharePoint enforces permissions.", true);
        }
        const win = window.open("", "_blank");
        if (win) win.location.href = this._url;
        else this._setStatus("Pop-up blocked. Allow pop-ups for this site.", true);
    }

    private _onDownload(): void {
        if (!this._url) { this._setStatus("No URL is configured.", true); return; }
        const block = this._context.parameters.blockSharePointSharingLinks.raw !== false;
        if (this._kind === "unsafe" && block) {
            this._setStatus("Download blocked for sharing links - they bypass per-user permissions. Bind the direct file URL.", true);
            return;
        }
        const a = document.createElement("a");
        a.href = this._url;
        a.download = this._downloadName;
        a.click();
    }
}
