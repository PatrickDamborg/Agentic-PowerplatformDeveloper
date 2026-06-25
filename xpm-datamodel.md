---
name: xPM Essentials data model
description: Full pum_ table inventory and relationship map for the Projectum xPM Essentials solution installed in pdausa. Use when building features that read/write Dataverse tables.
type: project
originSessionId: b18b31b3-0889-4d94-b4a9-399e595edda7
---
All solutions installed in pdausa as of 2026-04-21:
PowerRoadmap 2.10.15, PumPowerGanttSolution 4.3.0, PowerMatrix 2.2.4, PowerUX 1.6.3,
PowerFinancialsSolution 3.17.0, PowerBoard 2.11.0, PowerPPMEssentials 4.0.1,
ResourcePlan 1.0.0.31, PowerHeatmap 2.0.27

Total pum_ tables: 77

---

## Core PPM Hierarchy

| Table | Display Name | Key Lookups |
|-------|-------------|-------------|
| pum_StrategicObjectives | Strategic Objective | Lead (SystemUser) |
| pum_KeyResults | Key Result | pum_StrategicObjectives |
| pum_InvestmentCategory | Business Driver | — (catalog) |
| pum_Portfolio | Portfolio | pum_PrimaryObjective (StrategicObjectives) |
| pum_PortfolioAlignment | Portfolio Alignment | pum_Portfolio, pum_Category (InvestmentCategory) |
| pum_Program | Program | pum_Portfolio, pum_KeyResults, pum_Category, pum_Sponsor (SystemUser), Read/Write Teams |
| pum_Initiative | Initiative | pum_Program, pum_Portfolio, pum_KeyResults, pum_Category, pum_LinkedIdea, pum_Sponsor, Read/Write Teams |
| pum_Idea | Idea | pum_Portfolio, pum_Category, pum_PrimaryObjective (StrategicObjectives), pum_LinkedInitiative |

OKR chain: StrategicObjectives → KeyResults → Portfolio (via PrimaryObjective)
Work funnel: Idea → Initiative (LinkedIdea/LinkedInitiative) → Program → Portfolio

---

## Scheduling / Gantt

| Table | Display Name | Key Lookups |
|-------|-------------|-------------|
| pum_GanttVersion | Gantt Version | — |
| pum_GanttTask | Gantt Task | pum_GanttVersion, pum_initiative, pum_program, pum_portfolio, pum_WorkPackage, pum_SystemUser, pum_PowerGanttTemplate, pum_OriginalTaskId_Version |
| pum_WorkPackage | Work Package | pum_Initiative |
| pum_Dependency | Dependency | pum_From (SystemUser), pum_To (SystemUser) |
| pum_TaskLink | Task Link | — |
| pum_Assignment | Assignment | pum_AssTask (GanttTask), pum_Initiative, pum_Program1, pum_Portfolio1, pum_Resource, pum_User (SystemUser) |
| pum_LessonsLearned | Lessons Learned | pum_Initiative, pum_Task (GanttTask) |

GanttTask has 3 baselines (baseline1–5), WBS, sort order, constraint/deadline fields, and Kanban status.
GanttTask links directly to Initiative/Program/Portfolio — schedule is owned at any hierarchy level.

---

## Resource Management

| Table | Display Name | Key Lookups |
|-------|-------------|-------------|
| pum_rbs | RBS | pum_ParentName (self — hierarchy) |
| pum_Role | Role | — (catalog) |
| pum_Calendar | Calendar | — |
| pum_NationalHoliday | National Holiday | — |
| pum_Resource | Resource | pum_Calendar, pum_Role, pum_RBS, pum_RelatedUser (SystemUser), pum_Manager (Resource), pum_RelatedGenericResource (Resource) |
| pum_TeamMembers | Team Member | pum_Resource, pum_Initiative, pum_Program |
| pum_Stakeholder | Stakeholder | pum_Initiative, pum_Program, pum_UserInternal (SystemUser) |
| pum_ResourcePlan | Resource Plan | pum_Idea, pum_Initiative, pum_Program, pum_Portfolio |
| pum_Propose | Proposal | pum_ResourcePlan, pum_Resource, pum_Idea, pum_Initiative, pum_Program, pum_Portfolio |
| pum_Commit | Commit | pum_ResourcePlan, pum_Resource, pum_Idea, pum_Initiative, pum_Program, pum_Portfolio |

Propose = proposed allocation; Commit = committed allocation. Both share identical structure and hang off a ResourcePlan header.

---

## Governance / Reporting

| Table | Display Name | Key Lookups |
|-------|-------------|-------------|
| pum_Risk | Risk | pum_Initiative, pum_Program, pum_Portfolio |
| pum_StatusReporting | Status Reporting | pum_Initiative, pum_Program |
| pum_ChangeRequest | Change Request | pum_Initiative / pum_Program (assumed) |
| pum_Stakeholder | Stakeholder | pum_Initiative, pum_Program, pum_UserInternal |

StatusReporting has full KPI snapshot fields (KPINew*/KPICurrent* picklists for Cost/Quality/Resources/Schedule/Scope/Summary).

---

## Configuration Tables (one per app)

| Table | App |
|-------|-----|
| pum_DefaultConfig | System-wide defaults |
| pum_PowerGanttConfig | Power Gantt |
| pum_PowerGanttTemplate | Gantt Templates |
| pum_PowerBoardConfig | Power Board |
| pum_PowerRoadmapConfig | Power Roadmap |
| pum_PowerMatrixConfig | Power Matrix |
| pum_PowerMatrixData | Power Matrix |
| pum_PowerHeatmapConfig | Power Heatmap |
| pum_PowerUXConfig | Power UX |
| pum_powerfinancialsconfig | Power Financials |

---

## Financial Sub-model (pum_pf_*)

| Table | Display Name |
|-------|-------------|
| pum_pf_unit | Financial Unit |
| pum_pf_costtype | Cost Type PF |
| pum_pf_costarea | Cost Area PF |
| pum_pf_costcategory | Cost Category PF |
| pum_pf_fiscalperiod | Fiscal Periods PF |
| pum_pf_costplan_version | Cost Plan Version PF |
| pum_pf_costspecification | Cost Specification PF |
| pum_pf_customcolumndata | Custom Column Data |
| pum_pf_CustomRowData | Custom Row Data |
| pum_pf_powerfinancialsdata | Power Financials Data |
| pum_pf_powerfinancialscomment | Power Financials Comment |
| pum_FinancialStructure | Financial Structure |
| pum_CustomCostHierarchy | Custom Cost Hierarchy |
| pum_CostResource | Cost Resource |

---

## N:N Intersection Tables

- pum_FinancialStructure_pum_pf_costarea
- pum_FinancialStructure_pum_pf_costcateg
- pum_pf_costtype_pum_FinancialStructure
- pum_GanttTask_pum_GanttTeam
- pum_Ganttuser_pum_GanttTask
- pum_Ganttuser_pum_GanttTeam (deprecated)
- pum_RoadmapSwimlane_pum_Idea
- pum_RoadmapSwimlane_pum_Initiative
- pum_RoadmapSwimlane_pum_Program
- pum_KeyResults_SystemUser

---

## Deprecated Tables
- pum_GanttTeam, pum_Ganttuser — marked deprecated in display names

**Why:** Documented after full solution import on 2026-04-21 to support future feature development.
**How to apply:** Use these table/column names when writing Dataverse API queries, building flows, or authoring Copilot actions targeting xPM data.
