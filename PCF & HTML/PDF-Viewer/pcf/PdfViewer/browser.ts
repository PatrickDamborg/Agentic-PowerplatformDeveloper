import {
    ChildrenPage,
    DriveChild,
    PreviewError,
    ResolvedDriveItem,
    graphGetPreviewUrl,
    graphListChildren,
    previewSrc
} from "./graph";

export interface FileBrowserOptions {
    host: HTMLElement;
    height: number;
    pageSize: number;
    getToken: () => Promise<string>;
    onStatus: (text: string, isError: boolean) => void;
}

interface BreadcrumbEntry {
    driveId: string;
    itemId: string;
    name: string;
}

/**
 * Renders a SharePoint-like folder/file browser for a resolved library or folder driveItem,
 * using delegated Microsoft Graph calls so per-user permissions are always enforced.
 */
export class FileBrowser {
    private _opts: FileBrowserOptions;
    private _root: HTMLDivElement | null = null;
    private _crumbsEl!: HTMLDivElement;
    private _listPaneEl!: HTMLDivElement;
    private _rowsEl!: HTMLDivElement;
    private _listStatusEl!: HTMLDivElement;
    private _paneBarEl!: HTMLDivElement;
    private _paneTitleEl!: HTMLSpanElement;
    private _paneBodyEl!: HTMLDivElement;
    private _iframe: HTMLIFrameElement | null = null;

    private _breadcrumb: BreadcrumbEntry[] = [];
    private _childrenCache: Map<string, ChildrenPage> = new Map();
    private _selectedId: string | null = null;
    private _navToken = 0;

    constructor(opts: FileBrowserOptions) {
        this._opts = opts;
    }

    public open(root: ResolvedDriveItem): void {
        if (!this._root) this._buildDOM();
        (this._root as HTMLDivElement).style.height = this._opts.height + "px";
        (this._root as HTMLDivElement).style.display = "";
        this._childrenCache.clear();
        this._breadcrumb = [{ driveId: root.driveId, itemId: root.itemId, name: root.name || "Documents" }];
        this._selectedId = null;
        this._showList();
        this._showEmptyPreview();
        this._renderBreadcrumb();
        void this._loadFolder(root.driveId, root.itemId);
    }

    public close(): void {
        this._teardownIframe();
        this._navToken++;
        this._childrenCache.clear();
        this._breadcrumb = [];
        if (this._root) this._root.style.display = "none";
    }

    // ---- DOM construction ---------------------------------------------------

    private _buildDOM(): void {
        const root = document.createElement("div");
        root.className = "pv-browser";

        this._crumbsEl = document.createElement("div");
        this._crumbsEl.className = "pv-crumbs";

        const split = document.createElement("div");
        split.className = "pv-split";

        this._listPaneEl = document.createElement("div");
        this._listPaneEl.className = "pv-list-pane";
        this._rowsEl = document.createElement("div");
        this._rowsEl.className = "pv-rows";
        this._listStatusEl = document.createElement("div");
        this._listStatusEl.className = "pv-list-status";
        this._listStatusEl.style.display = "none";
        this._listPaneEl.append(this._rowsEl, this._listStatusEl);

        const previewPane = document.createElement("div");
        previewPane.className = "pv-preview-pane";

        this._paneBarEl = document.createElement("div");
        this._paneBarEl.className = "pv-pane-bar";
        const backBtn = document.createElement("button");
        backBtn.type = "button";
        backBtn.className = "pv-pane-back";
        backBtn.textContent = "< Back to files";
        backBtn.addEventListener("click", () => this._showList());
        this._paneTitleEl = document.createElement("span");
        this._paneTitleEl.className = "pv-pane-title";
        this._paneBarEl.append(backBtn, this._paneTitleEl);

        this._paneBodyEl = document.createElement("div");
        this._paneBodyEl.className = "pv-pane-body";

        previewPane.append(this._paneBarEl, this._paneBodyEl);
        split.append(this._listPaneEl, previewPane);
        root.append(this._crumbsEl, split);

        this._opts.host.appendChild(root);
        this._root = root;
    }

    private _showList(): void {
        if (this._root) this._root.classList.remove("pv-show-preview");
    }

    private _showPreviewPane(): void {
        if (this._root) this._root.classList.add("pv-show-preview");
    }

    private _key(driveId: string, itemId: string): string {
        return driveId + "|" + itemId;
    }

    private _currentEntry(): BreadcrumbEntry {
        return this._breadcrumb[this._breadcrumb.length - 1];
    }

    // ---- Breadcrumb -----------------------------------------------------------

    private _renderBreadcrumb(): void {
        this._crumbsEl.replaceChildren();
        this._breadcrumb.forEach((entry, i) => {
            if (i > 0) {
                const sep = document.createElement("span");
                sep.className = "pv-crumb-sep";
                sep.textContent = "/";
                this._crumbsEl.appendChild(sep);
            }
            if (i === this._breadcrumb.length - 1) {
                const cur = document.createElement("span");
                cur.className = "pv-crumb-current";
                cur.textContent = entry.name;
                this._crumbsEl.appendChild(cur);
            } else {
                const btn = document.createElement("button");
                btn.type = "button";
                btn.className = "pv-crumb";
                btn.textContent = entry.name;
                btn.addEventListener("click", () => this._navigateToCrumb(i));
                this._crumbsEl.appendChild(btn);
            }
        });
    }

    private _navigateToCrumb(index: number): void {
        this._breadcrumb = this._breadcrumb.slice(0, index + 1);
        this._renderBreadcrumb();
        this._showList();
        const entry = this._currentEntry();
        void this._loadFolder(entry.driveId, entry.itemId);
    }

    // ---- Folder listing ---------------------------------------------------

    private async _loadFolder(driveId: string, itemId: string): Promise<void> {
        const myToken = ++this._navToken;
        this._selectedId = null;
        this._showEmptyPreview();

        const key = this._key(driveId, itemId);
        const cached = this._childrenCache.get(key);
        if (cached) {
            this._renderRows(cached.items);
            return;
        }

        this._rowsEl.replaceChildren();
        this._setListStatus("Loading...", false);

        try {
            const token = await this._opts.getToken();
            if (myToken !== this._navToken) return;
            const page = await graphListChildren(token, driveId, itemId, this._opts.pageSize);
            if (myToken !== this._navToken) return;
            this._childrenCache.set(key, page);
            this._renderRows(page.items);
        } catch (e) {
            if (myToken !== this._navToken) return;
            const reason = e instanceof PreviewError ? e.reason : "graph-error";
            this._setListStatus(
                reason === "no-access" ? "You don't have access to this folder." : "Couldn't load this folder. Try again.",
                true
            );
        }
    }

    private _setListStatus(text: string, isError: boolean): void {
        this._listStatusEl.textContent = text;
        this._listStatusEl.style.display = text ? "" : "none";
        this._listStatusEl.classList.toggle("is-error", isError);
    }

    private _renderRows(items: DriveChild[]): void {
        this._rowsEl.replaceChildren();
        if (items.length === 0) {
            this._setListStatus("This folder is empty.", false);
            return;
        }
        this._setListStatus("", false);

        // Folders first, then files; each group keeps the server's (name) order.
        const folders = items.filter((it) => it.isFolder);
        const files = items.filter((it) => !it.isFolder);
        const ordered = folders.concat(files);

        for (const item of ordered) {
            const row = document.createElement("button");
            row.type = "button";
            row.className = "pv-row" + (item.id === this._selectedId ? " is-selected" : "");

            const badge = document.createElement("span");
            if (item.isFolder) {
                badge.className = "pv-badge-folder";
            } else {
                badge.className = "pv-badge-file";
                badge.textContent = this._extensionLabel(item.name);
            }

            const name = document.createElement("span");
            name.className = "pv-row-name";
            name.textContent = item.name;

            const meta = document.createElement("span");
            meta.className = "pv-row-meta";
            meta.textContent = item.isFolder
                ? item.childCount + " items"
                : this._formatBytes(item.size) + " - " + this._formatDate(item.modified);

            row.append(badge, name, meta);
            row.addEventListener("click", () => {
                if (item.isFolder) this._openFolder(item);
                else void this._openFilePreview(item);
            });
            this._rowsEl.appendChild(row);
        }

        const page = this._childrenCache.get(this._key(this._currentEntry().driveId, this._currentEntry().itemId));
        if (page && page.nextLink) {
            const more = document.createElement("button");
            more.type = "button";
            more.className = "pv-loadmore-row";
            more.textContent = "Load more";
            more.addEventListener("click", () => void this._loadMore());
            this._rowsEl.appendChild(more);
        }
    }

    private async _loadMore(): Promise<void> {
        const entry = this._currentEntry();
        const key = this._key(entry.driveId, entry.itemId);
        const page = this._childrenCache.get(key);
        if (!page || !page.nextLink) return;
        const myToken = this._navToken;
        try {
            const token = await this._opts.getToken();
            if (myToken !== this._navToken) return;
            const nextPage = await graphListChildren(token, entry.driveId, entry.itemId, this._opts.pageSize, page.nextLink);
            if (myToken !== this._navToken) return;
            const merged: ChildrenPage = { items: page.items.concat(nextPage.items), nextLink: nextPage.nextLink };
            this._childrenCache.set(key, merged);
            this._renderRows(merged.items);
        } catch (_) {
            this._opts.onStatus("Couldn't load more items. Try again.", true);
        }
    }

    private _openFolder(item: DriveChild): void {
        const parent = this._currentEntry();
        this._breadcrumb.push({ driveId: parent.driveId, itemId: item.id, name: item.name });
        this._renderBreadcrumb();
        void this._loadFolder(parent.driveId, item.id);
    }

    // ---- File preview -------------------------------------------------------

    private async _openFilePreview(item: DriveChild): Promise<void> {
        this._selectedId = item.id;
        this._renderRows(this._currentItems());
        this._paneTitleEl.textContent = item.name;
        this._showPaneLoading();
        this._showPreviewPane();

        const myToken = ++this._navToken;
        try {
            const parent = this._currentEntry();
            const token = await this._opts.getToken();
            if (myToken !== this._navToken) return;
            const getUrl = await graphGetPreviewUrl(token, parent.driveId, item.id);
            if (myToken !== this._navToken) return;
            this._renderPreviewIframe(getUrl);
        } catch (e) {
            if (myToken !== this._navToken) return;
            this._renderFallback(item, e instanceof PreviewError ? e.reason : "graph-error");
        }
    }

    private _currentItems(): DriveChild[] {
        const entry = this._currentEntry();
        const page = this._childrenCache.get(this._key(entry.driveId, entry.itemId));
        return page ? page.items : [];
    }

    private _showPaneLoading(): void {
        this._teardownIframe();
        this._paneBodyEl.replaceChildren();
        const loading = document.createElement("div");
        loading.className = "pv-pane-empty";
        loading.textContent = "Loading preview...";
        this._paneBodyEl.appendChild(loading);
    }

    private _showEmptyPreview(): void {
        this._teardownIframe();
        this._paneBodyEl.replaceChildren();
        const empty = document.createElement("div");
        empty.className = "pv-pane-empty";
        empty.textContent = "Select a file to preview it here.";
        this._paneBodyEl.appendChild(empty);
        this._paneTitleEl.textContent = "";
    }

    private _renderPreviewIframe(getUrl: string): void {
        this._paneBodyEl.replaceChildren();
        const iframe = document.createElement("iframe");
        iframe.className = "pv-browser-iframe";
        iframe.setAttribute("title", "Document preview");
        iframe.setAttribute("referrerpolicy", "no-referrer");
        iframe.src = previewSrc(getUrl);
        this._paneBodyEl.appendChild(iframe);
        this._iframe = iframe;
    }

    private _renderFallback(item: DriveChild, reason: string): void {
        this._paneBodyEl.replaceChildren();
        const wrap = document.createElement("div");
        wrap.className = "pv-pane-fallback";
        const msg = document.createElement("div");
        msg.textContent = reason === "no-access"
            ? "You don't have access to this file."
            : "This file can't be previewed inline.";
        wrap.appendChild(msg);
        if (item.webUrl) {
            const openBtn = document.createElement("button");
            openBtn.type = "button";
            openBtn.className = "pv-btn";
            openBtn.textContent = "Open in SharePoint";
            openBtn.addEventListener("click", () => {
                const win = window.open("", "_blank");
                if (win) win.location.href = item.webUrl;
            });
            wrap.appendChild(openBtn);
        }
        this._paneBodyEl.appendChild(wrap);
    }

    private _teardownIframe(): void {
        if (this._iframe) {
            this._iframe.src = "about:blank";
            this._iframe.remove();
            this._iframe = null;
        }
    }

    // ---- Formatting helpers ---------------------------------------------------

    private _extensionLabel(name: string): string {
        const m = /\.([a-z0-9]{1,5})$/i.exec(name);
        return m ? m[1].toUpperCase() : "FILE";
    }

    private _formatBytes(size: number): string {
        if (!size) return "0 KB";
        const kb = size / 1024;
        if (kb < 1024) return Math.max(1, Math.round(kb)) + " KB";
        return (kb / 1024).toFixed(1) + " MB";
    }

    private _formatDate(iso: string): string {
        if (!iso) return "";
        const d = new Date(iso);
        if (isNaN(d.getTime())) return "";
        return d.toLocaleDateString();
    }
}
