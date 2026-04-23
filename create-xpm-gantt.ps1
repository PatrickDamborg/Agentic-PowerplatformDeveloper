#!/usr/bin/env pwsh
# Creates GanttVersions, GanttTasks (summary/phase/task/milestone/deliverable),
# and TaskLinks for all 12 xPM initiatives.
#
# pum_tasktype:     493840000=task 493840001=project(phase) 493840002=milestone 493840003=projectSummary
# pum_taskcategory: 493840000=Tasks 493840001=Legal 493840002=Gate 493840003=KeyMilestone 493840004=KeyDeliverable

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

function Get-PctComplete {
    param([string]$start, [string]$end)
    $today = [DateTime]"2026-04-23"
    $s = [DateTime]$start; $e = [DateTime]$end
    if ($today -ge $e) { return 100 }
    if ($today -le $s) { return 0 }
    return [int](($today - $s).TotalDays / ($e - $s).TotalDays * 100)
}

function New-GanttVersion {
    param([string]$iniId, [string]$name)
    Post-Record "pum_ganttversions" @{
        pum_name = "v1.0"
        "pum_Initiative@odata.bind" = "/pum_initiatives($iniId)"
    } "pum_ganttversionid" "GanttVersion: $name"
}

# $taskDefs is an ordered list of hashtables
# Type: 'summary'|'phase'|'task'|'milestone'|'deliverable'
# ParentKey is used to link child tasks back to phase/summary
$script:taskMap = @{}   # key → gantttask GUID

function New-GanttTask {
    param(
        [string]$VersionId,
        [string]$IniId,
        [string]$Key,
        [string]$ParentKey,
        [string]$Name,
        [string]$Type,        # summary|phase|task|milestone|deliverable|gate
        [string]$Start,
        [string]$End,
        [string]$Wbs,
        [int]$SortOrder,
        [int]$Pct = -1
    )

    $typeCode = switch ($Type) {
        'summary'     { 493840003 }
        'phase'       { 493840001 }
        'milestone'   { 493840002 }
        'gate'        { 493840002 }
        default       { 493840000 }  # task / deliverable
    }
    $catCode = switch ($Type) {
        'gate'        { 493840002 }
        'milestone'   { 493840003 }
        'deliverable' { 493840004 }
        default       { 493840000 }
    }

    $pct = if ($Pct -ge 0) { $Pct } else { Get-PctComplete $Start $End }

    $body = @{
        pum_name             = $Name
        pum_tasktype         = $typeCode
        pum_taskcategory     = $catCode
        pum_startdate        = "${Start}T00:00:00Z"
        pum_enddate          = "${End}T00:00:00Z"
        pum_percentcomplete  = $pct
        pum_wbs              = $Wbs
        pum_sortorder        = "$SortOrder".PadLeft(4,'0')
        "pum_GanttVersion@odata.bind" = "/pum_ganttversions($VersionId)"
        "pum_initiative@odata.bind"   = "/pum_initiatives($IniId)"
    }

    if ($ParentKey -and $script:taskMap.ContainsKey($ParentKey)) {
        $body["pum_parenttaskid"] = $script:taskMap[$ParentKey]
    }

    $id = Post-Record "pum_gantttasks" $body "pum_gantttaskid" "  Task: $Name"
    if ($id) { $script:taskMap[$Key] = $id }
    return $id
}

function New-TaskLink {
    param([string]$VersionId, [string]$PredKey, [string]$SuccKey, [string]$Label)
    $predId = $script:taskMap[$PredKey]
    $succId = $script:taskMap[$SuccKey]
    if (-not $predId -or -not $succId) { return }
    Post-Record "pum_tasklinks" @{
        pum_linktype = "FS"
        pum_laginminutes = 0
        "pum_Predecessor@odata.bind" = "/pum_gantttasks($predId)"
        "pum_Successor@odata.bind"   = "/pum_gantttasks($succId)"
        "pum_Version@odata.bind"     = "/pum_ganttversions($VersionId)"
    } "pum_tasklinkid" "  Link: $Label" | Out-Null
}

# ─── Initiative definitions ────────────────────────────────────────────────
$initiatives = @(
    @{
        Id = "d6351a72-0a3f-f111-bec6-70a8a59a44c4"; Name = "Customer Self-Service Portal Redesign"
        Start = "2025-01-15"; End = "2025-12-31"
        Phases = @(
            @{ Key="p1"; Name="Phase 1: Discovery & Requirements"; Start="2025-01-15"; End="2025-03-31"; Tasks=@(
                @{ Key="t11"; Name="Stakeholder Interviews & Workshops"; Type="task"; Start="2025-01-15"; End="2025-01-31" }
                @{ Key="t12"; Name="Current State Assessment"; Type="task"; Start="2025-02-01"; End="2025-02-14" }
                @{ Key="t13"; Name="Business & System Requirements"; Type="task"; Start="2025-02-15"; End="2025-03-14" }
                @{ Key="t14"; Name="Requirements & Scope Document"; Type="deliverable"; Start="2025-03-15"; End="2025-03-28" }
                @{ Key="m11"; Name="Discovery Gate Review"; Type="gate"; Start="2025-03-31"; End="2025-03-31" }
            )}
            @{ Key="p2"; Name="Phase 2: UX Design & Architecture"; Start="2025-04-01"; End="2025-05-31"; Tasks=@(
                @{ Key="t21"; Name="UX Research & Wireframes"; Type="task"; Start="2025-04-01"; End="2025-04-21" }
                @{ Key="t22"; Name="Technical Architecture & Infrastructure"; Type="task"; Start="2025-04-07"; End="2025-04-30" }
                @{ Key="t23"; Name="Security & Accessibility Review"; Type="task"; Start="2025-05-01"; End="2025-05-15" }
                @{ Key="t24"; Name="Design & Architecture Blueprint"; Type="deliverable"; Start="2025-05-16"; End="2025-05-28" }
                @{ Key="m21"; Name="Design Approved"; Type="milestone"; Start="2025-05-31"; End="2025-05-31" }
            )}
            @{ Key="p3"; Name="Phase 3: Development & Integration"; Start="2025-06-01"; End="2025-08-31"; Tasks=@(
                @{ Key="t31"; Name="Backend API Development"; Type="task"; Start="2025-06-01"; End="2025-07-15" }
                @{ Key="t32"; Name="Frontend Portal Development"; Type="task"; Start="2025-06-15"; End="2025-07-31" }
                @{ Key="t33"; Name="CRM & SSO Integration"; Type="task"; Start="2025-07-01"; End="2025-08-15" }
                @{ Key="t34"; Name="Beta Build & Internal Testing"; Type="deliverable"; Start="2025-08-16"; End="2025-08-29" }
            )}
            @{ Key="p4"; Name="Phase 4: Testing & Launch"; Start="2025-09-01"; End="2025-12-31"; Tasks=@(
                @{ Key="t41"; Name="Performance & Security Testing"; Type="task"; Start="2025-09-01"; End="2025-09-30" }
                @{ Key="t42"; Name="User Acceptance Testing"; Type="task"; Start="2025-10-01"; End="2025-10-31" }
                @{ Key="t43"; Name="Training & Documentation"; Type="task"; Start="2025-11-01"; End="2025-11-30" }
                @{ Key="t44"; Name="Production Deployment"; Type="task"; Start="2025-12-01"; End="2025-12-15" }
                @{ Key="m41"; Name="Go-Live"; Type="milestone"; Start="2025-12-31"; End="2025-12-31" }
            )}
        )
    }
    @{
        Id = "f8351a72-0a3f-f111-bec6-70a8a59a44c4"; Name = "Mobile App for Field Service"
        Start = "2025-03-01"; End = "2025-11-30"
        Phases = @(
            @{ Key="p1"; Name="Phase 1: Discovery"; Start="2025-03-01"; End="2025-04-30"; Tasks=@(
                @{ Key="t11"; Name="Field Technician Workshops"; Type="task"; Start="2025-03-01"; End="2025-03-21" }
                @{ Key="t12"; Name="Mobile Platform Selection"; Type="task"; Start="2025-03-22"; End="2025-04-11" }
                @{ Key="t13"; Name="Offline Sync Architecture Design"; Type="task"; Start="2025-04-01"; End="2025-04-18" }
                @{ Key="t14"; Name="App Requirements Document"; Type="deliverable"; Start="2025-04-19"; End="2025-04-25" }
                @{ Key="m11"; Name="Discovery Complete"; Type="gate"; Start="2025-04-30"; End="2025-04-30" }
            )}
            @{ Key="p2"; Name="Phase 2: UI/UX & Technical Design"; Start="2025-05-01"; End="2025-05-31"; Tasks=@(
                @{ Key="t21"; Name="Mobile UX Prototyping"; Type="task"; Start="2025-05-01"; End="2025-05-14" }
                @{ Key="t22"; Name="API & Backend Design"; Type="task"; Start="2025-05-08"; End="2025-05-22" }
                @{ Key="t23"; Name="Device Compatibility Matrix"; Type="deliverable"; Start="2025-05-23"; End="2025-05-28" }
                @{ Key="m21"; Name="Design Approved"; Type="milestone"; Start="2025-05-31"; End="2025-05-31" }
            )}
            @{ Key="p3"; Name="Phase 3: Development"; Start="2025-06-01"; End="2025-08-31"; Tasks=@(
                @{ Key="t31"; Name="iOS & Android App Development"; Type="task"; Start="2025-06-01"; End="2025-07-31" }
                @{ Key="t32"; Name="Offline Data Sync Module"; Type="task"; Start="2025-06-15"; End="2025-07-31" }
                @{ Key="t33"; Name="ERP Integration (Work Orders)"; Type="task"; Start="2025-07-01"; End="2025-08-15" }
                @{ Key="t34"; Name="Beta App Build"; Type="deliverable"; Start="2025-08-16"; End="2025-08-29" }
            )}
            @{ Key="p4"; Name="Phase 4: Testing & Release"; Start="2025-09-01"; End="2025-11-30"; Tasks=@(
                @{ Key="t41"; Name="Device Compatibility Testing"; Type="task"; Start="2025-09-01"; End="2025-09-30" }
                @{ Key="t42"; Name="Field Pilot (20 Technicians)"; Type="task"; Start="2025-10-01"; End="2025-10-31" }
                @{ Key="t43"; Name="App Store Submission & Rollout"; Type="task"; Start="2025-11-01"; End="2025-11-15" }
                @{ Key="m41"; Name="Production Release"; Type="milestone"; Start="2025-11-30"; End="2025-11-30" }
            )}
        )
    }
    @{
        Id = "18361a72-0a3f-f111-bec6-70a8a59a44c4"; Name = "CRM Integration & Automation"
        Start = "2025-06-01"; End = "2026-03-31"
        Phases = @(
            @{ Key="p1"; Name="Phase 1: Data Profiling & Design"; Start="2025-06-01"; End="2025-07-31"; Tasks=@(
                @{ Key="t11"; Name="Source CRM Data Profiling"; Type="task"; Start="2025-06-01"; End="2025-06-20" }
                @{ Key="t12"; Name="Deduplication & Data Cleansing"; Type="task"; Start="2025-06-21"; End="2025-07-11" }
                @{ Key="t13"; Name="Integration Architecture Design"; Type="task"; Start="2025-07-01"; End="2025-07-25" }
                @{ Key="t14"; Name="Data Model & Field Mapping Doc"; Type="deliverable"; Start="2025-07-26"; End="2025-07-30" }
                @{ Key="m11"; Name="Design Gate"; Type="gate"; Start="2025-07-31"; End="2025-07-31" }
            )}
            @{ Key="p2"; Name="Phase 2: Integration Development"; Start="2025-08-01"; End="2025-10-31"; Tasks=@(
                @{ Key="t21"; Name="CRM Connector Development"; Type="task"; Start="2025-08-01"; End="2025-08-31" }
                @{ Key="t22"; Name="Automation Workflows (Power Automate)"; Type="task"; Start="2025-09-01"; End="2025-09-30" }
                @{ Key="t23"; Name="Lead Scoring & Routing Logic"; Type="task"; Start="2025-09-15"; End="2025-10-15" }
                @{ Key="t24"; Name="Integration Test Environment"; Type="deliverable"; Start="2025-10-16"; End="2025-10-28" }
            )}
            @{ Key="p3"; Name="Phase 3: Testing & Stabilization"; Start="2025-11-01"; End="2025-12-31"; Tasks=@(
                @{ Key="t31"; Name="End-to-End Integration Testing"; Type="task"; Start="2025-11-01"; End="2025-11-30" }
                @{ Key="t32"; Name="Performance & Load Testing"; Type="task"; Start="2025-11-15"; End="2025-12-15" }
                @{ Key="t33"; Name="UAT with Sales & Marketing"; Type="task"; Start="2025-12-01"; End="2025-12-15" }
                @{ Key="m31"; Name="UAT Sign-off"; Type="milestone"; Start="2025-12-31"; End="2025-12-31" }
            )}
            @{ Key="p4"; Name="Phase 4: Go-Live & Hypercare"; Start="2026-01-01"; End="2026-03-31"; Tasks=@(
                @{ Key="t41"; Name="Phased Production Rollout"; Type="task"; Start="2026-01-01"; End="2026-01-31" }
                @{ Key="t42"; Name="Hypercare Support & Monitoring"; Type="task"; Start="2026-02-01"; End="2026-02-28" }
                @{ Key="t43"; Name="Lessons Learned & Handover"; Type="task"; Start="2026-03-01"; End="2026-03-15" }
                @{ Key="t44"; Name="Runbook & Operations Guide"; Type="deliverable"; Start="2026-03-16"; End="2026-03-25" }
                @{ Key="m41"; Name="Go-Live Complete"; Type="milestone"; Start="2026-03-31"; End="2026-03-31" }
            )}
        )
    }
    @{
        Id = "37361a72-0a3f-f111-bec6-70a8a59a44c4"; Name = "Enterprise Data Lake Phase 1"
        Start = "2025-03-01"; End = "2025-12-31"
        Phases = @(
            @{ Key="p1"; Name="Phase 1: Architecture & Ingestion Design"; Start="2025-03-01"; End="2025-04-30"; Tasks=@(
                @{ Key="t11"; Name="Source System Inventory & Assessment"; Type="task"; Start="2025-03-01"; End="2025-03-21" }
                @{ Key="t12"; Name="Data Lake Architecture Design"; Type="task"; Start="2025-03-22"; End="2025-04-11" }
                @{ Key="t13"; Name="Governance & Security Framework"; Type="task"; Start="2025-04-01"; End="2025-04-18" }
                @{ Key="t14"; Name="Architecture Blueprint"; Type="deliverable"; Start="2025-04-19"; End="2025-04-25" }
                @{ Key="m11"; Name="Architecture Approved"; Type="gate"; Start="2025-04-30"; End="2025-04-30" }
            )}
            @{ Key="p2"; Name="Phase 2: Infrastructure & Ingestion"; Start="2025-05-01"; End="2025-07-31"; Tasks=@(
                @{ Key="t21"; Name="Cloud Storage & Compute Provisioning"; Type="task"; Start="2025-05-01"; End="2025-05-21" }
                @{ Key="t22"; Name="ERP Data Ingestion Pipelines"; Type="task"; Start="2025-05-15"; End="2025-06-30" }
                @{ Key="t23"; Name="CRM & Sales Data Ingestion"; Type="task"; Start="2025-06-01"; End="2025-07-15" }
                @{ Key="t24"; Name="Raw Zone Data Catalogue"; Type="deliverable"; Start="2025-07-16"; End="2025-07-28" }
            )}
            @{ Key="p3"; Name="Phase 3: Transformation & Curated Zone"; Start="2025-08-01"; End="2025-10-31"; Tasks=@(
                @{ Key="t31"; Name="Data Transformation (dbt / Spark)"; Type="task"; Start="2025-08-01"; End="2025-09-15" }
                @{ Key="t32"; Name="Data Quality Rules & Monitoring"; Type="task"; Start="2025-08-15"; End="2025-09-30" }
                @{ Key="t33"; Name="Curated Zone & Data Products"; Type="task"; Start="2025-09-15"; End="2025-10-20" }
                @{ Key="t34"; Name="Data Catalogue (Purview)"; Type="deliverable"; Start="2025-10-21"; End="2025-10-28" }
                @{ Key="m31"; Name="Curated Zone Complete"; Type="milestone"; Start="2025-10-31"; End="2025-10-31" }
            )}
            @{ Key="p4"; Name="Phase 4: Analytics Enablement & Handover"; Start="2025-11-01"; End="2025-12-31"; Tasks=@(
                @{ Key="t41"; Name="Power BI Dashboards (Pilot)"; Type="task"; Start="2025-11-01"; End="2025-11-30" }
                @{ Key="t42"; Name="User Training & Self-Service Enablement"; Type="task"; Start="2025-11-15"; End="2025-12-15" }
                @{ Key="t43"; Name="Phase 1 Completion Report"; Type="deliverable"; Start="2025-12-16"; End="2025-12-24" }
                @{ Key="m41"; Name="Phase 1 Complete"; Type="milestone"; Start="2025-12-31"; End="2025-12-31" }
            )}
        )
    }
    @{
        Id = "b7611778-0a3f-f111-bec6-70a8a59a44c4"; Name = "Sales Forecasting ML Model"
        Start = "2025-07-01"; End = "2026-02-28"
        Phases = @(
            @{ Key="p1"; Name="Phase 1: Data Assessment & Feature Engineering"; Start="2025-07-01"; End="2025-08-31"; Tasks=@(
                @{ Key="t11"; Name="Historical Sales Data Assessment"; Type="task"; Start="2025-07-01"; End="2025-07-21" }
                @{ Key="t12"; Name="Feature Engineering & Data Pipeline"; Type="task"; Start="2025-07-22"; End="2025-08-15" }
                @{ Key="t13"; Name="Training Dataset Documentation"; Type="deliverable"; Start="2025-08-16"; End="2025-08-25" }
                @{ Key="m11"; Name="Data Ready"; Type="gate"; Start="2025-08-31"; End="2025-08-31" }
            )}
            @{ Key="p2"; Name="Phase 2: Model Development & Training"; Start="2025-09-01"; End="2025-11-30"; Tasks=@(
                @{ Key="t21"; Name="Baseline Model Development (XGBoost)"; Type="task"; Start="2025-09-01"; End="2025-09-30" }
                @{ Key="t22"; Name="Hyperparameter Tuning & Cross-Validation"; Type="task"; Start="2025-10-01"; End="2025-10-31" }
                @{ Key="t23"; Name="Ensemble Model & Drift Monitoring Setup"; Type="task"; Start="2025-11-01"; End="2025-11-21" }
                @{ Key="t24"; Name="Model Card & Performance Report"; Type="deliverable"; Start="2025-11-22"; End="2025-11-28" }
                @{ Key="m21"; Name="Model Approved"; Type="milestone"; Start="2025-11-30"; End="2025-11-30" }
            )}
            @{ Key="p3"; Name="Phase 3: MLOps & Deployment"; Start="2025-12-01"; End="2026-01-31"; Tasks=@(
                @{ Key="t31"; Name="MLOps Pipeline (Azure ML)"; Type="task"; Start="2025-12-01"; End="2025-12-31" }
                @{ Key="t32"; Name="Power BI Forecast Integration"; Type="task"; Start="2026-01-01"; End="2026-01-21" }
                @{ Key="t33"; Name="Sales Team Training"; Type="task"; Start="2026-01-15"; End="2026-01-28" }
                @{ Key="t34"; Name="Production ML API"; Type="deliverable"; Start="2026-01-22"; End="2026-01-28" }
            )}
            @{ Key="p4"; Name="Phase 4: Validation & Handover"; Start="2026-02-01"; End="2026-02-28"; Tasks=@(
                @{ Key="t41"; Name="Q4 Forecast Accuracy Validation"; Type="task"; Start="2026-02-01"; End="2026-02-14" }
                @{ Key="t42"; Name="Monitoring Dashboard & Runbook"; Type="deliverable"; Start="2026-02-15"; End="2026-02-21" }
                @{ Key="m41"; Name="Model Live & Validated"; Type="milestone"; Start="2026-02-28"; End="2026-02-28" }
            )}
        )
    }
    @{
        Id = "52621778-0a3f-f111-bec6-70a8a59a44c4"; Name = "Digital Onboarding Platform"
        Start = "2025-06-01"; End = "2026-01-31"
        Phases = @(
            @{ Key="p1"; Name="Phase 1: Process Mapping & Design"; Start="2025-06-01"; End="2025-07-31"; Tasks=@(
                @{ Key="t11"; Name="As-Is Onboarding Process Mapping"; Type="task"; Start="2025-06-01"; End="2025-06-20" }
                @{ Key="t12"; Name="Digital Workflow Design (Power Automate)"; Type="task"; Start="2025-06-21"; End="2025-07-15" }
                @{ Key="t13"; Name="To-Be Process & System Design"; Type="deliverable"; Start="2025-07-16"; End="2025-07-25" }
                @{ Key="m11"; Name="Design Approved"; Type="gate"; Start="2025-07-31"; End="2025-07-31" }
            )}
            @{ Key="p2"; Name="Phase 2: Development"; Start="2025-08-01"; End="2025-10-31"; Tasks=@(
                @{ Key="t21"; Name="Power Apps Onboarding Portal"; Type="task"; Start="2025-08-01"; End="2025-09-15" }
                @{ Key="t22"; Name="DocuSign & HRIS Integration"; Type="task"; Start="2025-09-01"; End="2025-10-01" }
                @{ Key="t23"; Name="Automated Notifications & Escalations"; Type="task"; Start="2025-10-02"; End="2025-10-22" }
                @{ Key="t24"; Name="Beta Onboarding Platform"; Type="deliverable"; Start="2025-10-23"; End="2025-10-28" }
            )}
            @{ Key="p3"; Name="Phase 3: Pilot & Rollout"; Start="2025-11-01"; End="2026-01-31"; Tasks=@(
                @{ Key="t31"; Name="HR Pilot (10 New Hires)"; Type="task"; Start="2025-11-01"; End="2025-11-30" }
                @{ Key="t32"; Name="Refinements & UAT Sign-off"; Type="task"; Start="2025-12-01"; End="2025-12-15" }
                @{ Key="t33"; Name="Company-Wide Rollout"; Type="task"; Start="2025-12-16"; End="2026-01-15" }
                @{ Key="t34"; Name="HR Operations Handover Guide"; Type="deliverable"; Start="2026-01-16"; End="2026-01-23" }
                @{ Key="m31"; Name="Platform Live"; Type="milestone"; Start="2026-01-31"; End="2026-01-31" }
            )}
        )
    }
    @{
        Id = "f5611778-0a3f-f111-bec6-70a8a59a44c4"; Name = "ERP Assessment & Blueprint"
        Start = "2025-04-01"; End = "2025-09-30"
        Phases = @(
            @{ Key="p1"; Name="Phase 1: Current State Assessment"; Start="2025-04-01"; End="2025-05-31"; Tasks=@(
                @{ Key="t11"; Name="ERP Landscape & Module Inventory"; Type="task"; Start="2025-04-01"; End="2025-04-21" }
                @{ Key="t12"; Name="Technical Debt & Risk Assessment"; Type="task"; Start="2025-04-22"; End="2025-05-09" }
                @{ Key="t13"; Name="Vendor & Licensing Review"; Type="task"; Start="2025-05-01"; End="2025-05-21" }
                @{ Key="t14"; Name="Current State Report"; Type="deliverable"; Start="2025-05-22"; End="2025-05-28" }
                @{ Key="m11"; Name="Assessment Complete"; Type="gate"; Start="2025-05-31"; End="2025-05-31" }
            )}
            @{ Key="p2"; Name="Phase 2: Future State & Blueprint"; Start="2025-06-01"; End="2025-09-30"; Tasks=@(
                @{ Key="t21"; Name="Cloud ERP Vendor Evaluation (SAP/Oracle)"; Type="task"; Start="2025-06-01"; End="2025-06-30" }
                @{ Key="t22"; Name="Business Process Re-engineering"; Type="task"; Start="2025-07-01"; End="2025-07-31" }
                @{ Key="t23"; Name="Migration Roadmap & Sequencing"; Type="task"; Start="2025-08-01"; End="2025-08-31" }
                @{ Key="t24"; Name="ERP Transformation Blueprint"; Type="deliverable"; Start="2025-09-01"; End="2025-09-19" }
                @{ Key="m21"; Name="Blueprint Approved"; Type="milestone"; Start="2025-09-30"; End="2025-09-30" }
            )}
        )
    }
    @{
        Id = "14621778-0a3f-f111-bec6-70a8a59a44c4"; Name = "Finance Module Cloud Migration"
        Start = "2025-10-01"; End = "2026-09-30"
        Phases = @(
            @{ Key="p1"; Name="Phase 1: Preparation & Data Migration Design"; Start="2025-10-01"; End="2025-11-30"; Tasks=@(
                @{ Key="t11"; Name="Finance Module Scope & Cutover Strategy"; Type="task"; Start="2025-10-01"; End="2025-10-21" }
                @{ Key="t12"; Name="Custom Field & Report Mapping"; Type="task"; Start="2025-10-22"; End="2025-11-10" }
                @{ Key="t13"; Name="Data Migration Design & ETL Build"; Type="task"; Start="2025-11-01"; End="2025-11-25" }
                @{ Key="t14"; Name="Migration Strategy Document"; Type="deliverable"; Start="2025-11-26"; End="2025-11-28" }
                @{ Key="m11"; Name="Migration Design Approved"; Type="gate"; Start="2025-11-30"; End="2025-11-30" }
            )}
            @{ Key="p2"; Name="Phase 2: Cloud Environment & Config"; Start="2025-12-01"; End="2026-01-31"; Tasks=@(
                @{ Key="t21"; Name="Cloud ERP Tenant Provisioning"; Type="task"; Start="2025-12-01"; End="2025-12-15" }
                @{ Key="t22"; Name="Finance Module Configuration"; Type="task"; Start="2025-12-16"; End="2026-01-15" }
                @{ Key="t23"; Name="Chart of Accounts & Org Structure Setup"; Type="task"; Start="2026-01-01"; End="2026-01-21" }
                @{ Key="t24"; Name="Configured Environment Handover"; Type="deliverable"; Start="2026-01-22"; End="2026-01-28" }
            )}
            @{ Key="p3"; Name="Phase 3: Data Migration & Integration"; Start="2026-02-01"; End="2026-06-30"; Tasks=@(
                @{ Key="t31"; Name="Historical Data Migration (Trial Runs)"; Type="task"; Start="2026-02-01"; End="2026-03-31" }
                @{ Key="t32"; Name="Integration: Payroll, AP/AR, Procurement"; Type="task"; Start="2026-03-01"; End="2026-05-15" }
                @{ Key="t33"; Name="Parallel Run (90 Days)"; Type="task"; Start="2026-04-01"; End="2026-06-28" }
                @{ Key="t34"; Name="Validated Dataset & Reconciliation Report"; Type="deliverable"; Start="2026-06-15"; End="2026-06-28" }
                @{ Key="m31"; Name="Parallel Run Complete"; Type="milestone"; Start="2026-06-30"; End="2026-06-30" }
            )}
            @{ Key="p4"; Name="Phase 4: Cutover & Hypercare"; Start="2026-07-01"; End="2026-09-30"; Tasks=@(
                @{ Key="t41"; Name="Finance Module Cutover"; Type="task"; Start="2026-07-01"; End="2026-07-14" }
                @{ Key="t42"; Name="Post-Cutover Hypercare (30 days)"; Type="task"; Start="2026-07-15"; End="2026-08-14" }
                @{ Key="t43"; Name="Year-End Close Testing"; Type="task"; Start="2026-08-15"; End="2026-09-15" }
                @{ Key="t44"; Name="Operations & Finance Runbook"; Type="deliverable"; Start="2026-09-16"; End="2026-09-25" }
                @{ Key="m41"; Name="Finance Module Live"; Type="milestone"; Start="2026-09-30"; End="2026-09-30" }
            )}
        )
    }
    @{
        Id = "17154a7e-0a3f-f111-bec6-70a8a59a44c4"; Name = "M365 Collaboration Rollout"
        Start = "2025-09-01"; End = "2026-04-30"
        Phases = @(
            @{ Key="p1"; Name="Phase 1: Planning & Governance"; Start="2025-09-01"; End="2025-10-31"; Tasks=@(
                @{ Key="t11"; Name="M365 Tenant Assessment & Licensing"; Type="task"; Start="2025-09-01"; End="2025-09-21" }
                @{ Key="t12"; Name="Teams Governance Policy Design"; Type="task"; Start="2025-09-22"; End="2025-10-10" }
                @{ Key="t13"; Name="Change Management Plan"; Type="task"; Start="2025-10-01"; End="2025-10-21" }
                @{ Key="t14"; Name="Governance & Rollout Plan"; Type="deliverable"; Start="2025-10-22"; End="2025-10-28" }
                @{ Key="m11"; Name="Planning Complete"; Type="gate"; Start="2025-10-31"; End="2025-10-31" }
            )}
            @{ Key="p2"; Name="Phase 2: Pilot Deployment"; Start="2025-11-01"; End="2025-12-31"; Tasks=@(
                @{ Key="t21"; Name="Pilot Group Config (200 Users)"; Type="task"; Start="2025-11-01"; End="2025-11-21" }
                @{ Key="t22"; Name="Champions Network Training"; Type="task"; Start="2025-11-15"; End="2025-12-05" }
                @{ Key="t23"; Name="Pilot Feedback & Adoption Metrics"; Type="task"; Start="2025-12-01"; End="2025-12-21" }
                @{ Key="m21"; Name="Pilot Sign-off"; Type="milestone"; Start="2025-12-31"; End="2025-12-31" }
            )}
            @{ Key="p3"; Name="Phase 3: Company-Wide Rollout"; Start="2026-01-01"; End="2026-03-31"; Tasks=@(
                @{ Key="t31"; Name="Wave 1 Rollout (HQ + Finance)"; Type="task"; Start="2026-01-01"; End="2026-01-31" }
                @{ Key="t32"; Name="Wave 2 Rollout (Operations + Field)"; Type="task"; Start="2026-02-01"; End="2026-02-28" }
                @{ Key="t33"; Name="Data Migration (File Shares → SharePoint)"; Type="task"; Start="2026-01-15"; End="2026-03-15" }
                @{ Key="t34"; Name="M365 Adoption Playbook"; Type="deliverable"; Start="2026-03-16"; End="2026-03-25" }
                @{ Key="m31"; Name="Full Rollout Complete"; Type="milestone"; Start="2026-03-31"; End="2026-03-31" }
            )}
            @{ Key="p4"; Name="Phase 4: Adoption & Optimization"; Start="2026-04-01"; End="2026-04-30"; Tasks=@(
                @{ Key="t41"; Name="Adoption Dashboards & KPI Tracking"; Type="task"; Start="2026-04-01"; End="2026-04-15" }
                @{ Key="t42"; Name="Advanced Features Training (Copilot)"; Type="task"; Start="2026-04-10"; End="2026-04-25" }
                @{ Key="m41"; Name="Adoption Target Achieved"; Type="milestone"; Start="2026-04-30"; End="2026-04-30" }
            )}
        )
    }
    @{
        Id = "d6611778-0a3f-f111-bec6-70a8a59a44c4"; Name = "Real-Time Analytics Dashboard"
        Start = "2025-09-01"; End = "2026-06-30"
        Phases = @(
            @{ Key="p1"; Name="Phase 1: Requirements & Data Sourcing"; Start="2025-09-01"; End="2025-10-31"; Tasks=@(
                @{ Key="t11"; Name="Business Intelligence Requirements Workshop"; Type="task"; Start="2025-09-01"; End="2025-09-21" }
                @{ Key="t12"; Name="Data Source Connectivity Assessment"; Type="task"; Start="2025-09-22"; End="2025-10-10" }
                @{ Key="t13"; Name="KPI & Metric Framework"; Type="deliverable"; Start="2025-10-11"; End="2025-10-22" }
                @{ Key="m11"; Name="Requirements Approved"; Type="gate"; Start="2025-10-31"; End="2025-10-31" }
            )}
            @{ Key="p2"; Name="Phase 2: Dashboard Development"; Start="2025-11-01"; End="2026-02-28"; Tasks=@(
                @{ Key="t21"; Name="Real-Time Data Pipeline (Fabric/Synapse)"; Type="task"; Start="2025-11-01"; End="2025-12-15" }
                @{ Key="t22"; Name="Executive Dashboard (Power BI)"; Type="task"; Start="2025-12-01"; End="2026-01-15" }
                @{ Key="t23"; Name="Operational Dashboards (5 Domains)"; Type="task"; Start="2026-01-01"; End="2026-02-15" }
                @{ Key="t24"; Name="Dashboard Suite v1.0"; Type="deliverable"; Start="2026-02-16"; End="2026-02-25" }
                @{ Key="m21"; Name="Dashboard Suite Approved"; Type="milestone"; Start="2026-02-28"; End="2026-02-28" }
            )}
            @{ Key="p3"; Name="Phase 3: Testing & Optimization"; Start="2026-03-01"; End="2026-04-30"; Tasks=@(
                @{ Key="t31"; Name="Performance & Load Testing"; Type="task"; Start="2026-03-01"; End="2026-03-21" }
                @{ Key="t32"; Name="Business User Acceptance Testing"; Type="task"; Start="2026-03-22"; End="2026-04-10" }
                @{ Key="t33"; Name="Dashboard Optimization & Fine-tuning"; Type="task"; Start="2026-04-01"; End="2026-04-21" }
                @{ Key="m31"; Name="UAT Complete"; Type="milestone"; Start="2026-04-30"; End="2026-04-30" }
            )}
            @{ Key="p4"; Name="Phase 4: Rollout & Enablement"; Start="2026-05-01"; End="2026-06-30"; Tasks=@(
                @{ Key="t41"; Name="Executive & Management Rollout"; Type="task"; Start="2026-05-01"; End="2026-05-21" }
                @{ Key="t42"; Name="Self-Service Analytics Training"; Type="task"; Start="2026-05-22"; End="2026-06-10" }
                @{ Key="t43"; Name="Analytics Centre of Excellence Launch"; Type="deliverable"; Start="2026-06-11"; End="2026-06-25" }
                @{ Key="m41"; Name="Analytics Platform Live"; Type="milestone"; Start="2026-06-30"; End="2026-06-30" }
            )}
        )
    }
    @{
        Id = "71621778-0a3f-f111-bec6-70a8a59a44c4"; Name = "Automated Compliance Reporting"
        Start = "2025-07-01"; End = "2026-03-31"
        Phases = @(
            @{ Key="p1"; Name="Phase 1: Compliance Scope & Shadow IT Audit"; Start="2025-07-01"; End="2025-08-31"; Tasks=@(
                @{ Key="t11"; Name="GDPR & SOX Reporting Requirements"; Type="task"; Start="2025-07-01"; End="2025-07-21" }
                @{ Key="t12"; Name="Shadow IT & Data Flow Audit"; Type="task"; Start="2025-07-22"; End="2025-08-15" }
                @{ Key="t13"; Name="Compliance Scope Document"; Type="deliverable"; Start="2025-08-16"; End="2025-08-25" }
                @{ Key="m11"; Name="Scope Approved"; Type="gate"; Start="2025-08-31"; End="2025-08-31" }
            )}
            @{ Key="p2"; Name="Phase 2: Report Automation Development"; Start="2025-09-01"; End="2025-11-30"; Tasks=@(
                @{ Key="t21"; Name="GDPR Report Automation (Power Automate)"; Type="task"; Start="2025-09-01"; End="2025-09-30" }
                @{ Key="t22"; Name="SOX Control Reporting Automation"; Type="task"; Start="2025-10-01"; End="2025-10-31" }
                @{ Key="t23"; Name="ISO Audit Evidence Collection"; Type="task"; Start="2025-11-01"; End="2025-11-21" }
                @{ Key="t24"; Name="Automated Report Suite"; Type="deliverable"; Start="2025-11-22"; End="2025-11-28" }
                @{ Key="m21"; Name="Automation Complete"; Type="milestone"; Start="2025-11-30"; End="2025-11-30" }
            )}
            @{ Key="p3"; Name="Phase 3: Validation & Sign-off"; Start="2025-12-01"; End="2026-01-31"; Tasks=@(
                @{ Key="t31"; Name="DPO & Legal Review"; Type="task"; Start="2025-12-01"; End="2025-12-21" }
                @{ Key="t32"; Name="External Auditor Verification"; Type="task"; Start="2026-01-01"; End="2026-01-21" }
                @{ Key="t33"; Name="Compliance Validation Report"; Type="deliverable"; Start="2026-01-22"; End="2026-01-28" }
                @{ Key="m31"; Name="Auditor Sign-off"; Type="milestone"; Start="2026-01-31"; End="2026-01-31" }
            )}
            @{ Key="p4"; Name="Phase 4: Operationalisation"; Start="2026-02-01"; End="2026-03-31"; Tasks=@(
                @{ Key="t41"; Name="Compliance Team Training"; Type="task"; Start="2026-02-01"; End="2026-02-14" }
                @{ Key="t42"; Name="Reporting Schedule & Alerts Configuration"; Type="task"; Start="2026-02-15"; End="2026-02-28" }
                @{ Key="t43"; Name="Compliance Operations Runbook"; Type="deliverable"; Start="2026-03-01"; End="2026-03-14" }
                @{ Key="m41"; Name="System Operational"; Type="milestone"; Start="2026-03-31"; End="2026-03-31" }
            )}
        )
    }
    @{
        Id = "33621778-0a3f-f111-bec6-70a8a59a44c4"; Name = "Supply Chain Module Implementation"
        Start = "2026-04-01"; End = "2027-03-31"
        Phases = @(
            @{ Key="p1"; Name="Phase 1: Planning & Vendor Onboarding"; Start="2026-04-01"; End="2026-05-31"; Tasks=@(
                @{ Key="t11"; Name="SCM Requirements & Scope Definition"; Type="task"; Start="2026-04-01"; End="2026-04-21"; Pct=50 }
                @{ Key="t12"; Name="SI Partner Selection & Contract"; Type="task"; Start="2026-04-15"; End="2026-05-05"; Pct=30 }
                @{ Key="t13"; Name="Logistics Provider Integration Inventory"; Type="task"; Start="2026-05-01"; End="2026-05-21"; Pct=10 }
                @{ Key="t14"; Name="Project Charter & Plan"; Type="deliverable"; Start="2026-05-22"; End="2026-05-28"; Pct=0 }
                @{ Key="m11"; Name="Kick-off Complete"; Type="gate"; Start="2026-05-31"; End="2026-05-31"; Pct=0 }
            )}
            @{ Key="p2"; Name="Phase 2: Design & Configuration"; Start="2026-06-01"; End="2026-09-30"; Tasks=@(
                @{ Key="t21"; Name="SCM Process Design (Demand, Procurement)"; Type="task"; Start="2026-06-01"; End="2026-07-15"; Pct=0 }
                @{ Key="t22"; Name="ERP SCM Module Configuration"; Type="task"; Start="2026-07-16"; End="2026-08-31"; Pct=0 }
                @{ Key="t23"; Name="Logistics API Integrations (5 Providers)"; Type="task"; Start="2026-08-01"; End="2026-09-25"; Pct=0 }
                @{ Key="t24"; Name="Configured SCM System"; Type="deliverable"; Start="2026-09-16"; End="2026-09-25"; Pct=0 }
            )}
            @{ Key="p3"; Name="Phase 3: Testing & Data Migration"; Start="2026-10-01"; End="2026-12-31"; Tasks=@(
                @{ Key="t31"; Name="SCM Integration Testing"; Type="task"; Start="2026-10-01"; End="2026-10-31"; Pct=0 }
                @{ Key="t32"; Name="Data Migration (Inventory & Vendor Master)"; Type="task"; Start="2026-11-01"; End="2026-11-30"; Pct=0 }
                @{ Key="t33"; Name="User Acceptance Testing"; Type="task"; Start="2026-12-01"; End="2026-12-21"; Pct=0 }
                @{ Key="m31"; Name="UAT Sign-off"; Type="milestone"; Start="2026-12-31"; End="2026-12-31"; Pct=0 }
            )}
            @{ Key="p4"; Name="Phase 4: Go-Live & Stabilisation"; Start="2027-01-01"; End="2027-03-31"; Tasks=@(
                @{ Key="t41"; Name="Cutover & Production Go-Live"; Type="task"; Start="2027-01-01"; End="2027-01-14"; Pct=0 }
                @{ Key="t42"; Name="Hypercare & Issue Resolution"; Type="task"; Start="2027-01-15"; End="2027-02-14"; Pct=0 }
                @{ Key="t43"; Name="Supply Chain Operations Runbook"; Type="deliverable"; Start="2027-02-15"; End="2027-02-28"; Pct=0 }
                @{ Key="m41"; Name="SCM Live & Stable"; Type="milestone"; Start="2027-03-31"; End="2027-03-31"; Pct=0 }
            )}
        )
    }
)

# ─── Main loop ────────────────────────────────────────────────────────────
foreach ($ini in $initiatives) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Initiative: $($ini.Name)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    # Reset task map for this initiative
    $script:taskMap = @{}

    # 1. Create Gantt Version
    $verId = New-GanttVersion $ini.Id $ini.Name
    if (-not $verId) { Write-Host "  SKIPPING - failed to create version" -ForegroundColor Red; continue }

    # 2. Create Project Summary task
    $summaryKey = "summary"
    $summaryId = New-GanttTask -VersionId $verId -IniId $ini.Id `
        -Key $summaryKey -ParentKey $null `
        -Name $ini.Name -Type "summary" `
        -Start $ini.Start -End $ini.End `
        -Wbs "1" -SortOrder 1

    $sortBase = 2
    $wbsPhase = 1

    foreach ($phase in $ini.Phases) {
        # 3. Create Phase
        $phaseId = New-GanttTask -VersionId $verId -IniId $ini.Id `
            -Key $phase.Key -ParentKey $summaryKey `
            -Name $phase.Name -Type "phase" `
            -Start $phase.Start -End $phase.End `
            -Wbs "1.$wbsPhase" -SortOrder $sortBase
        $sortBase++

        $wbsTask = 1
        $prevTaskKey = $null

        foreach ($t in $phase.Tasks) {
            $pct = if ($t.ContainsKey('Pct')) { $t.Pct } else { -1 }
            New-GanttTask -VersionId $verId -IniId $ini.Id `
                -Key "$($phase.Key)_$($t.Key)" -ParentKey $phase.Key `
                -Name $t.Name -Type $t.Type `
                -Start $t.Start -End $t.End `
                -Wbs "1.$wbsPhase.$wbsTask" -SortOrder $sortBase `
                -Pct $pct | Out-Null
            $sortBase++; $wbsTask++
        }
        $wbsPhase++
    }

    # 4. Create phase-to-phase FS task links
    $phaseKeys = $ini.Phases | ForEach-Object { $_.Key }
    for ($i = 0; $i -lt ($phaseKeys.Count - 1); $i++) {
        $pred = $phaseKeys[$i]; $succ = $phaseKeys[$i + 1]
        New-TaskLink $verId $pred $succ "Phase $($i+1) → Phase $($i+2) ($($ini.Name))"
    }
    # Last task in each phase → first task of next phase (cross-phase critical path)
    for ($i = 0; $i -lt ($ini.Phases.Count - 1); $i++) {
        $lastTask = $ini.Phases[$i].Tasks[-1]
        $firstTask = $ini.Phases[$i+1].Tasks[0]
        $predKey = "$($ini.Phases[$i].Key)_$($lastTask.Key)"
        $succKey = "$($ini.Phases[$i+1].Key)_$($firstTask.Key)"
        New-TaskLink $verId $predKey $succKey "Cross-Phase: $($lastTask.Name) → $($firstTask.Name)"
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Gantt Creation Complete!"
Write-Host "  Succeeded : $($script:ok)"  -ForegroundColor Green
Write-Host "  Failed    : $($script:err)" -ForegroundColor $(if ($script:err -gt 0) { 'Red' } else { 'Green' })
Write-Host "============================================" -ForegroundColor Cyan
