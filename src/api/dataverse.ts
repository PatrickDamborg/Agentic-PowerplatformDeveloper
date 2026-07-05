import { CONFIG } from "../config";

// Typed port of the legacy web resource's Web API layer
// (agent-monitor.html lines 483-554).

declare global {
  interface Window {
    Xrm?: {
      Utility: { getGlobalContext(): { getClientUrl(): string } };
    };
  }
}

let clientUrl: string | null | undefined;

export function resolveClientUrl(): string | null {
  if (clientUrl !== undefined) return clientUrl;
  if (CONFIG.clientUrl) {
    clientUrl = CONFIG.clientUrl.replace(/\/$/, "");
    return clientUrl;
  }
  const candidates = [() => window.Xrm, () => window.parent?.Xrm];
  for (const get of candidates) {
    try {
      const xrm = get();
      const url = xrm?.Utility.getGlobalContext().getClientUrl();
      if (url) {
        clientUrl = url.replace(/\/$/, "");
        return clientUrl;
      }
    } catch {
      /* cross-origin parent */
    }
  }
  clientUrl = /\.dynamics\.com$/i.test(location.hostname) ? location.origin : null;
  return clientUrl;
}

export class ApiError extends Error {
  status: number;
  path: string;
  constructor(status: number, body: string, path: string) {
    let msg = `HTTP ${status}`;
    try {
      msg = JSON.parse(body).error.message || msg;
    } catch {
      /* keep default */
    }
    super(msg);
    this.status = status;
    this.path = path;
  }
}

const ODATA_HEADERS = {
  Accept: "application/json",
  "OData-MaxVersion": "4.0",
  "OData-Version": "4.0"
};

export async function api<T = any>(path: string): Promise<T> {
  const base = resolveClientUrl();
  if (!base) throw new ApiError(0, "", path);
  const res = await fetch(`${base}/api/data/v9.2/${path}`, {
    credentials: "same-origin",
    headers: {
      ...ODATA_HEADERS,
      "Cache-Control": "no-cache",
      Prefer: 'odata.include-annotations="OData.Community.Display.V1.FormattedValue"'
    }
  });
  if (!res.ok) throw new ApiError(res.status, await res.text(), path);
  return res.json();
}

export async function apiPost(entitySet: string, body: unknown): Promise<string | null> {
  const base = resolveClientUrl();
  if (!base) return null;
  const res = await fetch(`${base}/api/data/v9.2/${entitySet}`, {
    method: "POST",
    credentials: "same-origin",
    headers: { ...ODATA_HEADERS, "Content-Type": "application/json" },
    body: JSON.stringify(body)
  });
  if (!res.ok) throw new ApiError(res.status, await res.text(), entitySet);
  const loc = res.headers.get("OData-EntityId") || res.headers.get("Location") || "";
  const m = loc.match(/\(([^)]+)\)$/);
  return m ? m[1] : null;
}

export async function apiPatch(entitySet: string, id: string, body: unknown): Promise<void> {
  const base = resolveClientUrl();
  if (!base || !id) return;
  const res = await fetch(`${base}/api/data/v9.2/${entitySet}(${id})`, {
    method: "PATCH",
    credentials: "same-origin",
    headers: { ...ODATA_HEADERS, "Content-Type": "application/json" },
    body: JSON.stringify(body)
  });
  if (!res.ok) throw new ApiError(res.status, await res.text(), `${entitySet}(${id})`);
}
