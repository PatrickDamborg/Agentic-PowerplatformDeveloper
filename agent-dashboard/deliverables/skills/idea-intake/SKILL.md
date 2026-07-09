---
name: idea-intake
description: 'Interview a requester, check for duplicates, propose a strategy-linked idea, and create it in xPM after explicit approval. Load when the user wants to submit/propose/capture a NEW idea, suggest a project, log a proposal, or qualify an early request — phrases like "I have an idea", "I want to propose", "can we look into", "new initiative request". Do NOT load to summarize, report on, gather documents for, or analyse resources for an existing project — those are other skills. This is the ONE task with no existing entity to resolve: it creates a new record. Writes one row to pum_Idea, only after the user approves the proposed record.'
---

# Idea Intake and Qualification

Interview the requester (max 3 questions), check for duplicates, propose a strategy-linked `pum_Idea`, and save it only after explicit approval.

> Guardrails, approval rules, and Dataverse tool discipline are in the agent instructions. Data-model details: `dataverse-mcp`. This skill is the **exception to entity-first** — there is no existing entity; you are creating one.

---

## Step 1 — Interview (max 3 questions)

Stay in character as an intake assistant. Ask at most three focused questions; combine where possible; skip any the user already answered.

1. **Problem / opportunity** — "What problem does this solve, or what opportunity does it open?"
2. **Expected value** — "What is the benefit — cost saving, revenue, risk reduction, new capability?"
3. **Urgency** — "Is there a deadline or strategic window that makes this time-sensitive?"

Do not ask about technology, implementation, or budget — this is qualification, not scoping. Then go to Step 2.

---

## Step 2 — Duplicate check (before proposing)

```
search_data(query: "<key phrase from the title or problem>", table: "pum_Idea")
```
Run one or two searches with different keyword combinations.

**Duplicates found** — show them and stop for a decision:
> "I found [N] existing idea(s) that may overlap:
> | Title | Created | Status |
> |---|---|---|
> Proceed with a new idea, review one of these, or extend an existing one?"

**No duplicates** — go to Step 3.

---

## Step 3 — Discover strategy context, then propose

Ground the alignment in real records before proposing:

```sql
SELECT pum_investmentcategoryid, pum_name FROM pum_InvestmentCategory ORDER BY pum_name
```
```sql
SELECT pum_strategicobjectivesid, pum_name, pum_description FROM pum_StrategicObjectives ORDER BY pum_name
```

Choose the best-fit `pum_InvestmentCategory` (Business Driver) and `pum_StrategicObjectives`, and **show your reasoning**. Then present:

```
IDEA RECORD PROPOSAL
Title:               [concise noun-phrase]
Description:         [2–4 sentences from the user's answers]
Business Driver:     [InvestmentCategory name] — because [reason]
Strategic Objective: [StrategicObjective name] — because [reason]
Strategy link:       "Supports [Objective] via [Driver] — it enters the funnel already aligned."
```

The strategy link is the wow moment: it shows the agent understands organisational priorities, not just the idea text. Ask: **"Shall I create this idea record in xPM?"**

**Choosing the best fit:** prefer the objective whose name most directly matches the stated value, and the driver that best describes the initiative's nature; if two are equally plausible, pick the less crowded pipeline and say why. Always cite the reason — an unexplained guess undermines trust.

---

## Step 4 — Create on explicit approval

Only on an unambiguous "yes":

```
create_record(table: "pum_Idea", body: {
  "pum_name": "<title>",
  "pum_description": "<description>",
  "pum_InvestmentCategory@odata.bind": "/pum_investmentcategories(<guid>)",
  "pum_PrimaryObjective@odata.bind":   "/pum_strategicobjectives(<guid>)"
})
```
Use the IDs discovered in Step 3 — never hardcode GUIDs. After saving, return the record name and where to find it: "in xPM under the Idea list, available for review and prioritisation."

---

## Edge cases

| Situation | Action |
|-----------|--------|
| One-word idea | Run the three interview questions first |
| No Investment Categories exist | Omit that binding; note it; tell the user to add categories in xPM |
| No Strategic Objectives exist | Omit that binding; flag the missing strategy layer |
| User wants to extend a duplicate | Switch to `update_record` on the existing record, after the same approval; surface it first |
| User declines all duplicates, wants new | Create it; note in the description that similar ideas exist (by name) |
