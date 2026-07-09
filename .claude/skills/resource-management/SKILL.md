---
name: resource-management
description: |
  Reference knowledge for resource management — process, terminology, stakeholder
  needs, common customer pitfalls, and consulting-grade responses. Grounded in
  Context& Level 100 material.
  Use when the user asks about resource management concepts, definitions
  (generic/named/category resources, RBS, capacity, demand vs supply),
  stakeholder roles (portfolio manager, line manager, project manager, resource),
  why RM implementations fail, customer red-flag phrases, or how to respond as a
  consultant. Also load as background knowledge when other skills/agents need RM
  context.
  Do NOT use for: technical setup of Team Planner / Resource Planner (different
  scope), time tracking / Time for Teams (that's history, not RM), or task-level
  booking management.
cowork:
  category: research
  icon: Book
---

# Resource Management Reference

## What it is (and what it isn't)

Resource management = supply and demand for people: who's doing what, when, and
how many we need looking forward. Always future-facing — not history.

Frequently confused with — and **distinct from**:
| Discipline | What it does | Why it's not RM |
|---|---|---|
| Project management | Plans what's delivered and when | Not about resource availability |
| Work / booking / task management | Who does which task | Too detailed; RM stays at higher level |
| Time tracking (Time for Teams) | Records what already happened | RM looks forward |

## Why customers ask for it

Most common entry point: **"We don't know what new intake we can take on"** — no
visibility into capacity, can't forecast hiring (especially for specialised
roles needing 6–9 months lead time). Secondary entry: people overworked, sick
leaves, unclear prioritisation when resource conflicts arise.

Top benefit (often forgotten): **employee satisfaction** — preventing burnout
is cheaper than rehiring.

## Why it fails (and what to push on early)

| Failure mode | What to raise with the customer up front |
|---|---|
| People overworked from constant fire-fighting | Build awareness into the process; can't plan ahead while reacting |
| Estimates uncertain | Who does initial estimates? Is their time blocked? Manage expectations on data accuracy — start rough, refine |
| No prioritisation when resources conflict | Define the escalation ladder: PM → PMO → VP. Can resources self-accept? |
| Detail vs big picture tension | Different stakeholders want different things — align expectations |
| Non-project work invisible | Plan at 100% capacity so vacation, internal work, ERP, management time all show |
| Process too complicated | Map swim lanes per persona per cadence (week/month/quarter) |

## Key concepts

**Resource types**
- **Generic resource** = RBS + role (e.g. R&D Agile Practice + Scrum Master).
  Used for **demand** — what's being requested.
- **Named resource** = an actual person. Used for **supply** — answers a generic
  request. Limited capacity.
- **Category resource** = unlimited-capacity placeholder for "I see your
  request, but no named answer yet" — new hire, external, or rejected request.
  Enables tracking.

If a case doesn't fit these three, you're outside the bullseye — discuss with
the RM group.

**Skills on resources**: only recommended when domain-critical (e.g.
certifications for medical/regulated work). Otherwise the maintenance burden
isn't worth it — communication between PM and resource owner covers it.

**RBS** (Resource Breakdown Structure): org hierarchy used to route requests to
the right manager. Combined with Role to form a generic resource. Long-term
direction is to simplify to roles + managers, but RBS is current standard.

**Capacity**
- Default 100% (e.g. 7.4 hr/day in DK), adjusted for part-time.
- Fluctuates monthly — public holidays matter (Sep ≫ Dec workdays).
- Split into: non-project work, running projects, free capacity (for pipeline).
- Plan **requests** as far out as possible; **allocations** only 3–6 months out
  (people leave, get sick, take vacation).

**The two graphs that justify RM existing**
1. Project demand vs capacity — pipeline + running projects against available
   hours. Tells you: hire, defer pipeline, or both.
2. Project supply by role — for each role/generic resource, how loaded are
   people. Tells you: where the bottlenecks are.

## Stakeholders — what each one needs

| Stakeholder | Primary needs |
|---|---|
| Portfolio manager | Headcount, bottlenecks, utilisation %, pipeline intake capacity |
| Project manager | Resources to execute; help with initial estimates |
| Line manager / resource owner | Balance workload, prevent over/underuse, spot stress early, avoid "favourite resource" patterns |
| Resource (employee) | Know what they're working on this week, work-life balance, autonomy to flag overload |

Treat these as different audiences with different views — not one universal
report.

## Customer red flags → consultant responses

When a customer says one of these, **pause** before agreeing:

| Customer says | Read this as | Response direction |
|---|---|---|
| "Just implement it, there's a standard process" | Underestimating change management | RM is a process problem; tool follows process |
| "We need to track every task in detail" | Confusing RM with work/booking management | Higher-level forecasting, not task booking |
| "We'll figure out the process as we go" | High failure risk | Define swim lanes, cadence, escalation ladder up front |
| "It's too administratively heavy" | Usually how they're using it, not the tool | Review process, not just config |
| "We need to plan on days" | Wrong granularity | Plan at week/month — daily is booking, not RM |
| "We only need high-level capacity" | Will miss bottlenecks | Need both demand and supply views |

The consultant's job: validate and challenge the ask, not just implement it.
Saying "no, not that way" is part of the value.

## When loaded as background knowledge

Other skills/agents can rely on this for:
- Definitions (generic/named/category, RBS, capacity, demand vs supply)
- Stakeholder framing for any RM-adjacent comms or document
- Spotting customer anti-patterns in meeting notes / emails / requirements docs
- Sanity-checking proposals against the failure modes above

## Out of scope

- Team Planner / Resource Planner technical configuration → separate Level 200
- Time for Teams / time tracking → that's history, not RM
- Day-to-day booking management → use a booking tool

## Internal contacts

The RM group (Peter, Glen, Cecilie) meets ~monthly. Reach out for non-trivial
scenarios, cases that fall outside the three resource types, or when a customer
ask doesn't sit right.
