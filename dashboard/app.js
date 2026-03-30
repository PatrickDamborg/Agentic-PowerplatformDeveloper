/**
 * Dataverse Activity Dashboard
 *
 * A Fluent UI web app that displays AI agent activity logs from a Dataverse
 * ActivityLog table. Provides traceability and educational context (what, why,
 * how, best practices) for every action taken.
 *
 * Auth: MSAL.js 2.x with delegated (user_impersonation) permissions.
 */

// ============================================================
// Constants
// ============================================================

const CATEGORY_MAP = {
    100000000: "Schema Change",
    100000001: "Cloud Flow",
    100000002: "Solution Operation",
    100000003: "Security",
    100000004: "Configuration",
    100000005: "Data Migration",
    100000006: "Other",
};

const STATUS_MAP = {
    100000000: { label: "Completed", css: "completed" },
    100000001: { label: "In Progress", css: "inprogress" },
    100000002: { label: "Failed", css: "failed" },
};

const CATEGORY_ICONS = {
    100000000: `<svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor"><path d="M2 3.5A1.5 1.5 0 013.5 2h9A1.5 1.5 0 0114 3.5v9a1.5 1.5 0 01-1.5 1.5h-9A1.5 1.5 0 012 12.5v-9zM3.5 3a.5.5 0 00-.5.5v9a.5.5 0 00.5.5h9a.5.5 0 00.5-.5v-9a.5.5 0 00-.5-.5h-9z"/><path d="M5 5.5a.5.5 0 01.5-.5h5a.5.5 0 010 1h-5a.5.5 0 01-.5-.5zm0 2.5a.5.5 0 01.5-.5h5a.5.5 0 010 1h-5A.5.5 0 015 8zm0 2.5a.5.5 0 01.5-.5h3a.5.5 0 010 1h-3a.5.5 0 01-.5-.5z"/></svg>`,
    100000001: `<svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor"><path d="M6 1a1 1 0 00-1 1v1H3.5A1.5 1.5 0 002 4.5v9A1.5 1.5 0 003.5 15h9a1.5 1.5 0 001.5-1.5v-9A1.5 1.5 0 0012.5 3H11V2a1 1 0 00-1-1H6zm0 1h4v1H6V2zM3.5 4h9a.5.5 0 01.5.5v9a.5.5 0 01-.5.5h-9a.5.5 0 01-.5-.5v-9a.5.5 0 01.5-.5z"/><path d="M5 7l2 2 4-4" stroke="currentColor" stroke-width="1.5" fill="none"/></svg>`,
    100000002: `<svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor"><path d="M8 1a7 7 0 100 14A7 7 0 008 1zM2 8a6 6 0 1112 0A6 6 0 012 8z"/><path d="M8 4v5h4" stroke="currentColor" stroke-width="1.2" fill="none"/></svg>`,
    100000003: `<svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor"><path d="M8 1a3 3 0 013 3v2h.5A1.5 1.5 0 0113 7.5v5a1.5 1.5 0 01-1.5 1.5h-7A1.5 1.5 0 013 12.5v-5A1.5 1.5 0 014.5 6H5V4a3 3 0 013-3zm-2 5h4V4a2 2 0 10-4 0v2z"/></svg>`,
    100000004: `<svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor"><path d="M8 4.754a3.246 3.246 0 100 6.492 3.246 3.246 0 000-6.492zM5.754 8a2.246 2.246 0 114.492 0 2.246 2.246 0 01-4.492 0z"/><path d="M9.796 1.343c-.527-1.79-3.065-1.79-3.592 0l-.094.319a.873.873 0 01-1.255.52l-.292-.16c-1.64-.892-3.433.902-2.54 2.541l.159.292a.873.873 0 01-.52 1.255l-.319.094c-1.79.527-1.79 3.065 0 3.592l.319.094a.873.873 0 01.52 1.255l-.16.292c-.892 1.64.901 3.434 2.541 2.54l.292-.159a.873.873 0 011.255.52l.094.319c.527 1.79 3.065 1.79 3.592 0l.094-.319a.873.873 0 011.255-.52l.292.16c1.64.893 3.434-.902 2.54-2.541l-.159-.292a.873.873 0 01.52-1.255l.319-.094c1.79-.527 1.79-3.065 0-3.592l-.319-.094a.873.873 0 01-.52-1.255l.16-.292c.893-1.64-.902-3.433-2.541-2.54l-.292.159a.873.873 0 01-1.255-.52l-.094-.319z"/></svg>`,
    100000005: `<svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor"><path d="M2.5 1A1.5 1.5 0 001 2.5v11A1.5 1.5 0 002.5 15h11a1.5 1.5 0 001.5-1.5v-11A1.5 1.5 0 0013.5 1h-11zM2 2.5a.5.5 0 01.5-.5h11a.5.5 0 01.5.5v11a.5.5 0 01-.5.5h-11a.5.5 0 01-.5-.5v-11z"/><path d="M4 5.5a.5.5 0 01.5-.5h7a.5.5 0 010 1h-7a.5.5 0 01-.5-.5zm0 3a.5.5 0 01.5-.5h7a.5.5 0 010 1h-7a.5.5 0 01-.5-.5zm0 3a.5.5 0 01.5-.5h4a.5.5 0 010 1h-4a.5.5 0 01-.5-.5z"/></svg>`,
    100000006: `<svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor"><path d="M8 15A7 7 0 108 1a7 7 0 000 14zm0-1A6 6 0 118 2a6 6 0 010 12z"/><path d="M8 4a.5.5 0 01.5.5v3h3a.5.5 0 010 1h-3v3a.5.5 0 01-1 0v-3h-3a.5.5 0 010-1h3v-3A.5.5 0 018 4z"/></svg>`,
};

const CONFIG_KEY = "activityDashboard_config";

// ============================================================
// State
// ============================================================

let msalInstance = null;
let accessToken = null;
let config = null;
let allActivities = [];
let previewMode = false;
let activeCategory = "";

// ============================================================
// Config persistence
// ============================================================

function loadConfig() {
    try {
        return JSON.parse(localStorage.getItem(CONFIG_KEY));
    } catch {
        return null;
    }
}

function saveConfig(cfg) {
    localStorage.setItem(CONFIG_KEY, JSON.stringify(cfg));
}

// ============================================================
// MSAL Authentication
// ============================================================

function initMsal(cfg) {
    const msalConfig = {
        auth: {
            clientId: cfg.clientId,
            authority: `https://login.microsoftonline.com/${cfg.tenantId}`,
            redirectUri: window.location.origin + window.location.pathname,
        },
        cache: {
            cacheLocation: "sessionStorage",
            storeAuthStateInCookie: false,
        },
    };
    msalInstance = new msal.PublicClientApplication(msalConfig);
}

async function login() {
    const baseUrl = config.dataverseUrl.replace(/\/+$/, "");
    const scope = `${baseUrl}/user_impersonation`;

    try {
        const response = await msalInstance.loginPopup({
            scopes: [scope],
        });
        accessToken = response.accessToken;
        showDashboard(response.account);
        await loadActivities();
    } catch (err) {
        console.error("Login failed:", err);
    }
}

async function getToken() {
    const baseUrl = config.dataverseUrl.replace(/\/+$/, "");
    const scope = `${baseUrl}/user_impersonation`;

    const accounts = msalInstance.getAllAccounts();
    if (accounts.length === 0) return null;

    try {
        const response = await msalInstance.acquireTokenSilent({
            scopes: [scope],
            account: accounts[0],
        });
        accessToken = response.accessToken;
        return accessToken;
    } catch {
        // Silent failed, try popup
        try {
            const response = await msalInstance.acquireTokenPopup({
                scopes: [scope],
            });
            accessToken = response.accessToken;
            return accessToken;
        } catch (err) {
            console.error("Token acquisition failed:", err);
            return null;
        }
    }
}

function logout() {
    msalInstance.logoutPopup();
    document.getElementById("dashboard").style.display = "none";
    document.getElementById("setup-panel").style.display = "flex";
    document.getElementById("btn-login").style.display = "";
    document.getElementById("btn-logout").style.display = "none";
    document.getElementById("user-info").style.display = "none";
    document.getElementById("env-badge").style.display = "none";
}

// ============================================================
// Dataverse API
// ============================================================

async function fetchActivities(filter) {
    const token = await getToken();
    if (!token) return [];

    const baseUrl = config.dataverseUrl.replace(/\/+$/, "");
    const apiUrl = `${baseUrl}/api/data/v9.2/`;
    const p = config.prefix.toLowerCase();
    const entitySet = `${p}_activitylogs`;

    let query = `${apiUrl}${entitySet}?$orderby=${p}_executedon desc&$top=200`;

    const filters = [];
    if (filter?.category) {
        filters.push(`${p}_category eq ${filter.category}`);
    }
    if (filter?.status) {
        filters.push(`${p}_actionstatus eq ${filter.status}`);
    }
    if (filter?.search) {
        filters.push(`contains(${p}_title,'${filter.search}')`);
    }
    if (filters.length > 0) {
        query += `&$filter=${filters.join(" and ")}`;
    }

    const response = await fetch(query, {
        headers: {
            Authorization: `Bearer ${token}`,
            Accept: "application/json",
            "OData-MaxVersion": "4.0",
            "OData-Version": "4.0",
            Prefer: 'odata.include-annotations="OData.Community.Display.V1.FormattedValue"',
        },
    });

    if (!response.ok) {
        console.error("Failed to fetch activities:", response.statusText);
        return [];
    }

    const data = await response.json();
    return data.value || [];
}

// ============================================================
// Rendering
// ============================================================

function showDashboard(account) {
    document.getElementById("setup-panel").style.display = "none";
    document.getElementById("dashboard").style.display = "";
    document.getElementById("btn-login").style.display = "none";
    document.getElementById("btn-logout").style.display = "";
    document.getElementById("user-info").style.display = "";
    document.getElementById("user-name").textContent = account?.name || account?.username || "";
    document.getElementById("env-badge").style.display = "";
    document.getElementById("env-badge").textContent = config.dataverseUrl
        .replace("https://", "")
        .replace(/\.api\.crm.*/, "");
}

function renderActivities(activities) {
    const list = document.getElementById("activity-list");
    const empty = document.getElementById("empty-state");
    const p = config.prefix.toLowerCase();

    if (activities.length === 0) {
        list.innerHTML = "";
        empty.style.display = "";
        return;
    }
    empty.style.display = "none";

    list.innerHTML = activities
        .map((a) => {
            const category = a[`${p}_category`];
            const status = a[`${p}_actionstatus`];
            const statusInfo = STATUS_MAP[status] || { label: "Unknown", css: "unknown" };
            const categoryLabel = CATEGORY_MAP[category] || "Other";
            const executedOn = a[`${p}_executedon`]
                ? formatDate(a[`${p}_executedon`])
                : "";
            const component = a[`${p}_entity`] || "";
            const sessionId = a[`${p}_sessionid`] || "";
            const what = a[`${p}_what`] || "";
            const resourceUrl = a[`${p}_resourceurl`] || "";
            const resourceType = a[`${p}_resourcetype`] || "";

            return `
                <div class="activity-card" data-status="${status}" data-id="${a[`${p}_activitylogid`]}" onclick="openDetail(this)">
                    <div class="card-header">
                        <div class="card-title">${escapeHtml(a[`${p}_title`] || "Untitled")}</div>
                        <div class="card-meta">
                            ${resourceUrl ? `<a href="${escapeHtml(resourceUrl)}" target="_blank" rel="noopener" class="resource-link" onclick="event.stopPropagation();" title="Open ${escapeHtml(resourceType)} in Power Platform">${linkIcon()} View ${escapeHtml(resourceType)}</a>` : ""}
                            <span class="badge badge-category">${categoryLabel}</span>
                            <span class="badge badge-status-${statusInfo.css}">${statusInfo.label}</span>
                        </div>
                    </div>
                    ${what ? `<div class="card-summary">${escapeHtml(what)}</div>` : ""}
                    <div class="card-footer">
                        ${executedOn ? `<span class="card-footer-item">${clockIcon()} ${executedOn}</span>` : ""}
                        ${component ? `<span class="card-footer-item">${componentIcon()} ${escapeHtml(component)}</span>` : ""}
                        ${sessionId ? `<span class="card-footer-item">${sessionIcon()} ${escapeHtml(sessionId)}</span>` : ""}
                    </div>
                </div>
            `;
        })
        .join("");
}

function updateStats(activities) {
    const p = config.prefix.toLowerCase();
    document.getElementById("stat-total").textContent = activities.length;

    const sessions = new Set(activities.map((a) => a[`${p}_sessionid`]).filter(Boolean));
    document.getElementById("stat-sessions").textContent = sessions.size;

    const completed = activities.filter((a) => a[`${p}_actionstatus`] === 100000000).length;
    document.getElementById("stat-completed").textContent = completed;

    const failed = activities.filter((a) => a[`${p}_actionstatus`] === 100000002).length;
    document.getElementById("stat-failed").textContent = failed;
}

// ============================================================
// Detail Dialog
// ============================================================

window.openDetail = function (cardEl) {
    const id = cardEl.dataset.id;
    const p = config.prefix.toLowerCase();
    const activity = allActivities.find((a) => a[`${p}_activitylogid`] === id);
    if (!activity) return;

    const category = activity[`${p}_category`];
    const status = activity[`${p}_actionstatus`];
    const statusInfo = STATUS_MAP[status] || { label: "Unknown", css: "unknown" };

    const sections = [
        {
            key: "what",
            label: "What was done",
            icon: `<svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor"><path d="M8 1a7 7 0 100 14A7 7 0 008 1zM2 8a6 6 0 1112 0A6 6 0 012 8z"/><path d="M7.5 4.5a.5.5 0 011 0v3.5H12a.5.5 0 010 1H8a.5.5 0 01-.5-.5V4.5z"/></svg>`,
            value: activity[`${p}_what`],
            cssClass: "",
        },
        {
            key: "why",
            label: "Why this approach",
            icon: `<svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor"><path d="M8 1a7 7 0 100 14A7 7 0 008 1zm0 1a6 6 0 110 12A6 6 0 018 2zm-.5 3a.75.75 0 111.5 0 .75.75 0 01-1.5 0zM7 7.5a.5.5 0 01.5-.5h1a.5.5 0 01.5.5v4a.5.5 0 01-.5.5h-1a.5.5 0 01-.5-.5v-4z"/></svg>`,
            value: activity[`${p}_why`],
            cssClass: "",
        },
        {
            key: "how",
            label: "How it was implemented",
            icon: `<svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor"><path d="M5.854 4.854a.5.5 0 10-.708-.708l-3.5 3.5a.5.5 0 000 .708l3.5 3.5a.5.5 0 00.708-.708L2.707 8l3.147-3.146zm4.292 0a.5.5 0 01.708-.708l3.5 3.5a.5.5 0 010 .708l-3.5 3.5a.5.5 0 01-.708-.708L13.293 8l-3.147-3.146z"/></svg>`,
            value: activity[`${p}_how`],
            cssClass: "how-section",
        },
        {
            key: "bestpractice",
            label: "Best Practice",
            icon: `<svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor"><path d="M8 1.5l1.545 4.757h5.002l-4.047 2.94 1.546 4.756L8 10.952l-4.046 2.94 1.546-4.756-4.047-2.94h5.002L8 1.5z"/></svg>`,
            value: activity[`${p}_bestpractice`],
            cssClass: "best-practice",
        },
    ];

    const executedOn = activity[`${p}_executedon`]
        ? formatDate(activity[`${p}_executedon`])
        : "N/A";
    const component = activity[`${p}_entity`] || "";
    const apiEndpoint = activity[`${p}_apiendpoint`] || "";
    const sessionId = activity[`${p}_sessionid`] || "";
    const env = activity[`${p}_environment`] || "";
    const resourceUrl = activity[`${p}_resourceurl`] || "";
    const resourceType = activity[`${p}_resourcetype`] || "";

    const html = `
        <div class="detail-header">
            <div class="detail-title-row">
                <div class="detail-title">${escapeHtml(activity[`${p}_title`] || "Untitled")}</div>
                ${resourceUrl ? `<a href="${escapeHtml(resourceUrl)}" target="_blank" rel="noopener" class="detail-resource-link" title="Open in Power Platform">${linkIcon()} Open ${escapeHtml(resourceType)}</a>` : ""}
            </div>
            <div class="detail-meta">
                <span class="badge badge-category">${CATEGORY_MAP[category] || "Other"}</span>
                <span class="badge badge-status-${statusInfo.css}">${statusInfo.label}</span>
            </div>
            <div class="detail-info-row">
                <span>${clockIcon()} ${executedOn}</span>
                ${component ? `<span>${componentIcon()} ${escapeHtml(component)}</span>` : ""}
                ${sessionId ? `<span>${sessionIcon()} ${escapeHtml(sessionId)}</span>` : ""}
                ${env ? `<span>Env: ${escapeHtml(env.replace("https://", "").replace(/\.api\.crm.*/, ""))}</span>` : ""}
            </div>
        </div>

        ${sections
            .filter((s) => s.value)
            .map(
                (s) => `
            <div class="detail-section">
                <div class="detail-section-label">${s.icon} ${s.label}</div>
                <div class="detail-section-content ${s.cssClass}">${escapeHtml(s.value)}</div>
            </div>
        `
            )
            .join("")}

        ${
            apiEndpoint
                ? `
            <div class="detail-section">
                <div class="detail-section-label">${CATEGORY_ICONS[100000000]} API Endpoint</div>
                <div class="detail-section-content how-section">${escapeHtml(apiEndpoint)}</div>
            </div>
        `
                : ""
        }

        <div style="text-align:right; margin-top:24px;">
            <fluent-button appearance="accent" onclick="closeDetail()">Close</fluent-button>
        </div>
    `;

    document.getElementById("detail-content").innerHTML = html;
    document.getElementById("detail-dialog").hidden = false;
};

window.closeDetail = function () {
    document.getElementById("detail-dialog").hidden = true;
};

// ============================================================
// Data Loading
// ============================================================

async function loadActivities() {
    const spinner = document.getElementById("loading-spinner");
    const list = document.getElementById("activity-list");

    spinner.style.display = "";
    list.innerHTML = "";

    const categoryFilter = activeCategory;
    const statusFilter = document.getElementById("filter-status")?.value || "";
    const searchValue = document.getElementById("search-input")?.value || "";

    const filter = {};
    if (categoryFilter) filter.category = categoryFilter;
    if (statusFilter) filter.status = statusFilter;
    if (searchValue.trim()) filter.search = searchValue.trim();

    allActivities = await fetchActivities(filter);

    spinner.style.display = "none";
    renderActivities(allActivities);
    updateStats(allActivities);

    // Update tab counts with unfiltered data (only on initial/refresh load)
    if (!categoryFilter && !statusFilter && !searchValue) {
        updateTabCounts(allActivities);
    }
}

// ============================================================
// Helpers
// ============================================================

function escapeHtml(str) {
    const div = document.createElement("div");
    div.textContent = str;
    return div.innerHTML;
}

function formatDate(isoStr) {
    const d = new Date(isoStr);
    return d.toLocaleDateString("en-GB", {
        day: "numeric",
        month: "short",
        year: "numeric",
        hour: "2-digit",
        minute: "2-digit",
    });
}

function clockIcon() {
    return `<svg width="12" height="12" viewBox="0 0 16 16" fill="currentColor"><path d="M8 1a7 7 0 100 14A7 7 0 008 1zM2 8a6 6 0 1112 0A6 6 0 012 8z"/><path d="M7.5 4a.5.5 0 011 0v3.5H12a.5.5 0 010 1H8a.5.5 0 01-.5-.5V4z"/></svg>`;
}

function componentIcon() {
    return `<svg width="12" height="12" viewBox="0 0 16 16" fill="currentColor"><path d="M2 3.5A1.5 1.5 0 013.5 2h9A1.5 1.5 0 0114 3.5v9a1.5 1.5 0 01-1.5 1.5h-9A1.5 1.5 0 012 12.5v-9zM3.5 3a.5.5 0 00-.5.5v9a.5.5 0 00.5.5h9a.5.5 0 00.5-.5v-9a.5.5 0 00-.5-.5h-9z"/></svg>`;
}

function sessionIcon() {
    return `<svg width="12" height="12" viewBox="0 0 16 16" fill="currentColor"><path d="M8 8a3 3 0 100-6 3 3 0 000 6zm-5 6s-1 0-1-1 1-4 6-4 6 3 6 4-1 1-1 1H3z"/></svg>`;
}

function linkIcon() {
    return `<svg width="12" height="12" viewBox="0 0 16 16" fill="currentColor"><path d="M6.354 5.5H4a3 3 0 000 6h3a3 3 0 002.83-4H9.4a2 2 0 01-1.4 3H5a2 2 0 110-4h1.354zm3.292 5H12a3 3 0 000-6H9a3 3 0 00-2.83 4h.43a2 2 0 011.4-3h3a2 2 0 110 4h-1.354z"/></svg>`;
}

// ============================================================
// Preview Mode (Sample Data)
// ============================================================

function generateSampleActivities() {
    const p = "demo";
    const now = Date.now();
    const hour = 3600000;

    return [
        {
            [`${p}_activitylogid`]: "s1",
            [`${p}_title`]: "Created table pda_Project",
            [`${p}_category`]: 100000000,
            [`${p}_actionstatus`]: 100000000,
            [`${p}_executedon`]: new Date(now - hour * 1).toISOString(),
            [`${p}_entity`]: "pda_Project",
            [`${p}_sessionid`]: "session-a1b2",
            [`${p}_what`]: "Created a new Dataverse table pda_Project with columns for Name, Status, Start Date, and Owner.",
            [`${p}_why`]: "The project tracking solution needs a dedicated table to store project metadata and link related tasks.",
            [`${p}_how`]: "POST /api/data/v9.2/EntityDefinitions\n{\n  SchemaName: 'pda_Project',\n  DisplayName: 'Project',\n  PrimaryNameAttribute: 'pda_name'\n}",
            [`${p}_bestpractice`]: "Always use a publisher prefix for custom tables to avoid naming conflicts across solutions.",
            [`${p}_apiendpoint`]: "POST /api/data/v9.2/EntityDefinitions",
            [`${p}_environment`]: "https://contoso-dev.crm.dynamics.com",
            [`${p}_resourceurl`]: "https://make.powerapps.com/environments/contoso-dev/entities/pda_project",
            [`${p}_resourcetype`]: "Table",
        },
        {
            [`${p}_activitylogid`]: "s2",
            [`${p}_title`]: "Added lookup: Task → Project",
            [`${p}_category`]: 100000000,
            [`${p}_actionstatus`]: 100000000,
            [`${p}_executedon`]: new Date(now - hour * 2).toISOString(),
            [`${p}_entity`]: "pda_Task",
            [`${p}_sessionid`]: "session-a1b2",
            [`${p}_what`]: "Added a Many-to-One lookup from pda_Task to pda_Project.",
            [`${p}_why`]: "Tasks need to reference their parent project for reporting and navigation.",
            [`${p}_how`]: "POST /api/data/v9.2/RelationshipDefinitions\nRelationshipType: OneToManyRelationship",
            [`${p}_bestpractice`]: "Use cascading behaviour 'RemoveLink' on delete to avoid orphaned records.",
            [`${p}_resourceurl`]: "https://make.powerapps.com/environments/contoso-dev/entities/pda_task/relationships",
            [`${p}_resourcetype`]: "Table",
        },
        {
            [`${p}_activitylogid`]: "s3",
            [`${p}_title`]: "Deployed cloud flow: Notify on Task Completion",
            [`${p}_category`]: 100000001,
            [`${p}_actionstatus`]: 100000000,
            [`${p}_executedon`]: new Date(now - hour * 4).toISOString(),
            [`${p}_entity`]: "Cloud Flow",
            [`${p}_sessionid`]: "session-c3d4",
            [`${p}_what`]: "Created an automated cloud flow that sends a Teams notification when a task status changes to Completed.",
            [`${p}_why`]: "Stakeholders need real-time visibility when tasks are finished.",
            [`${p}_how`]: "Trigger: Dataverse 'When a row is modified'\nCondition: Status == Completed\nAction: Post adaptive card to Teams channel",
            [`${p}_bestpractice`]: "Filter trigger conditions at the connector level to reduce unnecessary flow runs.",
            [`${p}_resourceurl`]: "https://make.powerautomate.com/environments/contoso-dev/flows/f1a2b3c4-d5e6-7890-abcd-ef1234567890/details",
            [`${p}_resourcetype`]: "Flow",
        },
        {
            [`${p}_activitylogid`]: "s4",
            [`${p}_title`]: "Added pda_Project to solution",
            [`${p}_category`]: 100000002,
            [`${p}_actionstatus`]: 100000000,
            [`${p}_executedon`]: new Date(now - hour * 5).toISOString(),
            [`${p}_entity`]: "pda_Project",
            [`${p}_sessionid`]: "session-a1b2",
            [`${p}_what`]: "Added the pda_Project table and all related components to the ProjectTracker solution.",
            [`${p}_why`]: "All customisations must belong to a managed solution for ALM and deployment.",
            [`${p}_how`]: "POST /api/data/v9.2/AddSolutionComponent",
            [`${p}_bestpractice`]: "Always add components to a solution immediately after creation for traceability.",
            [`${p}_resourceurl`]: "https://make.powerapps.com/environments/contoso-dev/solutions/ProjectTracker",
            [`${p}_resourcetype`]: "Solution",
        },
        {
            [`${p}_activitylogid`]: "s5",
            [`${p}_title`]: "Configured security role: Project Manager",
            [`${p}_category`]: 100000003,
            [`${p}_actionstatus`]: 100000000,
            [`${p}_executedon`]: new Date(now - hour * 6).toISOString(),
            [`${p}_entity`]: "Security Role",
            [`${p}_sessionid`]: "session-e5f6",
            [`${p}_what`]: "Created a security role granting CRUD on pda_Project (org-level) and pda_Task (BU-level).",
            [`${p}_why`]: "Project Managers need full access to projects but scoped access to tasks within their business unit.",
            [`${p}_how`]: "PATCH /api/data/v9.2/roles(...)/privileges",
            [`${p}_bestpractice`]: "Follow least-privilege principle — grant only the access levels users actually need.",
            [`${p}_resourceurl`]: "https://make.powerapps.com/environments/contoso-dev/security/roles",
            [`${p}_resourcetype`]: "Security Role",
        },
        {
            [`${p}_activitylogid`]: "s6",
            [`${p}_title`]: "Data import: Legacy projects migration",
            [`${p}_category`]: 100000005,
            [`${p}_actionstatus`]: 100000002,
            [`${p}_executedon`]: new Date(now - hour * 8).toISOString(),
            [`${p}_entity`]: "pda_Project",
            [`${p}_sessionid`]: "session-g7h8",
            [`${p}_what`]: "Attempted to import 150 legacy project records from CSV. 3 rows failed due to duplicate name constraint.",
            [`${p}_why`]: "Migrating historical data from the previous system into the new Dataverse solution.",
            [`${p}_how`]: "POST /api/data/v9.2/$batch\nContent-Type: multipart/mixed",
            [`${p}_bestpractice`]: "Always run a dry-run validation before bulk imports to catch constraint violations early.",
            [`${p}_resourceurl`]: "https://make.powerapps.com/environments/contoso-dev/entities/pda_project/data",
            [`${p}_resourcetype`]: "Table",
        },
        {
            [`${p}_activitylogid`]: "s7",
            [`${p}_title`]: "Updated environment variable: DefaultRegion",
            [`${p}_category`]: 100000004,
            [`${p}_actionstatus`]: 100000000,
            [`${p}_executedon`]: new Date(now - hour * 10).toISOString(),
            [`${p}_entity`]: "Environment Variable",
            [`${p}_sessionid`]: "session-e5f6",
            [`${p}_what`]: "Set the DefaultRegion environment variable to 'EMEA' for the dev environment.",
            [`${p}_why`]: "Cloud flows reference this variable for region-specific API routing.",
            [`${p}_how`]: "PATCH /api/data/v9.2/environmentvariabledefinitions(...)",
            [`${p}_bestpractice`]: "Use environment variables instead of hard-coded values so flows adapt across environments.",
            [`${p}_resourceurl`]: "https://make.powerapps.com/environments/contoso-dev/solutions/ProjectTracker/environmentvariables",
            [`${p}_resourcetype`]: "Environment Variable",
        },
    ];
}

function updateTabCounts(activities) {
    const p = config.prefix.toLowerCase();
    const tabs = document.querySelectorAll(".filter-tab");
    tabs.forEach((tab) => {
        const cat = tab.dataset.category;
        let count;
        if (cat === "") {
            count = activities.length;
        } else {
            count = activities.filter((a) => String(a[`${p}_category`]) === cat).length;
        }
        let countEl = tab.querySelector(".tab-count");
        if (!countEl) {
            countEl = document.createElement("span");
            countEl.className = "tab-count";
            tab.appendChild(countEl);
        }
        countEl.textContent = count;
        // Hide tabs with zero count (except "All")
        if (cat !== "" && count === 0) {
            tab.style.display = "none";
        } else {
            tab.style.display = "";
        }
    });
}

function setActiveTab(category) {
    activeCategory = category;
    document.querySelectorAll(".filter-tab").forEach((tab) => {
        tab.classList.toggle("active", tab.dataset.category === category);
    });
}

function enterPreviewMode() {
    previewMode = true;
    config = { clientId: "", tenantId: "", dataverseUrl: "https://contoso-dev.crm.dynamics.com", prefix: "demo" };

    document.getElementById("setup-panel").style.display = "none";
    document.getElementById("dashboard").style.display = "";
    document.getElementById("btn-login").style.display = "none";
    document.getElementById("preview-banner").style.display = "";
    document.getElementById("env-badge").style.display = "";
    document.getElementById("env-badge").textContent = "contoso-dev (preview)";
    document.getElementById("user-info").style.display = "";
    document.getElementById("user-name").textContent = "Preview User";

    const all = generateSampleActivities();
    allActivities = all;
    renderActivities(allActivities);
    updateStats(allActivities);
    updateTabCounts(all);
}

function exitPreviewMode() {
    previewMode = false;
    config = loadConfig();
    allActivities = [];

    document.getElementById("dashboard").style.display = "none";
    document.getElementById("setup-panel").style.display = "flex";
    document.getElementById("preview-banner").style.display = "none";
    document.getElementById("btn-login").style.display = "";
    document.getElementById("btn-logout").style.display = "none";
    document.getElementById("user-info").style.display = "none";
    document.getElementById("env-badge").style.display = "none";
}

// ============================================================
// Debounce utility
// ============================================================

function debounce(fn, ms) {
    let timer;
    return (...args) => {
        clearTimeout(timer);
        timer = setTimeout(() => fn(...args), ms);
    };
}

// ============================================================
// Initialization
// ============================================================

document.addEventListener("DOMContentLoaded", () => {
    // Show the redirect URI the user needs to register
    const redirectEl = document.getElementById("current-redirect-uri");
    if (redirectEl) {
        redirectEl.textContent = window.location.origin + window.location.pathname;
    }

    // Load saved config
    config = loadConfig();

    if (config) {
        document.getElementById("input-client-id").value = config.clientId || "";
        document.getElementById("input-tenant-id").value = config.tenantId || "";
        document.getElementById("input-dataverse-url").value = config.dataverseUrl || "";
        document.getElementById("input-prefix").value = config.prefix || "";
        initMsal(config);

        // Try silent auth
        const accounts = msalInstance.getAllAccounts();
        if (accounts.length > 0) {
            getToken().then((token) => {
                if (token) {
                    showDashboard(accounts[0]);
                    loadActivities();
                }
            });
        }
    }

    // Save config
    document.getElementById("btn-save-config").addEventListener("click", () => {
        const clientId = document.getElementById("input-client-id").value.trim();
        const tenantId = document.getElementById("input-tenant-id").value.trim();
        const dataverseUrl = document.getElementById("input-dataverse-url").value.trim().replace(/\/+$/, "");
        const prefix = document.getElementById("input-prefix").value.trim();

        if (!clientId || !tenantId || !dataverseUrl || !prefix) {
            alert("Please fill in all fields.");
            return;
        }

        config = { clientId, tenantId, dataverseUrl, prefix };
        saveConfig(config);
        initMsal(config);
        login();
    });

    // Auth buttons
    document.getElementById("btn-login").addEventListener("click", () => {
        if (!config) {
            alert("Please configure your connection first.");
            return;
        }
        login();
    });
    document.getElementById("btn-logout").addEventListener("click", logout);

    // Preview mode
    document.getElementById("btn-preview").addEventListener("click", () => {
        enterPreviewMode();
    });
    document.getElementById("exit-preview").addEventListener("click", (e) => {
        e.preventDefault();
        exitPreviewMode();
    });

    // Auto-enter preview if ?preview query param is present
    if (new URLSearchParams(window.location.search).has("preview")) {
        enterPreviewMode();
    }

    // Filters — in preview mode, filter the sample data client-side
    const handleFilter = () => {
        if (previewMode) {
            const cat = activeCategory;
            const st = document.getElementById("filter-status").value;
            const q = (document.getElementById("search-input").value || "").toLowerCase();
            const p = config.prefix.toLowerCase();
            let filtered = generateSampleActivities();
            if (cat) filtered = filtered.filter((a) => String(a[`${p}_category`]) === cat);
            if (st) filtered = filtered.filter((a) => String(a[`${p}_actionstatus`]) === st);
            if (q) filtered = filtered.filter((a) => (a[`${p}_title`] || "").toLowerCase().includes(q));
            allActivities = filtered;
            renderActivities(allActivities);
            updateStats(allActivities);
        } else {
            loadActivities();
        }
    };

    // Category tabs
    document.getElementById("filter-tabs").addEventListener("click", (e) => {
        const tab = e.target.closest(".filter-tab");
        if (!tab) return;
        setActiveTab(tab.dataset.category);
        handleFilter();
    });

    document.getElementById("filter-status").addEventListener("change", handleFilter);
    document.getElementById("search-input").addEventListener("input", debounce(handleFilter, 400));
    document.getElementById("btn-refresh").addEventListener("click", handleFilter);

    // Close dialog on Escape
    document.addEventListener("keydown", (e) => {
        if (e.key === "Escape") closeDetail();
    });
});
