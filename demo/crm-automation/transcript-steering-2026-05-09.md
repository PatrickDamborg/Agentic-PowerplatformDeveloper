# Meeting Transcript — Steering Committee Update #1
**Project:** CRM & Automation Modernisation
**Date:** 9 May 2026
**Time:** 09:00–09:45
**Location:** Microsoft Teams
**Attendees:** Sarah Mitchell (Sponsor), James Okafor (PM), Lena Bergström (Lead Architect), Tom Harding (Sales Ops), Dan Kowalski (Change Manager)
**Apologies:** Priya Nair (IT Lead) — represented by James

---

**James Okafor (09:01):**
Morning all. Quick status before we dive in — overall we're green on schedule, but I want to flag a yellow on scope. Let me go through each area.

**Data migration** — Lena's team completed the initial Salesforce data audit. We have 47,000 account records, 210,000 contact records, and about 380,000 activity records going back to 2017. The good news is the data quality is better than expected. The concern is that about 12% of contact records have duplicate entries — we need to decide whether we deduplicate before migration or after.

**Lena Bergström (09:04):**
My recommendation is before. It's much harder to clean up duplicates once they're in Dynamics and users have started working with them. I've scoped a two-day deduplication sprint — it would push our data migration start by four days, but I think it's worth it.

**James Okafor (09:06):**
Sarah, can I get your sign-off on that call?

**Sarah Mitchell (09:07):**
Agreed. Clean data going in is non-negotiable. Do the deduplication first.

**Tom Harding (09:08):**
Can I ask — what happens to the activity history? Ten years of call logs and emails is important for the Sales team. I don't want reps landing in Dynamics with no context on their accounts.

**Lena Bergström (09:10):**
We're bringing across everything from 2022 onwards in full fidelity. For 2017–2021 we'll migrate a summarised activity count per account. Dynamics has storage limits and the old activity format doesn't map cleanly. That was agreed in the data mapping workshop last week — Tom, were you not at that one?

**Tom Harding (09:12):**
I sent a delegate — I didn't realise that decision was being made. I'd like to revisit it. Five years of history is significant.

**James Okafor (09:14):**
Noted. Let's take that offline after this call. Lena and Tom — can you align and come back to me by Wednesday with a recommendation?

**Lena Bergström / Tom Harding (09:14):**
Agreed.

**James Okafor (09:15):**
SAP integration — this is the yellow flag. We signed the contract with Innotek Solutions on April 18th. Their discovery session was last week. Their initial scoping came in 20% higher in effort than we budgeted. Specifically, the quote-sync process is more complex because SAP Business One uses a custom pricing engine that doesn't have a standard API endpoint. Innotek are proposing a middleware layer.

**Sarah Mitchell (09:19):**
What does that mean for cost and timeline?

**James Okafor (09:20):**
Potentially €35k additional cost and a 3-week delay to the integration workstream. It doesn't affect go-live yet because SAP integration is on the critical path but has some float. I'll have a clearer picture by end of next week.

**Sarah Mitchell (09:22):**
Flag it as a formal risk. I'll speak to the CFO. Keep me posted.

**Dan Kowalski (09:23):**
Change update — ambassador programme is in good shape. We have six confirmed champions: two from inside Sales, one from Account Management, one from Finance, and two from the regional teams. First ambassador session is May 20th. We're also planning a "Dynamics preview" session for all 140 users in late June — a 90-minute walk-through before UAT opens up.

**Sarah Mitchell (09:27):**
Good. What's the sentiment like from the Sales team?

**Dan Kowalski (09:28):**
Mixed, honestly. The older reps are nervous about change. The younger ones are excited about the automation — especially the lead-to-quote flow removing the manual handoff with Finance. We're leaning into that in our comms.

**James Okafor (09:31):**
One more thing — Priya has confirmed the sandbox is live and the core Dynamics Sales configuration has started. First sprint review for the Build phase is June 6th.

**Sarah Mitchell (09:33):**
Good progress. James, make sure the SAP risk is in the next weekly report with a mitigation plan.

**James Okafor (09:34):**
Will do. Thanks everyone.

---

## Decisions Made

| # | Decision | Made by |
|---|----------|---------|
| 1 | Deduplicate Salesforce contacts before migration (4-day delay accepted) | Sarah Mitchell |
| 2 | SAP scope increase to be raised as formal risk | James Okafor |

## Action Items

| # | Action | Owner | Due |
|---|--------|-------|-----|
| 1 | Align on activity history migration scope (2017–2021) | Lena Bergström + Tom Harding | 13 May 2026 |
| 2 | Formal risk log entry for SAP scope increase + mitigation plan | James Okafor | 15 May 2026 |
| 3 | Update budget forecast with SAP overrun scenario | James Okafor | 16 May 2026 |
| 4 | Confirm Dynamics preview session date for all users | Dan Kowalski | 20 May 2026 |
