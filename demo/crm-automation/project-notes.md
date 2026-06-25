# CRM & Automation Modernisation — Project Notes

**Project Manager:** James Okafor
**Sponsor:** Sarah Mitchell (VP Sales)
**Start date:** 7 April 2026
**Target go-live:** 7 November 2026
**Budget:** €480,000
**Current forecast:** €512,000 (SAP integration overrun +€35k; contingency partially absorbed)

---

## Scope Summary

1. **CRM Migration** — Salesforce → Dynamics 365 Sales. ~47k accounts, ~210k contacts, activity history from 2022 onwards.
2. **Lead-to-Quote Automation** — Power Automate flow replacing manual handoff between Sales and Finance. Triggers on "Qualified" lead, auto-creates quote draft and notifies Finance.
3. **SAP Integration** — Dynamics ↔ SAP Business One via Innotek middleware. Syncs quotes, orders, and invoicing status. Custom pricing engine required async middleware layer (added April scope).

---

## Key Decisions Log

| Date | Decision |
|------|----------|
| 7 Apr 2026 | Go-live target confirmed: 7 November 2026 |
| 18 Apr 2026 | SAP integration partner selected: Innotek Solutions |
| 9 May 2026 | Deduplication of Salesforce contacts to be done pre-migration (4-day delay accepted) |
| 9 May 2026 | Activity history: full fidelity 2022–present; summarised count for 2017–2021 |
| 14 May 2026 | SAP scope increase logged as formal risk; CFO briefed |
| 22 Aug 2026 | iOS PCF fallback accepted as post-go-live iteration if not resolved by Sept 19 |

---

## Team

| Name | Role |
|------|------|
| Sarah Mitchell | Project Sponsor (VP Sales) |
| James Okafor | Project Manager |
| Lena Bergström | Lead Architect / Technical Lead |
| Tom Harding | Sales Operations Lead |
| Priya Nair | IT Lead |
| Dan Kowalski | Change Manager |
| Rachel Donovan | UAT Lead |
| Marcus Webb | Sales Ambassador (Change Champion) |
| Innotek Solutions | SAP Integration Partner |

---

## Risks

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|-----------|--------|-----------|
| R1 | SAP middleware delay | Medium | High | Async pattern implemented Aug 2026; float in schedule used |
| R2 | User adoption — legacy Salesforce users resistant to change | Medium | Medium | Ambassador programme, June preview sessions, training Oct 2026 |
| R3 | Data quality issues post-migration | Low | High | Pre-migration dedup; data validation sprint in Phase 1 |
| R4 | iOS mobile rendering (PCF) | Low | Low-Medium | Fallback to native canvas if not fixed; desktop unaffected |

---

## Open Questions (as of Aug 2026)

- Will the lead scoring card be fixed for iOS before go-live, or will we ship with a simplified view?
- Has the CFO formally approved the €35k SAP overrun into contingency?
- Training schedule for October — are all 140 users booked?

---

## Milestones

| Milestone | Target | Status |
|-----------|--------|--------|
| Project kickoff | 7 Apr 2026 | ✅ Complete |
| Sandbox provisioned | 14 Apr 2026 | ✅ Complete |
| SAP partner signed | 18 Apr 2026 | ✅ Complete |
| Data mapping complete | 30 Apr 2026 | ✅ Complete |
| Process workshops complete | 23 May 2026 | ✅ Complete |
| Build phase start | 2 Jun 2026 | ✅ Complete |
| UAT start | 8 Aug 2026 | ✅ Complete |
| UAT complete | 19 Sep 2026 | 🔄 In progress |
| Training complete | 31 Oct 2026 | ⬜ Not started |
| Go-live | 7 Nov 2026 | ⬜ Not started |
