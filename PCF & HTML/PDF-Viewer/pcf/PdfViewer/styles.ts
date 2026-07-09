// Bumped so an older control version cached on the same page can't pin stale CSS.
export const STYLE_ID = "pv-styles-context-v2";

export function injectStyles(): void {
    if (document.getElementById(STYLE_ID)) return;
    const s = document.createElement("style");
    s.id = STYLE_ID;
    s.textContent = [
        // Card
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
        ".pv-iframe{width:100%;border:0;display:block;height:600px}",

        // File browser (library / folder mode)
        ".pv-browser-wrap{display:none}",
        ".pv-browser{display:flex;flex-direction:column;gap:6px;width:100%;box-sizing:border-box}",
        ".pv-crumbs{display:flex;flex-wrap:wrap;align-items:center;gap:2px;font-size:13px;color:#605e5c;min-height:22px}",
        ".pv-crumb{background:none;border:none;color:#0078d4;cursor:pointer;font:inherit;padding:2px 4px;border-radius:2px}",
        ".pv-crumb:hover{background:#f3f2f1;text-decoration:underline}",
        ".pv-crumb-sep{color:#a19f9d;padding:0 2px}",
        ".pv-crumb-current{color:#323130;font-weight:600;padding:2px 4px}",
        ".pv-split{display:flex;flex-direction:row;border:1px solid #e1dfdd;border-radius:4px;overflow:hidden;background:#fff;flex:1;min-height:0}",
        ".pv-list-pane{width:320px;min-width:240px;max-width:45%;border-right:1px solid #e1dfdd;overflow-y:auto;flex-shrink:0;display:flex;flex-direction:column}",
        ".pv-rows{display:flex;flex-direction:column}",
        ".pv-row{display:flex;align-items:center;gap:8px;width:100%;text-align:left;background:none;border:none;border-bottom:1px solid #f3f2f1;padding:8px 10px;cursor:pointer;font:inherit;color:#323130}",
        ".pv-row:hover{background:#f3f2f1}",
        ".pv-row.is-selected{background:#deecf9}",
        ".pv-badge-folder{width:22px;height:16px;background:#ffc83d;border-radius:0 2px 2px 2px;flex-shrink:0;position:relative}",
        ".pv-badge-folder::before{content:\"\";position:absolute;left:0;top:-4px;width:10px;height:4px;background:#ffc83d;border-radius:2px 2px 0 0}",
        ".pv-badge-file{min-width:28px;height:16px;background:#0078d4;color:#fff;font-size:9px;font-weight:700;display:flex;align-items:center;justify-content:center;border-radius:2px;padding:0 3px;flex-shrink:0}",
        ".pv-row-name{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-size:13px}",
        ".pv-row-meta{flex-shrink:0;font-size:11px;color:#605e5c;white-space:nowrap}",
        ".pv-list-status{padding:16px 10px;font-size:13px;color:#605e5c;text-align:center}",
        ".pv-list-status.is-error{color:#a4262c}",
        ".pv-loadmore-row{width:100%;text-align:center;padding:8px;background:none;border:none;color:#0078d4;cursor:pointer;font:inherit;border-top:1px solid #f3f2f1}",
        ".pv-loadmore-row:hover{background:#f3f2f1}",
        ".pv-preview-pane{flex:1;min-width:0;display:flex;flex-direction:column;background:#f5f5f5}",
        ".pv-pane-bar{display:none;align-items:center;gap:8px;padding:6px 10px;border-bottom:1px solid #e1dfdd;background:#fff;flex-shrink:0}",
        ".pv-pane-back{background:none;border:none;color:#0078d4;cursor:pointer;font:inherit;padding:2px 6px;flex-shrink:0}",
        ".pv-pane-title{font-size:13px;font-weight:600;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}",
        ".pv-pane-body{flex:1;min-height:0;position:relative}",
        ".pv-pane-empty{display:flex;align-items:center;justify-content:center;height:100%;color:#605e5c;font-size:13px;text-align:center;padding:20px;box-sizing:border-box}",
        ".pv-pane-fallback{display:flex;flex-direction:column;align-items:center;justify-content:center;height:100%;gap:10px;padding:20px;text-align:center;color:#605e5c;font-size:13px;box-sizing:border-box}",
        ".pv-browser-iframe{width:100%;height:100%;border:0;display:block}",

        // Narrow container: drill-in (one pane visible at a time)
        ".pv-narrow .pv-list-pane{width:100%;max-width:100%;border-right:none}",
        ".pv-narrow .pv-preview-pane{display:none}",
        ".pv-narrow .pv-browser.pv-show-preview .pv-list-pane{display:none}",
        ".pv-narrow .pv-browser.pv-show-preview .pv-preview-pane{display:flex;width:100%}",
        ".pv-narrow .pv-browser.pv-show-preview .pv-pane-bar{display:flex}"
    ].join("\n");
    document.head.appendChild(s);
}
