// Shared formatting helpers, ported from the legacy web resource (lines 449-478).

export function timeAgo(date: Date | null): string {
  if (!date) return "–";
  const s = Math.max(0, (Date.now() - date.getTime()) / 1000);
  if (s < 60) return "just now";
  if (s < 3600) return `${Math.floor(s / 60)} min ago`;
  if (s < 86400) return `${Math.floor(s / 3600)} h ago`;
  return `${Math.floor(s / 86400)} d ago`;
}

export function fmtTime(date: Date | null): string {
  if (!date) return "–";
  return date.toLocaleString(undefined, {
    day: "2-digit",
    month: "short",
    hour: "2-digit",
    minute: "2-digit"
  });
}

export function fmtDuration(ms: number | null): string {
  if (ms == null || isNaN(ms) || ms < 0) return "";
  if (ms < 1000) return `${Math.round(ms)}ms`;
  if (ms < 60000) return `${(ms / 1000).toFixed(1)}s`;
  if (ms < 3600000) return `${Math.floor(ms / 60000)}m${Math.round((ms % 60000) / 1000)}s`;
  return `${(ms / 3600000).toFixed(1)}h`;
}

export const isToday = (date: Date | null): boolean =>
  !!date && date.toDateString() === new Date().toDateString();

export function normaliseStatus(raw: unknown, endTime: Date | null) {
  const s = String(raw || "").toLowerCase();
  if (/succe/.test(s)) return "success" as const;
  if (/fail|fault|error/.test(s)) return "failed" as const;
  if (/cancel/.test(s)) return "cancelled" as const;
  if (/run|start|wait|progress/.test(s)) return "running" as const;
  return endTime ? ("success" as const) : ("running" as const);
}

export const STATUS_LABEL: Record<string, string> = {
  success: "Succeeded",
  failed: "Failed",
  cancelled: "Cancelled",
  running: "Running",
  completed: "Completed"
};

export const cleanGuid = (g: unknown): string =>
  String(g || "").trim().replace(/[{}]/g, "").toLowerCase();

export const GUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
