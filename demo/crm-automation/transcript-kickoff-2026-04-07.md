# Meeting Transcript — Project Kickoff
**Project:** CRM & Automation Modernisation
**Date:** 7 April 2026
**Time:** 09:00–10:30
**Location:** Microsoft Teams
**Attendees:** Sarah Mitchell (Project Sponsor), James Okafor (Project Manager), Lena Bergström (Lead Architect), Tom Harding (Sales Operations), Priya Nair (IT Lead), Dan Kowalski (Change Manager)

---

**Sarah Mitchell (09:02):**
Good morning everyone. Glad we're finally kicking this off — we've been talking about replacing Salesforce for over a year now. The board signed off on the budget last month, so we're officially go. James, can you set the scene?

**James Okafor (09:04):**
Absolutely. So the project has three main workstreams. First, migrating our CRM data from Salesforce to Dynamics 365 Sales. Second, automating the lead-to-quote process using Power Automate — right now that involves a lot of manual handoffs between Sales and Finance. Third, integrating the new CRM with our ERP system, which is SAP Business One. We've got a 7-month timeline, go-live is targeted for 7 November.

**Lena Bergström (09:07):**
I want to flag early that the SAP integration is the highest-risk item. We haven't done a full data mapping exercise yet, and SAP Business One's API has some quirks. I'd recommend we front-load that discovery in Phase 1.

**Tom Harding (09:10):**
From Sales Ops perspective, the number one ask is that the lead scoring model comes across correctly. We've built a lot of custom scoring logic in Salesforce over the years. I'd like to make sure we're not just migrating fields — we're migrating the logic.

**Priya Nair (09:13):**
Agreed. And on the automation side — we should be careful about replicating bad processes. Some of the current flows in Salesforce are workarounds for things Dynamics does natively. Can we do a process review before we start building flows?

**James Okafor (09:15):**
That's on the plan. We have a two-week process workshop in Phase 1 — week two of May. Priya, I'd like you and Tom to co-lead that.

**Priya Nair (09:16):**
Works for me.

**Dan Kowalski (09:17):**
Change management — I want to raise this now because it always gets left to the end. We have around 140 users who will switch from Salesforce to Dynamics. Some of them have been on Salesforce for ten years. Training and comms need to start early. I'd suggest we run an ambassador programme — identify five or six power users from the Sales team who can be our internal champions.

**Sarah Mitchell (09:20):**
Fully support that. Dan, can you identify candidates by end of April?

**Dan Kowalski (09:21):**
I'll have a shortlist by April 25th.

**James Okafor (09:23):**
Let me walk through the high-level phases quickly.

- **Phase 1 (April–May):** Discovery — process workshops, data mapping, SAP integration scoping, environment setup
- **Phase 2 (June–July):** Build — Dynamics configuration, Power Automate flows, SAP connector development
- **Phase 3 (August–September):** Testing — UAT with Sales Ops, integration testing, performance testing
- **Phase 4 (October):** Training and cutover preparation
- **Phase 5 (November):** Go-live and hypercare

**Lena Bergström (09:27):**
One question on environment — are we getting a dedicated Dynamics sandbox, or sharing the existing one?

**Priya Nair (09:29):**
I've requested a dedicated sandbox. IT should have it provisioned by April 14th.

**Sarah Mitchell (09:31):**
Good. I want weekly steering updates — James, can you send those to myself, CFO, and the Head of Sales every Friday?

**James Okafor (09:32):**
Will do. I'll use the xPM status reporting module for that — you'll get a structured update with traffic lights on cost, schedule, and scope.

**Sarah Mitchell (09:34):**
Perfect. Any other blockers before we close?

**Lena Bergström (09:35):**
We still need to confirm the SAP integration partner. I know we're talking to two vendors — can we get a decision by April 21st so we're not blocked?

**Sarah Mitchell (09:36):**
I'll chase procurement. I'll aim to have a decision by the 18th.

**James Okafor (09:37):**
Great. I'll send out the action log after this. Thanks everyone.

---

## Action Items

| # | Action | Owner | Due |
|---|--------|-------|-----|
| 1 | Provision dedicated Dynamics 365 sandbox | Priya Nair | 14 Apr 2026 |
| 2 | Identify change ambassador candidates (shortlist of 5–6) | Dan Kowalski | 25 Apr 2026 |
| 3 | Confirm SAP integration partner | Sarah Mitchell | 18 Apr 2026 |
| 4 | Begin data mapping exercise for Salesforce → Dynamics migration | Lena Bergström | 30 Apr 2026 |
| 5 | Schedule process workshop (lead-to-quote flow review) | James Okafor / Priya Nair | 12 May 2026 |
| 6 | Send weekly steering update template to Sarah / CFO / Head of Sales | James Okafor | 11 Apr 2026 |
