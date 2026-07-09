import { PublicClientApplication } from "@azure/msal-browser";

// Page-shared MSAL registry -------------------------------------------------
// One PublicClientApplication per (clientId|authority|redirectUri), shared across
// all control instances on the page so the token cache and active account are shared.
export interface MsalEntry { app: PublicClientApplication; ready: Promise<void>; }

const _msalRegistry: Map<string, MsalEntry> = new Map();

export function getMsal(clientId: string, authority: string, redirectUri: string): MsalEntry {
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
