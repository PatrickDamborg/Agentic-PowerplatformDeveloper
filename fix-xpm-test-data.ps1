#!/usr/bin/env pwsh
# Fix script — creates the records that failed in the main run:
#   - 1 Strategic Objective (description truncated to 100 chars)
#   - 8 Ideas (pum_ideascore on 0-10 scale)
#   - 15 Risks (pum_riskcost cast to [decimal])
# Reads IDs of already-created portfolios, programs, and initiatives from Dataverse.

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
    param([string]$Set,[hashtable]$Body,[string]$IdField,[string]$Label)
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
        if ($hdr -match '\(([^)]+)\)$') {
            Write-Host "  [OK] $Label" -ForegroundColor Green; $script:ok++; return $Matches[1]
        }
    } catch {
        $msg = $_.Exception.Message
        if ($_.ErrorDetails.Message) { try { $msg = ($_.ErrorDetails.Message | ConvertFrom-Json).error.message } catch {} }
        Write-Host "  [ERR] $Label" -ForegroundColor Red
        Write-Host "        $msg" -ForegroundColor DarkRed
        $script:err++; return $null
    }
}

function Get-First { param([string]$Set,[string]$Filter,[string]$Select)
    $safeFilter = $Filter -replace '&', '%26'
    $ep  = "${Set}?`$filter=$safeFilter&`$select=$Select&`$top=1"
    $res = Invoke-WebRequest -Method GET -Uri "$baseUrl/$ep" -Headers $headers -UseBasicParsing
    ($res.Content | ConvertFrom-Json).value | Select-Object -First 1
}

# ── Fetch existing record IDs ─────────────────────────────────
Write-Host "Fetching existing record IDs..." -ForegroundColor Cyan

$portDT = (Get-First "pum_portfolios" "pum_portfolio eq 'Digital Transformation Portfolio'" "pum_portfolioid").pum_portfolioid
$portEE = (Get-First "pum_portfolios" "pum_portfolio eq 'Enterprise Excellence Portfolio'"  "pum_portfolioid").pum_portfolioid

function GetIni($name) { (Get-First "pum_initiatives" "pum_name eq '$name'" "pum_initiativeid").pum_initiativeid }
function GetProg($name){ (Get-First "pum_programs"    "pum_program eq '$name'" "pum_programid").pum_programid }

$ini1  = GetIni "Customer Self-Service Portal Redesign"
$ini2  = GetIni "Mobile App for Field Service"
$ini3  = GetIni "CRM Integration & Automation"
$ini4  = GetIni "Enterprise Data Lake Phase 1"
$ini5  = GetIni "Sales Forecasting ML Model"
$ini8  = GetIni "Finance Module Cloud Migration"
$ini9  = GetIni "Supply Chain Module Implementation"
$ini11 = GetIni "Automated Compliance Reporting"
$ini12 = GetIni "M365 Collaboration Rollout"

$prog2 = GetProg "Data & AI Enablement"
$prog3 = GetProg "ERP Consolidation & Cloud Lift"

Write-Host "  portDT=$portDT"
Write-Host "  portEE=$portEE"
Write-Host "  ini1=$ini1  ini4=$ini4  ini8=$ini8"

# ── Fix 1: Strategic Objective (description max 100 chars) ────
Write-Host "`nFix 1: Strategic Objective" -ForegroundColor Yellow
Post-Record "pum_strategicobjectiveses" @{
    pum_name        = "Elevate Customer Experience"
    pum_description = "Achieve 95%+ satisfaction through self-service and faster resolution"  # 69 chars
    pum_launchdate  = "2025-06-01T00:00:00Z"
    pum_enddate     = "2027-06-30T00:00:00Z"
} "pum_strategicobjectivesid" "Objective: Elevate Customer Experience" | Out-Null

# ── Fix 2: Ideas (score on 0-5 scale) ────────────────────────
Write-Host "`nFix 2: Ideas (score 0-5)" -ForegroundColor Yellow

function New-Idea { param($name,$desc,$portId,$budget,$benefits,$start,$end,$score)
    $body = @{
        pum_name             = $name
        pum_description      = $desc
        pum_budgetestimate   = $budget
        pum_benefitsestimate = $benefits
        pum_ideascore        = $score
        pum_proposedstart    = $start
        pum_proposedend      = $end
        pum_rank             = 1
    }
    if ($portId) { $body["pum_Portfolio@odata.bind"] = "/pum_portfolios($portId)" }
    Post-Record "pum_ideas" $body "pum_ideaid" "Idea: $name"
}

New-Idea "AI-Powered Customer Portal"           "Replace legacy portal with AI-driven self-service experience reducing support calls by 40%"     $portDT 1200000 3500000 "2025-03-01T00:00:00Z" "2026-06-30T00:00:00Z" 5
New-Idea "Unified Data Lake Platform"           "Centralize enterprise data into a governed lake to enable analytics and ML workloads"            $portDT 2100000 5000000 "2025-01-01T00:00:00Z" "2026-12-31T00:00:00Z" 5
New-Idea "Mobile Workforce App"                 "Empower field staff with a mobile app for real-time task management and reporting"               $portDT  450000  900000 "2025-06-01T00:00:00Z" "2026-03-31T00:00:00Z" 4
New-Idea "ERP Cloud Migration"                  "Migrate on-premises ERP to cloud to reduce infrastructure costs by 35%"                         $portEE 3200000 7000000 "2025-04-01T00:00:00Z" "2027-06-30T00:00:00Z" 5
New-Idea "Automated Compliance Reporting"       "Automate GDPR, SOX, and ISO audit reporting to cut compliance prep time from weeks to days"     $portEE  380000  850000 "2025-02-01T00:00:00Z" "2025-12-31T00:00:00Z" 4
New-Idea "Digital Onboarding Platform"          "Fully digital employee onboarding reducing time-to-productivity from 4 weeks to 1 week"         $portEE  290000  600000 "2025-07-01T00:00:00Z" "2026-04-30T00:00:00Z" 3
New-Idea "API Gateway & Developer Portal"       "Internal API marketplace enabling teams to share services and accelerate integrations"           $portDT  520000 1200000 "2025-05-01T00:00:00Z" "2026-02-28T00:00:00Z" 4
New-Idea "Predictive Maintenance IoT Solution"  "Deploy IoT sensors and ML to predict equipment failures, reducing downtime by 60%"              $portDT 1800000 4200000 "2026-01-01T00:00:00Z" "2027-06-30T00:00:00Z" 5

# ── Fix 3: Risks (cast cost to [decimal]) ─────────────────────
Write-Host "`nFix 3: Risks" -ForegroundColor Yellow
# pum_riskstatus: 493840000=Identified, 493840001=Active, 493840002=Mitigated, 493840003=Resolved, 436130000=Issue
# pum_probability: 976880001=20%, 976880002=40%, 976880003=60%, 976880004=80%
# pum_riskimpact:  976880000=VeryLow, 976880001=Low, 976880002=Medium, 976880003=High, 976880004=Extreme

function New-Risk { param($name,$desc,$mitigation,$iniId,$portId,$progId,$status,$prob,$impact,[decimal]$cost,$dueDate)
    $body = @{
        pum_name            = $name
        pum_riskdescription = $desc
        pum_riskmitigation  = $mitigation
        pum_riskstatus      = $status
        pum_probability     = $prob
        pum_riskimpact      = $impact
        pum_riskcost        = $cost
        pum_riskduedate     = $dueDate
    }
    if ($iniId)  { $body["pum_Initiative@odata.bind"] = "/pum_initiatives($iniId)" }
    if ($portId) { $body["pum_Portfolio@odata.bind"]  = "/pum_portfolios($portId)" }
    if ($progId) { $body["pum_Program@odata.bind"]    = "/pum_programs($progId)" }
    Post-Record "pum_risks" $body "pum_riskid" "Risk: $name"
}

# params: name desc mitigation iniId portId progId status prob impact cost dueDate
New-Risk "Legacy API Incompatibility" `
    "Third-party APIs in portal may not support OAuth 2.0 required by new platform" `
    "Conduct API audit in Sprint 1; engage vendors for migration roadmap if needed" `
    $ini1 $portDT $null 493840001 976880003 976880003 60000.0 "2025-04-30T00:00:00Z"

New-Risk "Scope Creep from Stakeholders" `
    "Business stakeholders continue requesting feature additions after design freeze" `
    "Strict change control board — any new request goes through formal impact assessment" `
    $ini1 $portDT $null 493840001 976880004 976880003 40000.0 "2025-05-15T00:00:00Z"

New-Risk "Offline Sync Data Conflicts" `
    "Concurrent edits by field users when device reconnects may cause data inconsistencies" `
    "Implement conflict resolution UI and last-write-wins fallback with full audit log" `
    $ini2 $portDT $null 493840001 976880002 976880002 15000.0 "2025-06-30T00:00:00Z"

New-Risk "Device Fragmentation" `
    "Wide variety of Android device models may cause rendering or performance issues" `
    "Define supported device matrix; conduct compatibility testing on top 10 models" `
    $ini2 $portDT $null 493840002 976880002 976880001 8000.0 "2025-05-01T00:00:00Z"

New-Risk "CRM Data Quality Issues" `
    "Source CRM data has duplicate records and inconsistent formats affecting integration" `
    "Run data profiling tool pre-integration; deduplicate and standardize before go-live" `
    $ini3 $portDT $null 493840001 976880003 976880002 25000.0 "2025-08-31T00:00:00Z"

New-Risk "Data Lake Storage Cost Overrun" `
    "Raw data volume from source systems exceeds initial sizing estimates by up to 3x" `
    "Implement tiered storage policy and lifecycle management to control costs" `
    $ini4 $portDT $null 493840002 976880002 976880003 90000.0 "2025-07-31T00:00:00Z"

New-Risk "ML Model Bias in Sales Forecasting" `
    "Training data may not represent seasonal anomalies, leading to inaccurate Q4 predictions" `
    "Include synthetic data for rare events; implement ongoing model drift monitoring" `
    $ini5 $portDT $null 493840001 976880003 976880003 0.0 "2025-10-31T00:00:00Z"

New-Risk "ERP Vendor Support Gap" `
    "Current on-premises ERP version reaches end-of-support before migration completes" `
    "Negotiate extended support; prioritize finance modules in migration sequence" `
    $ini8 $portEE $null 493840001 976880004 976880004 200000.0 "2025-12-31T00:00:00Z"

New-Risk "Data Loss During ERP Migration" `
    "Incomplete mapping of custom fields may result in data loss during finance cutover" `
    "Full field-level mapping review; 90-day parallel run; documented rollback plan" `
    $ini8 $portEE $null 493840001 976880004 976880004 500000.0 "2026-06-30T00:00:00Z"

New-Risk "Key Resource Unavailability" `
    "Lead architect has competing commitments reducing capacity 50% in Q3" `
    "Identify backup architect; document key design decisions to reduce dependency" `
    $null $portDT $prog2 493840001 976880003 976880003 80000.0 "2025-09-30T00:00:00Z"

New-Risk "GDPR Compliance Gap in New Portal" `
    "Portal data residency and consent management may not meet GDPR at launch" `
    "Engage DPO for privacy-by-design review in Sprint 2; conduct DPIA before go-live" `
    $ini1 $portDT $null 493840001 976880004 976880004 120000.0 "2025-08-31T00:00:00Z"

New-Risk "Teams Adoption Resistance" `
    "Email-first employees may resist migrating to Teams for collaboration" `
    "Change management: champions network, training sessions, and usage dashboards" `
    $ini12 $portEE $null 493840001 976880002 976880002 30000.0 "2025-11-30T00:00:00Z"

New-Risk "Supply Chain Integration Complexity" `
    "SCM integration with 5 external logistics providers is more complex than estimated" `
    "Bring in SI partner with ERP SCM expertise; revise project timeline" `
    $ini9 $portEE $null 493840001 976880003 976880003 150000.0 "2026-09-30T00:00:00Z"

New-Risk "Compliance Report Accuracy" `
    "Automated GDPR reports may miss data flows through undocumented shadow IT systems" `
    "Conduct shadow IT audit; include API gateway monitoring to capture all data flows" `
    $ini11 $portEE $null 493840001 976880004 976880003 0.0 "2026-01-31T00:00:00Z"

New-Risk "Budget Overrun — Data Lake" `
    "Phase 1 data lake exceeded estimate by 18% due to unexpected data quality work" `
    "Revise Phase 2 scope; present revised business case to portfolio steering committee" `
    $ini4 $portDT $null 436130000 976880004 976880003 180000.0 "2025-11-30T00:00:00Z"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Fix Complete!"
Write-Host "  Succeeded : $($script:ok)"  -ForegroundColor Green
Write-Host "  Failed    : $($script:err)" -ForegroundColor $(if ($script:err -gt 0) { "Red" } else { "Green" })
Write-Host "============================================" -ForegroundColor Cyan
