// ---- Microsoft Graph helpers (pure fetch) ----------------------------------

// Reason codes used to drive graceful-degradation messages.
export type FallbackReason =
    | "not-configured"
    | "popup-blocked"
    | "cancelled"
    | "consent-required"
    | "no-access"
    | "unsupported"
    | "graph-error"
    | "auth-error";

// Thrown by the Graph helpers / token acquisition; carries a FallbackReason.
export class PreviewError extends Error {
    public reason: FallbackReason;
    constructor(reason: FallbackReason) {
        super(reason);
        this.reason = reason;
    }
}

export interface ResolvedDriveItem {
    driveId: string;
    itemId: string;
    name: string;
    isFolder: boolean;
    webUrl: string;
}

export interface DriveChild {
    id: string;
    name: string;
    isFolder: boolean;
    childCount: number;
    size: number;
    modified: string;
    mimeType: string;
    webUrl: string;
}

export interface ChildrenPage {
    items: DriveChild[];
    nextLink: string | null;
}

interface GraphRequestInit {
    method?: string;
    headers?: Record<string, string>;
    body?: string;
}

export function encodeShareUrl(url: string): string {
    // u! + unpadded base64url of the full URL (UTF-8 safe).
    const b64 = btoa(unescape(encodeURIComponent(url)));
    return "u!" + b64.replace(/=+$/, "").replace(/\//g, "_").replace(/\+/g, "-");
}

export function previewSrc(getUrl: string): string {
    const sep = getUrl.indexOf("?") === -1 ? "?" : "&";
    return getUrl + sep + "nb=true";
}

/** Fetch wrapper: on 429/503 waits Retry-After (capped ~10s) and retries once. */
async function graphFetch(token: string, url: string, init?: GraphRequestInit): Promise<Response> {
    const headers = Object.assign({ Authorization: "Bearer " + token }, (init && init.headers) || {});
    const doFetch = (): Promise<Response> =>
        fetch(url, { method: init && init.method, headers: headers, body: init && init.body });

    let r = await doFetch();
    if (r.status === 429 || r.status === 503) {
        const ra = Number(r.headers.get("Retry-After"));
        const waitMs = (isFinite(ra) && ra > 0 ? Math.min(ra, 10) : 2) * 1000;
        await new Promise((resolve) => setTimeout(resolve, waitMs));
        r = await doFetch();
    }
    return r;
}

export async function graphResolveDriveItem(token: string, url: string): Promise<ResolvedDriveItem> {
    const enc = encodeShareUrl(url);
    const api = "https://graph.microsoft.com/v1.0/shares/" + enc +
        "/driveItem?$select=id,name,parentReference,file,folder,size,webUrl";
    const r = await graphFetch(token, api);
    if (r.status === 403 || r.status === 404) throw new PreviewError("no-access");
    if (!r.ok) throw new PreviewError("graph-error");
    const j = await r.json();
    const driveId = j && j.parentReference ? j.parentReference.driveId : null;
    if (!driveId || !j.id) throw new PreviewError("graph-error");
    return {
        driveId: driveId,
        itemId: j.id,
        name: j.name || "",
        isFolder: !!j.folder,
        webUrl: j.webUrl || ""
    };
}

export async function graphGetPreviewUrl(token: string, driveId: string, itemId: string): Promise<string> {
    const api = "https://graph.microsoft.com/v1.0/drives/" + driveId + "/items/" + itemId + "/preview";
    const r = await graphFetch(token, api, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: "{}"
    });
    if (r.status === 403 || r.status === 404) throw new PreviewError("no-access");
    if (!r.ok) throw new PreviewError("unsupported");
    const j = await r.json();
    if (!j || !j.getUrl) throw new PreviewError("unsupported");
    return j.getUrl as string;
}

/** Lists the children of a folder. Pass a previous page's nextLink to fetch the next page. */
export async function graphListChildren(
    token: string,
    driveId: string,
    itemId: string,
    pageSize: number,
    nextLink?: string | null
): Promise<ChildrenPage> {
    const api = nextLink || (
        "https://graph.microsoft.com/v1.0/drives/" + driveId + "/items/" + itemId +
        "/children?$select=id,name,size,folder,file,webUrl,lastModifiedDateTime" +
        "&$orderby=name&$top=" + pageSize
    );
    const r = await graphFetch(token, api);
    if (r.status === 403 || r.status === 404) throw new PreviewError("no-access");
    if (!r.ok) throw new PreviewError("graph-error");
    const j = await r.json();
    const rawItems: Array<Record<string, unknown>> = (j && j.value) || [];
    const items: DriveChild[] = rawItems.map((it) => {
        const folder = it.folder as { childCount?: number } | undefined;
        const file = it.file as { mimeType?: string } | undefined;
        return {
            id: it.id as string,
            name: (it.name as string) || "",
            isFolder: !!folder,
            childCount: folder ? (folder.childCount || 0) : 0,
            size: (it.size as number) || 0,
            modified: (it.lastModifiedDateTime as string) || "",
            mimeType: file ? (file.mimeType || "") : "",
            webUrl: (it.webUrl as string) || ""
        };
    });
    return { items: items, nextLink: (j && j["@odata.nextLink"]) || null };
}
