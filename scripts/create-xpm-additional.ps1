#!/usr/bin/env pwsh
# Creates additional xPM records per the user's request:
#   - Stakeholders (2-3 per initiative, covering all 12)
#   - Risks (additional, targeting under-covered initiatives)
#   - Change Requests (additional)
#   - Lessons Learned (additional)
#   - Dependencies (pum_dependency: initiative-to-initiative)

$ErrorActionPreference = 'Continue'
$root = "C:\Users\Patrick\Agentic-PowerplatformDeveloper"
Import-Module (Join-Path $root "helpers.psm1") -Force

$conn    = Initialize-DataverseConnection -EnvPath (Join-Path $root ".env")
$baseUrl = $conn.BaseUrl
$headers = $conn.Headers.Clone()
$headers["Prefer"] = "return=representation"

$script:ok  = 0
$script:err = 0

function Post-Record {
    param([string]$Set, [hashtable]$Body, [string]$IdField, [string]$Label)
    try {
        $json = $Body | ConvertTo-Json -Depth 10 -Compress
        $resp = Invoke-WebRequest -Method POST -Uri "$baseUrl/$Set" -Headers $headers -Body $json -UseBasicParsing
        if ($resp.Content) {
            $rec = $resp.Content | ConvertFrom-Json
            Write-Host "  [OK] $Label" -ForegroundColor Green
            $script:ok++
            return $rec.$IdField
        }
        $hdr = $resp.Headers.'OData-EntityId'
        if ($hdr -match '\(([^)]+)\)$') { $script:ok++; Write-Host "  [OK] $Label" -ForegroundColor Green; return $Matches[1] }
    } catch {
        $msg = $_.Exception.Message
        if ($_.ErrorDetails.Message) { try { $msg = ($_.ErrorDetails.Message | ConvertFrom-Json).error.message } catch {} }
        Write-Host "  [ERR] $Label" -ForegroundColor Red
        Write-Host "        $msg" -ForegroundColor DarkRed
        $script:err++; return $null
    }
}

# ── Initiative IDs ────────────────────────────────────────────────────────
$ini1  = "d6351a72-0a3f-f111-bec6-70a8a59a44c4"  # Customer Self-Service Portal
$ini2  = "f8351a72-0a3f-f111-bec6-70a8a59a44c4"  # Mobile App for Field Service
$ini3  = "18361a72-0a3f-f111-bec6-70a8a59a44c4"  # CRM Integration & Automation
$ini4  = "37361a72-0a3f-f111-bec6-70a8a59a44c4"  # Enterprise Data Lake Phase 1
$ini5  = "b7611778-0a3f-f111-bec6-70a8a59a44c4"  # Sales Forecasting ML Model
$ini6  = "52621778-0a3f-f111-bec6-70a8a59a44c4"  # Digital Onboarding Platform
$ini7  = "f5611778-0a3f-f111-bec6-70a8a59a44c4"  # ERP Assessment & Blueprint
$ini8  = "14621778-0a3f-f111-bec6-70a8a59a44c4"  # Finance Module Cloud Migration
$ini9  = "17154a7e-0a3f-f111-bec6-70a8a59a44c4"  # M365 Collaboration Rollout
$ini10 = "d6611778-0a3f-f111-bec6-70a8a59a44c4"  # Real-Time Analytics Dashboard
$ini11 = "71621778-0a3f-f111-bec6-70a8a59a44c4"  # Automated Compliance Reporting
$ini12 = "33621778-0a3f-f111-bec6-70a8a59a44c4"  # Supply Chain Module Implementation

# ── STAKEHOLDERS ──────────────────────────────────────────────────────────
# pum_stakeholdertype: 493840000=Informed 493840001=Supporter 493840002=Blocker
#                      493840003=Leader   493840004=Observer
# pum_stakeholderpower:  976880001=Low 976880002=Medium 976880003=High
# pum_stakeholderinterest: 976880001=Low 976880002=Medium 976880003=High
Write-Host "`n=== Stakeholders ===" -ForegroundColor Yellow

function New-Stakeholder {
    param($name,$iniId,$type,$influence,$interest)
    $body = @{
        pum_name            = $name
        pum_stakeholdertype = $type
        pum_influence       = $influence
        pum_interest        = $interest
        "pum_Initiative@odata.bind" = "/pum_initiatives($iniId)"
    }
    Post-Record "pum_stakeholders" $body "pum_stakeholderid" "Stakeholder: $name"
}

# Customer Self-Service Portal
New-Stakeholder "Emma Larsson" $ini1 493840000 493840003 493840003
New-Stakeholder "David Chen" $ini1 493840000 493840002 493840003
New-Stakeholder "Maria Santos" $ini1 493840000 493840002 493840002

# Mobile App for Field Service
New-Stakeholder "Jake Williams" $ini2 493840000 493840003 493840003
New-Stakeholder "Priya Nair" $ini2 493840000 493840001 493840003
New-Stakeholder "Tom Mueller" $ini2 493840000 493840002 493840002

# CRM Integration & Automation
New-Stakeholder "Sarah Mitchell" $ini3 493840000 493840003 493840003
New-Stakeholder "Carlos Rivera" $ini3 493840000 493840002 493840003
New-Stakeholder "Fiona Bradley" $ini3 493840000 493840001 493840002

# Enterprise Data Lake
New-Stakeholder "Robert Kim" $ini4 493840000 493840003 493840003
New-Stakeholder "Anita Patel" $ini4 493840000 493840002 493840003
New-Stakeholder "Lars Eriksson" $ini4 493840000 493840002 493840002

# Sales Forecasting ML
New-Stakeholder "James O'Brien" $ini5 493840000 493840003 493840003
New-Stakeholder "Dr. Lin Zhang" $ini5 493840000 493840001 493840003
New-Stakeholder "Nicole Beaumont" $ini5 493840000 493840002 493840002

# Digital Onboarding
New-Stakeholder "Michelle Harper" $ini6 493840000 493840003 493840003
New-Stakeholder "Ben Okafor" $ini6 493840000 493840002 493840003
New-Stakeholder "Sophie Laurent" $ini6 493840000 493840001 493840002

# ERP Assessment
New-Stakeholder "George Hoffman" $ini7 493840000 493840003 493840002
New-Stakeholder "Diana Walsh" $ini7 493840000 493840002 493840003
New-Stakeholder "Paul Svensson" $ini7 493840000 493840003 493840003

# Finance Module Migration
New-Stakeholder "Catherine Moore" $ini8 493840000 493840003 493840003
New-Stakeholder "Adam Fischer" $ini8 493840000 493840002 493840003
New-Stakeholder "Helena Johansson" $ini8 493840000 493840002 493840002
New-Stakeholder "Mark Thompson" $ini8 493840000 493840002 493840002

# M365 Collaboration
New-Stakeholder "Natasha Brooks" $ini9 493840000 493840003 493840002
New-Stakeholder "Oliver Grant" $ini9 493840000 493840001 493840003
New-Stakeholder "Yuki Tanaka" $ini9 493840000 493840002 493840002

# Real-Time Analytics Dashboard
New-Stakeholder "Simon Clarke" $ini10 493840000 493840003 493840003
New-Stakeholder "Rachel Dupont" $ini10 493840000 493840001 493840003
New-Stakeholder "Ahmed Hassan" $ini10 493840000 493840002 493840002

# Automated Compliance
New-Stakeholder "Laura Henriksen" $ini11 493840000 493840003 493840003
New-Stakeholder "Nicholas Fox" $ini11 493840000 493840002 493840003
New-Stakeholder "Petra Kovacs" $ini11 493840000 493840002 493840002

# Supply Chain
New-Stakeholder "Derek Chambers" $ini12 493840000 493840003 493840003
New-Stakeholder "Ingrid Bauer" $ini12 493840000 493840002 493840003
New-Stakeholder "Samuel Adeyemi" $ini12 493840000 493840003 493840002
New-Stakeholder "Clara Weiss" $ini12 493840000 493840002 493840002

# ── RISKS (additional) ────────────────────────────────────────────────────
# pum_riskstatus:  493840000=Identified 493840001=Active 493840002=Mitigated 493840003=Resolved 436130000=Issue
# pum_probability: 976880001=20% 976880002=40% 976880003=60% 976880004=80%
# pum_riskimpact:  976880000=VeryLow 976880001=Low 976880002=Medium 976880003=High 976880004=Extreme
Write-Host "`n=== Additional Risks ===" -ForegroundColor Yellow

function New-Risk {
    param($name,$desc,$mit,$iniId,$status,$prob,$impact,[decimal]$cost,$due)
    $body = @{
        pum_name            = $name
        pum_riskdescription = $desc
        pum_riskmitigation  = $mit
        pum_riskstatus      = $status
        pum_probability     = $prob
        pum_riskimpact      = $impact
        pum_riskcost        = $cost
        pum_riskduedate     = $due
        "pum_Initiative@odata.bind" = "/pum_initiatives($iniId)"
    }
    Post-Record "pum_risks" $body "pum_riskid" "Risk: $name"
}

New-Risk "Portal Performance Under Load" `
    "High concurrent user load during peak periods may degrade portal response times" `
    "Implement CDN caching, auto-scaling, and load-test to 150% peak capacity" `
    $ini1 493840002 976880002 976880002 20000.0 "2025-09-30T00:00:00Z"

New-Risk "Field App Battery Drain" `
    "Continuous GPS and data sync drains device batteries, impacting field productivity" `
    "Optimise background sync frequency; support power banks as field kit standard" `
    $ini2 493840002 976880002 976880001 5000.0 "2025-08-31T00:00:00Z"

New-Risk "CRM Licence Cost Escalation" `
    "Vendor licence costs may increase 25%+ at renewal, exceeding OpEx budget" `
    "Negotiate 3-year lock-in; evaluate open-source alternatives in parallel" `
    $ini3 493840001 976880002 976880002 45000.0 "2025-12-31T00:00:00Z"

New-Risk "Data Lake Query Performance" `
    "Ad-hoc analytical queries on raw zone data exceeding 5-minute SLA" `
    "Implement query optimisation layer (Delta Lake / materialised views)" `
    $ini4 493840002 976880002 976880002 15000.0 "2025-09-30T00:00:00Z"

New-Risk "ML Model Overfitting to Historical Data" `
    "Model may overfit to pre-COVID sales patterns, reducing forecast accuracy post-2023" `
    "Use walk-forward validation; retrain quarterly with recent data windows" `
    $ini5 493840002 976880003 976880002 0.0 "2025-08-31T00:00:00Z"

New-Risk "Onboarding Platform Accessibility Compliance" `
    "Digital onboarding may not meet WCAG 2.1 AA accessibility standards" `
    "Engage accessibility specialist; conduct screen-reader UAT before go-live" `
    $ini6 493840001 976880002 976880002 12000.0 "2025-10-31T00:00:00Z"

New-Risk "ERP Vendor Shortlisting Delay" `
    "Procurement process for ERP vendor selection may delay blueprint approval by 6 weeks" `
    "Initiate RFP in parallel with assessment; pre-qualify 3 vendors by month 2" `
    $ini7 493840002 976880002 976880002 0.0 "2025-06-30T00:00:00Z"

New-Risk "Finance Year-End Freeze Conflict" `
    "Production cutover window overlaps with mandatory year-end financial close period" `
    "Schedule cutover for July; maintain legacy system read-only access through Q3" `
    $ini8 493840001 976880003 976880003 75000.0 "2026-06-30T00:00:00Z"

New-Risk "Teams External Sharing Policy Gap" `
    "Permissive external sharing defaults may expose confidential data to contractors" `
    "Lock external sharing at tenant level; whitelist per project via IT request process" `
    $ini9 493840003 976880002 976880003 0.0 "2025-11-30T00:00:00Z"

New-Risk "Real-Time Pipeline Latency Spikes" `
    "Event-driven pipeline shows latency spikes during high-volume order processing windows" `
    "Implement circuit breaker pattern; use dedicated Fabric capacity for business hours" `
    $ini10 493840001 976880002 976880002 25000.0 "2026-05-31T00:00:00Z"

New-Risk "Compliance Report False Positives" `
    "Automated GDPR reports flagging valid consent records as non-compliant" `
    "Refine detection logic; introduce human-in-the-loop review for edge cases" `
    $ini11 493840001 976880003 976880002 0.0 "2026-02-28T00:00:00Z"

New-Risk "Logistics Provider API Instability" `
    "Two of five logistics provider APIs lack SLA guarantees, risking supply chain disruption" `
    "Build retry/fallback logic; negotiate SLA clauses before integration go-live" `
    $ini12 493840000 976880003 976880003 95000.0 "2026-09-30T00:00:00Z"

# ── CHANGE REQUESTS ───────────────────────────────────────────────────────
# pum_changestatus: check valid values by looking at existing schema
Write-Host "`n=== Additional Change Requests ===" -ForegroundColor Yellow

function New-Change {
    param($name,$desc,$iniId)
    $body = @{
        pum_name        = $name
        pum_description = $desc
        "pum_Initiative@odata.bind" = "/pum_initiatives($iniId)"
    }
    Post-Record "pum_changerequests" $body "pum_changerequestid" "CR: $name"
}

New-Change "Add AI Chat Assistant to Portal" `
    "Stakeholders request integration of a GPT-powered chat widget to answer FAQs, reducing agent call volume" `
    $ini1

New-Change "Add Push Notification Module" `
    "Field supervisors request real-time job update push notifications to the mobile app" `
    $ini2

New-Change "Extend CRM Integration to Partner Portal" `
    "Sales leadership requests real-time CRM data sync to the B2B partner portal" `
    $ini3

New-Change "Include IoT Sensor Data Streams in Data Lake" `
    "Manufacturing team requests ingestion of factory IoT telemetry into the data lake" `
    $ini4

New-Change "Expand ML Forecast to Product-Level Granularity" `
    "VP Sales requests SKU-level forecasting in addition to regional sales aggregates" `
    $ini5

New-Change "Add E-Signature to Onboarding Documents" `
    "Legal requires all onboarding contracts to be signed via certified e-signature platform (DocuSign)" `
    $ini6

New-Change "Extend Blueprint to Include HR Module" `
    "CHRO requests HR module be included in ERP blueprint assessment alongside Finance and SCM" `
    $ini7

New-Change "Add Multi-Currency Support to Finance Module" `
    "Treasury requests multi-currency transaction processing for EU subsidiaries" `
    $ini8

New-Change "Enable Teams Phone System Replacement" `
    "CIO requests PSTN replacement (Teams Direct Routing) as part of M365 rollout scope" `
    $ini9

New-Change "Add Predictive Anomaly Detection to Dashboard" `
    "Operations requests automatic anomaly flagging in real-time KPI dashboards using ML" `
    $ini10

New-Change "Automate ISO 27001 Evidence Collection" `
    "CISO requests expansion of compliance automation to include ISO 27001 evidence gathering" `
    $ini11

New-Change "Add Demand Planning Module to SCM Scope" `
    "Supply Chain Director requests demand planning and S&OP module inclusion in implementation" `
    $ini12

# ── LESSONS LEARNED ───────────────────────────────────────────────────────
# pum_lessonsstatus: check existing schema from data already created
Write-Host "`n=== Additional Lessons Learned ===" -ForegroundColor Yellow

function New-Lesson {
    # pum_impact:           493840000=Positive 493840001=Negative 493840002=Neutral
    # pum_learningcategory: 493840000=ProjectMgmt 493840001=TeamCollab 493840002=RisksIssues 493840003=Skills
    param($name,$desc,$iniId,$impact,$category)
    $body = @{
        pum_name             = $name
        pum_description      = $desc
        pum_impact           = $impact
        pum_learningcategory = $category
        "pum_Initiative@odata.bind" = "/pum_initiatives($iniId)"
    }
    Post-Record "pum_lessonslearneds" $body "pum_lessonslearnedid" "LL: $name"
}

New-Lesson "Early UAT Engagement Prevents Late Rework" `
    "Involving end users in sprint reviews from Sprint 3 caught 60% of UX issues early — embedded business user in every sprint demo; added 1 UAT slot per sprint to project template" `
    $ini1 493840000 493840000

New-Lesson "Offline-First Architecture Must Be Non-Negotiable" `
    "Retrofitting offline support late in development added 6 weeks — architecture must assume offline-first from day 1; updated mobile kickoff checklist to mandate this decision before Phase 2" `
    $ini2 493840001 493840000

New-Lesson "Data Cleansing is 40% of Integration Effort" `
    "CRM data quality issues consumed 40% of integration effort, double the estimate — mandatory 2-week data profiling sprint now added to all integration project templates" `
    $ini3 493840001 493840002

New-Lesson "Tiered Storage Lifecycle Policies Save 30% Cost" `
    "Implementing hot/cool/archive tiers reduced data lake storage costs by 32% — tiered storage policies now included in all data lake project architectures as default" `
    $ini4 493840000 493840000

New-Lesson "Include Seasonal Anomalies in Training Data From Start" `
    "Model accuracy improved 18% after adding COVID-year data as anomaly-flagged samples — ML project template updated to mandate anomaly analysis and synthetic data augmentation from project start" `
    $ini5 493840000 493840003

New-Lesson "Champions Network Drives Faster Adoption" `
    "Recruiting 15 internal champions reduced training delivery time by 35% and increased satisfaction scores — champions network now a standard component of all digital platform rollout plans" `
    $ini6 493840000 493840001

New-Lesson "Involve Finance in ERP Blueprint from Week 1" `
    "Late Finance involvement in blueprint caused 2-week rework on CoA structure and reporting requirements — Finance stakeholders now mandatory in Week 1 workshop for all ERP-related assessments" `
    $ini7 493840001 493840000

New-Lesson "Parallel Run Duration Is Critical for Finance Migrations" `
    "90-day parallel run (vs. industry standard 30 days) detected 7 critical discrepancies before cutover — 90-day parallel run now standard for all financial module migrations in the programme" `
    $ini8 493840000 493840002

New-Lesson "Adoption Metrics Must Be Defined Before Rollout" `
    "Lack of agreed adoption KPIs at project start led to conflicting success criteria at steering committee — adoption metrics and targets now signed off at project initiation stage for all collaboration platforms" `
    $ini9 493840001 493840000

New-Lesson "Executive Dashboard Must Deliver Value by Week 2" `
    "Executive engagement dropped sharply when the first dashboard took 3 weeks to show meaningful data — dedicated sprint 1 deliverable now mandated: simplified exec KPI tile with live data, no filters required" `
    $ini10 493840001 493840001

New-Lesson "DPO Must Be a Core Team Member, Not a Reviewer" `
    "Treating the DPO as a reviewer (not core team) led to 3 rounds of late-stage consent mechanism redesign — DPO now included as a core project team member with standing allocation in all compliance projects" `
    $ini11 493840001 493840002

New-Lesson "Logistics API Testing Needs Dedicated Environment" `
    "Using shared QA environment for logistics API testing caused interference with 3 other project teams — dedicated integration sandbox environment now provisioned at project kick-off for all SCM integrations" `
    $ini12 493840000 493840000

# ── DEPENDENCIES (initiative-to-initiative) ───────────────────────────────
# pum_category: 493840000=Resource-based 493840001=Schedule-based
#               493840002=Technical 493840003=Customer/Stakeholder
# pum_kpi: 100000001=OnTrack 100000002=NeedsAttention 100000003=Delayed 100000005=Completed
Write-Host "`n=== Dependencies ===" -ForegroundColor Yellow

function New-Dependency {
    param($name,$fromId,$toId,$cat,$kpi,$due)
    $body = @{
        pum_name     = $name
        pum_category = $cat
        pum_kpi      = $kpi
        pum_duedate  = $due
        "pum_From_pum_initiative@odata.bind" = "/pum_initiatives($fromId)"
        "pum_To_pum_initiative@odata.bind"   = "/pum_initiatives($toId)"
    }
    Post-Record "pum_dependencies" $body "pum_dependencyid" "Dependency: $name"
}

# Data Lake enables Analytics Dashboard
New-Dependency "Data Lake provides data foundation for Analytics Dashboard" `
    $ini4 $ini10 493840002 100000005 "2025-12-31T00:00:00Z"

# ERP Blueprint drives Finance Migration scope
New-Dependency "ERP Blueprint defines Finance Module migration scope and vendor" `
    $ini7 $ini8 493840001 100000005 "2025-09-30T00:00:00Z"

# ERP Blueprint drives Supply Chain implementation scope
New-Dependency "ERP Blueprint defines SCM module implementation approach" `
    $ini7 $ini12 493840001 100000005 "2025-09-30T00:00:00Z"

# CRM Integration feeds Sales Forecasting ML training data
New-Dependency "CRM Integration delivers clean sales data for ML model training" `
    $ini3 $ini5 493840002 100000005 "2025-11-30T00:00:00Z"

# Portal Redesign needs SSO from CRM Integration
New-Dependency "CRM Integration provides SSO foundation required by Customer Portal" `
    $ini3 $ini1 493840002 100000005 "2025-06-30T00:00:00Z"

# M365 Rollout provides collaboration platform for all projects
New-Dependency "M365 Rollout provides Teams workspace for field app notifications" `
    $ini9 $ini2 493840000 100000001 "2026-01-31T00:00:00Z"

# Digital Onboarding depends on M365 for SharePoint document hosting
New-Dependency "M365 Rollout provides SharePoint for digital onboarding document storage" `
    $ini9 $ini6 493840002 100000001 "2026-01-31T00:00:00Z"

# Compliance Reporting depends on Data Lake for full data coverage
New-Dependency "Data Lake provides complete data lineage needed for GDPR compliance reports" `
    $ini4 $ini11 493840002 100000005 "2025-12-31T00:00:00Z"

# Finance Migration depends on ERP infrastructure from Blueprint
New-Dependency "Finance Module Migration depends on ERP cloud infrastructure provisioned in Blueprint" `
    $ini8 $ini12 493840000 100000002 "2026-09-30T00:00:00Z"

# Real-Time Analytics needs Sales Forecasting ML output as a data product
New-Dependency "Analytics Dashboard surfaces Sales Forecasting ML model output as executive KPI" `
    $ini5 $ini10 493840002 100000001 "2026-02-28T00:00:00Z"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Additional Data Complete!"
Write-Host "  Succeeded : $($script:ok)"  -ForegroundColor Green
Write-Host "  Failed    : $($script:err)" -ForegroundColor $(if ($script:err -gt 0) { 'Red' } else { 'Green' })
Write-Host "============================================" -ForegroundColor Cyan
