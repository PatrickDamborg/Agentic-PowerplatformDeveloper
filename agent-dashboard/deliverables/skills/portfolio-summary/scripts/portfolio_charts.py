#!/usr/bin/env python3
"""
portfolio_charts.py — Context&-branded charts for the xPM portfolio summary.

Renders the charts that are RELEVANT to a portfolio (the agent injects the data;
empty data is skipped automatically):
  1. Initiatives by number of open "4. High" risks.
  2. Initiatives by budget overrun (% over plan).
  3. Initiatives by phase — a portfolio-composition FALLBACK, shown only when
     neither of the above has data, so a summary always has at least one visual.

HOW DATA GETS HERE (important):
  The Copilot Studio code-interpreter sandbox has NO network access, so this
  script cannot call the Dataverse MCP itself. The AGENT retrieves the data
  with the Dataverse MCP (read_query) and replaces the DATA lists below with
  live rows BEFORE executing this script. The sample values let the script run
  standalone for a quick visual test.

Style: Context& brand (see .claude/skills/context-brand/SKILL.md) — Aktiv
Grotesk (graceful fallback), white card on light grey, dark-blue bars with the
worst bar highlighted in brand orange (composition chart stays neutral). No red.

Outputs (written to the working dir, returned as renderable images):
  - high_risk_by_initiative.png
  - budget_overrun_by_initiative.png
  - phase_composition.png   (fallback only)
"""

import matplotlib
matplotlib.use("Agg")  # headless backend — required in the sandbox
import matplotlib.pyplot as plt


# ─────────────────────────────────────────────────────────────────────────
# LIVE DATA — the agent REPLACES these lists with Dataverse MCP results.
# Keep the exact shape. Use real initiative names, never GUIDs.
# ─────────────────────────────────────────────────────────────────────────

# Chart 1: count of OPEN risks at severity "4. High", per initiative.
HIGH_RISK_DATA = [
    {"initiative": "EU FMD Serialisation Platform", "high_risks": 5},
    {"initiative": "Cold Chain IoT Monitoring Platform", "high_risks": 4},
    {"initiative": "GxP Quality Management System", "high_risks": 2},
    {"initiative": "Customer Self-Service Portal", "high_risks": 1},
    {"initiative": "Regulatory Reporting Automation", "high_risks": 0},
    {"initiative": "AI Route Optimisation Engine", "high_risks": 0},
]

# Chart 2: planned vs actual cost per initiative (same currency).
OVERRUN_DATA = [
    {"initiative": "EU FMD Serialisation Platform", "planned": 1200000, "actual": 1655000},
    {"initiative": "Cold Chain IoT Monitoring Platform", "planned": 900000, "actual": 1120000},
    {"initiative": "GxP Quality Management System", "planned": 750000, "actual": 815000},
    {"initiative": "Customer Self-Service Portal", "planned": 500000, "actual": 470000},
    {"initiative": "Regulatory Reporting Automation", "planned": 400000, "actual": 400000},
]

# Chart 3 (fallback): initiative count per phase (from pum_initiative.pum_phase).
PHASE_DATA = [
    {"phase": "Active", "count": 4},
    {"phase": "Proposed", "count": 1},
    {"phase": "Under Evaluation", "count": 1},
]

CURRENCY = ""   # e.g. "DKK" — set if known; charts work either way.
TOP_N = 8       # show at most this many bars per chart.


# ─────────────────────────────────────────────────────────────────────────
# Context& brand palette (.claude/skills/context-brand/SKILL.md)
# ─────────────────────────────────────────────────────────────────────────
DARK_BLUE = "#043F9C"   # primary data colour
ORANGE    = "#FF922D"   # highlight the worst bar (attention)
GREY_TEXT = "#3D424B"   # secondary text / labels
GREY_LINE = "#C9D6DE"   # gridlines / dividers
GREY_BG   = "#F1F5F7"   # section ("card") background
BLACK     = "#000000"   # titles


# ─────────────────────────────────────────────────────────────────────────
# Styling helpers
# ─────────────────────────────────────────────────────────────────────────

def _apply_brand_style():
    """Brand typography + colours via rcParams. Aktiv Grotesk is licensed and
    likely absent from the sandbox — matplotlib falls back down the list."""
    plt.rcParams.update({
        "font.family": "sans-serif",
        "font.sans-serif": ["Aktiv Grotesk", "Neue Haas Grotesk Text Pro",
                             "Segoe UI", "Helvetica Neue", "Arial", "DejaVu Sans"],
        "text.color": GREY_TEXT,
        "axes.labelcolor": GREY_TEXT,
        "xtick.color": GREY_TEXT,
        "ytick.color": GREY_TEXT,
        "figure.facecolor": "white",
        "axes.facecolor": GREY_BG,
    })


def _style_axes(ax, max_val):
    for side in ("top", "right", "left"):
        ax.spines[side].set_visible(False)
    ax.spines["bottom"].set_color(GREY_LINE)
    ax.tick_params(length=0)
    ax.set_axisbelow(True)
    ax.xaxis.grid(True, color=GREY_LINE, linewidth=1, alpha=0.7)
    ax.set_xlim(0, max_val * 1.18)


def _bar_colors(n):
    """Dark blue, with the top (worst) bar highlighted in brand orange.
    Rows are reversed before plotting, so the last entry is the top bar."""
    cols = [DARK_BLUE] * n
    if n:
        cols[-1] = ORANGE
    return cols


def _fmt_money(v):
    return f"{v:,.0f} {CURRENCY}".strip()


def _new_fig(n_rows):
    _apply_brand_style()
    fig, ax = plt.subplots(figsize=(9, max(2.6, 0.62 * n_rows + 1.2)))
    return fig, ax


def _save(fig, out):
    fig.tight_layout()
    fig.savefig(out, dpi=150, bbox_inches="tight", facecolor=fig.get_facecolor())
    plt.close(fig)


# ─────────────────────────────────────────────────────────────────────────
# Charts
# ─────────────────────────────────────────────────────────────────────────

def chart_high_risks(data, top_n=TOP_N):
    rows = [r for r in data if r.get("high_risks", 0) > 0]
    if not rows:
        print('High-risk chart: no initiatives have any "4. High" risks — chart skipped.')
        return None
    rows.sort(key=lambda r: r["high_risks"], reverse=True)
    rows = rows[:top_n]
    rows.reverse()  # highest at the top of a horizontal bar chart

    names = [r["initiative"] for r in rows]
    counts = [r["high_risks"] for r in rows]

    fig, ax = _new_fig(len(rows))
    bars = ax.barh(names, counts, height=0.62, color=_bar_colors(len(rows)))
    ax.set_title('Initiatives by number of "4. High" risks',
                 loc="left", color=BLACK, fontsize=14, fontweight="medium", pad=14)
    ax.set_xlabel("Open High (4) risks")
    _style_axes(ax, max(counts))
    for bar, c in zip(bars, counts):
        ax.text(bar.get_width() + max(counts) * 0.02,
                bar.get_y() + bar.get_height() / 2,
                str(c), va="center", fontweight="bold", color=GREY_TEXT)
    _save(fig, "high_risk_by_initiative.png")

    top = rows[-1]
    print(f'High-risk chart: {top["initiative"]} leads with '
          f'{top["high_risks"]} open High (4) risks.')
    return "high_risk_by_initiative.png"


def chart_overruns(data, top_n=TOP_N):
    rows = []
    for r in data:
        planned = r.get("planned") or 0
        actual = r.get("actual") or 0
        if planned <= 0:
            continue
        overrun = actual - planned
        rows.append({**r, "overrun": overrun, "pct": overrun / planned * 100.0})
    rows = [r for r in rows if r["overrun"] > 0]  # only initiatives over plan
    if not rows:
        print("Overrun chart: no initiatives are over plan — chart skipped.")
        return None
    rows.sort(key=lambda r: r["pct"], reverse=True)
    rows = rows[:top_n]
    rows.reverse()

    names = [r["initiative"] for r in rows]
    pcts = [r["pct"] for r in rows]

    fig, ax = _new_fig(len(rows))
    bars = ax.barh(names, pcts, height=0.62, color=_bar_colors(len(rows)))
    ax.set_title("Initiatives by budget overrun",
                 loc="left", color=BLACK, fontsize=14, fontweight="medium", pad=14)
    ax.set_xlabel("% over plan")
    _style_axes(ax, max(pcts))
    for bar, r in zip(bars, rows):
        ax.text(bar.get_width() + max(pcts) * 0.02,
                bar.get_y() + bar.get_height() / 2,
                f"+{r['pct']:.0f}%   {_fmt_money(r['overrun'])}",
                va="center", fontweight="bold", color=GREY_TEXT)
    _save(fig, "budget_overrun_by_initiative.png")

    top = rows[-1]
    print(f"Overrun chart: {top['initiative']} is worst at +{top['pct']:.0f}% "
          f"({_fmt_money(top['overrun'])} over plan).")
    return "budget_overrun_by_initiative.png"


def chart_phase_composition(data, top_n=TOP_N):
    """Fallback: portfolio composition by phase. Neutral (no worst-bar highlight)."""
    rows = [r for r in data if r.get("count", 0) > 0]
    if not rows:
        print("Phase chart: no initiatives in scope — chart skipped.")
        return None
    rows.sort(key=lambda r: r["count"], reverse=True)
    rows = rows[:top_n]
    rows.reverse()

    names = [r["phase"] for r in rows]
    counts = [r["count"] for r in rows]

    fig, ax = _new_fig(len(rows))
    bars = ax.barh(names, counts, height=0.62, color=DARK_BLUE)  # neutral composition
    ax.set_title("Initiatives by phase",
                 loc="left", color=BLACK, fontsize=14, fontweight="medium", pad=14)
    ax.set_xlabel("Initiatives")
    _style_axes(ax, max(counts))
    for bar, c in zip(bars, counts):
        ax.text(bar.get_width() + max(counts) * 0.02,
                bar.get_y() + bar.get_height() / 2,
                str(c), va="center", fontweight="bold", color=GREY_TEXT)
    _save(fig, "phase_composition.png")

    print(f"Phase chart (fallback): {len(rows)} phases; "
          f"largest is {rows[-1]['phase']} ({rows[-1]['count']}).")
    return "phase_composition.png"


if __name__ == "__main__":
    produced = [p for p in (chart_high_risks(HIGH_RISK_DATA),
                            chart_overruns(OVERRUN_DATA)) if p]
    if not produced:  # fallback so the summary always has at least one visual
        p = chart_phase_composition(PHASE_DATA)
        if p:
            produced.append(p)
    print("Charts written:", ", ".join(produced) if produced
          else "none — no qualifying data.")
