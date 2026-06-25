# Meeting Transcript — UAT Review Session
**Project:** CRM & Automation Modernisation
**Date:** 22 August 2026
**Time:** 13:00–14:15
**Location:** Microsoft Teams
**Attendees:** James Okafor (PM), Lena Bergström (Lead Architect), Tom Harding (Sales Ops), Priya Nair (IT Lead), Rachel Donovan (UAT Lead), Marcus Webb (Sales Ambassador)
**Absent:** Sarah Mitchell, Dan Kowalski

---

**James Okafor (13:01):**
Let's get into it. Rachel, you've been running UAT for two weeks now — what's the picture?

**Rachel Donovan (13:02):**
Overall, UAT is progressing well. We've completed 68% of test cases. Pass rate is 84%. The main issues are concentrated in three areas: the lead-to-quote automation, account data visibility, and mobile.

Starting with lead-to-quote — the Power Automate flow is triggering correctly, but there's a timing issue. When a rep marks a lead as "Qualified", the quote draft in Dynamics takes up to 8 minutes to appear. The business expectation was near-instant. Tom, your team flagged this as a blocker.

**Tom Harding (13:06):**
It's a real problem. Reps are refreshing the screen, thinking something broke. We need it under 60 seconds.

**Lena Bergström (13:08):**
I've looked at this. The delay is in the SAP price fetch — the middleware is doing a synchronous call and waiting for SAP to respond before completing the flow. We can switch to an async pattern with a notification when the quote is ready. That's roughly a day of dev work.

**James Okafor (13:10):**
Let's do it. Lena, can that be done by end of next week?

**Lena Bergström (13:11):**
Yes, I'll have it in the UAT environment by August 28th.

**Rachel Donovan (13:12):**
Second issue — account data visibility. Several testers in Account Management can't see account records they own. It turns out the security role assignment wasn't applied to about 23 users during migration. Priya, this is in your team's court.

**Priya Nair (13:15):**
We found the root cause yesterday. The migration script had a null-check bug on the territory field — users without a territory assigned got dropped from the role mapping. We've fixed the script. Re-running the role assignment for the affected users tonight. Should be resolved by tomorrow morning.

**Rachel Donovan (13:17):**
Great. The third area is mobile. The Dynamics mobile app isn't rendering the custom lead scoring card correctly on iOS — it shows a blank panel. Android is fine. Marcus, your ambassadors have all iOS devices.

**Marcus Webb (13:20):**
Yeah, that's a pain. The lead scoring view is one of the things people were most excited about. If it's broken on iOS on go-live day, it's going to create a bad first impression.

**Lena Bergström (13:22):**
This is a known Dynamics mobile limitation with certain PCF controls. The scoring card uses a custom PCF component. I'll check whether there's a mobile-compatible fallback or if we need to redesign it as a native canvas section.

**James Okafor (13:25):**
What's the risk to go-live if this isn't fixed?

**Lena Bergström (13:26):**
It's cosmetic but visible. I'd say medium risk. I'll give you a proper assessment by Monday. Worst case, we ship with a simplified scoring view on mobile and iterate post-go-live.

**Tom Harding (13:28):**
I can live with that if the desktop view is solid. Most of the heavy users are desktop anyway.

**James Okafor (13:30):**
Okay. Let's track that as a risk with a mitigation. Rachel, what's the plan for completing the remaining 32% of test cases?

**Rachel Donovan (13:32):**
We have three more test cycles planned — September 5th, 12th, and 19th. If the lead-to-quote fix and the security role issue are resolved by end of next week, I'm confident we hit 95%+ pass rate by September 19th. The remaining test cases are lower risk — reporting views and admin functions.

**James Okafor (13:35):**
Good. I'll update the project status to yellow — we're not in trouble but these issues need to close cleanly. I'll brief Sarah this afternoon.

---

## Issues Log Update

| # | Issue | Severity | Owner | Target Resolution |
|---|-------|----------|-------|------------------|
| UAT-01 | Lead-to-quote flow delay (>8 min) | High | Lena Bergström | 28 Aug 2026 |
| UAT-02 | Security role assignment missing for 23 users | High | Priya Nair | 23 Aug 2026 |
| UAT-03 | Lead scoring card blank on iOS mobile | Medium | Lena Bergström | Assessment 25 Aug; fix TBC |

## Action Items

| # | Action | Owner | Due |
|---|--------|-------|-----|
| 1 | Async refactor of lead-to-quote flow (SAP price fetch) | Lena Bergström | 28 Aug 2026 |
| 2 | Re-run security role assignment for 23 affected users | Priya Nair | 23 Aug 2026 |
| 3 | iOS PCF assessment — fix or fallback decision | Lena Bergström | 25 Aug 2026 |
| 4 | Brief Sarah Mitchell on UAT status and risk update | James Okafor | 22 Aug 2026 (today) |
| 5 | Update project status to Yellow in xPM | James Okafor | 22 Aug 2026 |
