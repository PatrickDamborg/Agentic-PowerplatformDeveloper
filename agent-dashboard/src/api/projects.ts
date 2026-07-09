import { api } from "./dataverse";
import { CONFIG } from "../config";
import type { AgentScope } from "../data/types";

export interface BrowseRecord {
  id: string;
  name: string;
}

/** List active records from the table matching an agent's scope (Initiative/Program/Portfolio). */
export async function loadBrowseRecords(scope: AgentScope, search?: string): Promise<BrowseRecord[]> {
  const t = CONFIG.scopeTables[scope];
  const filters = ["statecode eq 0"];
  if (search?.trim()) {
    filters.push(`contains(${t.nameCol}, '${search.trim().replace(/'/g, "''")}')`);
  }
  const data = await api(
    `${t.entitySet}?$select=${t.idCol},${t.nameCol}` +
      `&$filter=${filters.join(" and ")}` +
      `&$orderby=${t.nameCol} asc&$top=50`
  );
  return (data.value as any[]).map((r) => ({
    id: r[t.idCol] as string,
    name: (r[t.nameCol] as string) || "(untitled)"
  }));
}
