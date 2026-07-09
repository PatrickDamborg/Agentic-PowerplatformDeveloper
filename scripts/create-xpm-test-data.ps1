#!/usr/bin/env pwsh
#Requires -Version 7
<#
.SYNOPSIS
    Creates comprehensive Projectum xPM test data across all key tables.
    ~165 records covering Roles, RBS, Business Drivers, Strategic Objectives,
    Portfolios, Resources, Ideas, Programs, Initiatives, Work Packages,
    Team Members, Risks, Change Requests, Status Reports, Lessons Learned,
    and Stakeholders.
#>

$ErrorActionPreference = 'Continue'
$root = "C:\Users\Patrick\Agentic-PowerplatformDeveloper"
Import-Module (Join-Path $root "helpers.psm1") -Force

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Projectum xPM - Test Data Creation" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$conn = Initialize-DataverseConnection -EnvPath (Join-Path $root ".env")
$baseUrl = $conn.BaseUrl

# Add Prefer: return=representation so POST returns the created entity body
$headers = $conn.Headers.Clone()
$headers["Prefer"] = "return=representation"

$script:ok  = 0
$script:err = 0

function Post-Record {
    param([string]$Set, [hashtable]$Body, [string]$IdField, [string]$Label)
    try {
        $json = $Body | ConvertTo-Json -Depth 10 -Compress
        $url  = "$baseUrl/$Set"
        $resp = Invoke-WebRequest -Method POST -Uri $url -Headers $headers -Body $json -UseBasicParsing
        if ($resp.Content) {
            $rec = $resp.Content | ConvertFrom-Json
            $id  = $rec.$IdField
            Write-Host "  [OK] $Label" -ForegroundColor Green
            $script:ok++
            return $id
        }
        # Fallback: OData-EntityId header
        $hdr = $resp.Headers.'OData-EntityId'
        if ($hdr -match '\(([^)]+)\)$') {
            Write-Host "  [OK] $Label" -ForegroundColor Green
            $script:ok++
            return $Matches[1]
        }
    } catch {
        $msg = $_.Exception.Message
        if ($_.ErrorDetails.Message) {
            try { $msg = ($_.ErrorDetails.Message | ConvertFrom-Json).error.message } catch {}
        }
        Write-Host "  [ERR] $Label" -ForegroundColor Red
        Write-Host "        $msg" -ForegroundColor DarkRed
        $script:err++
        return $null
    }
}

# ─────────────────────────────────────────────────────────────
# PHASE 1 — ROLES
# ─────────────────────────────────────────────────────────────
Write-Host "Phase 1: Roles" -ForegroundColor Yellow

$roleIds = @{}
@("Project Manager","Business Analyst","Solution Architect","Senior Developer",
  "Junior Developer","QA Engineer","UX Designer","DevOps Engineer") | ForEach-Object {
    $id = Post-Record "pum_roles" @{ pum_name = $_ } "pum_roleid" "Role: $_"
    $roleIds[$_] = $id
}

# ─────────────────────────────────────────────────────────────
# PHASE 2 — RBS
# ─────────────────────────────────────────────────────────────
Write-Host "`nPhase 2: Resource Breakdown Structure" -ForegroundColor Yellow

$rbsIT = Post-Record "pum_rbses" @{
    pum_name = "Technology"; pum_level = 1
    pum_level1name = "Technology"; pum_fullrbs = "Technology"
} "pum_rbsid" "RBS L1: Technology"

$rbsBiz = Post-Record "pum_rbses" @{
    pum_name = "Business"; pum_level = 1
    pum_level1name = "Business"; pum_fullrbs = "Business"
} "pum_rbsid" "RBS L1: Business"

$rbsExt = Post-Record "pum_rbses" @{
    pum_name = "External"; pum_level = 1
    pum_level1name = "External"; pum_fullrbs = "External"
} "pum_rbsid" "RBS L1: External"

function RbsL2 { param($name,$parentId,$parent)
    $body = @{
        pum_name  = $name; pum_level = 2
        pum_level1name = $parent; pum_level2name = $name
        pum_fullrbs = "$parent.$name"
    }
    if ($parentId) { $body["pum_ParentName@odata.bind"] = "/pum_rbses($parentId)" }
    Post-Record "pum_rbses" $body "pum_rbsid" "RBS L2: $parent.$name"
}

$rbsDev  = RbsL2 "Development"    $rbsIT  "Technology"
$rbsQA   = RbsL2 "Quality"        $rbsIT  "Technology"
$rbsArch = RbsL2 "Architecture"   $rbsIT  "Technology"
$rbsOps2 = RbsL2 "IT Operations"  $rbsIT  "Technology"
$rbsStrat= RbsL2 "Strategy"       $rbsBiz "Business"
$rbsOps  = RbsL2 "Operations"     $rbsBiz "Business"
$rbsFin  = RbsL2 "Finance"        $rbsBiz "Business"

# ─────────────────────────────────────────────────────────────
# PHASE 3 — BUSINESS DRIVERS
# ─────────────────────────────────────────────────────────────
Write-Host "`nPhase 3: Business Drivers (Investment Categories)" -ForegroundColor Yellow

$driverIds = @()
@(
    @{ pum_name="Digital Transformation";   pum_priority=1 },
    @{ pum_name="Customer Experience";      pum_priority=2 },
    @{ pum_name="Operational Excellence";   pum_priority=3 },
    @{ pum_name="Compliance & Regulatory";  pum_priority=4 },
    @{ pum_name="Innovation & Growth";      pum_priority=5 }
) | ForEach-Object {
    $id = Post-Record "pum_investmentcategories" $_ "pum_investmentcategoryid" "Driver: $($_.pum_name)"
    $driverIds += $id
}

# ─────────────────────────────────────────────────────────────
# PHASE 4 — STRATEGIC OBJECTIVES
# ─────────────────────────────────────────────────────────────
Write-Host "`nPhase 4: Strategic Objectives" -ForegroundColor Yellow

$objIds = @()
@(
    @{
        pum_name = "Accelerate Digital Growth"
        pum_description = "Grow digital revenue by 40% through platform modernization and new digital channels by end of 2027"
        pum_launchdate = "2025-01-01T00:00:00Z"; pum_enddate = "2027-12-31T00:00:00Z"
    },
    @{
        pum_name = "Elevate Customer Experience"
        pum_description = "Achieve 95%+ customer satisfaction score through self-service capabilities and faster resolution times"
        pum_launchdate = "2025-06-01T00:00:00Z"; pum_enddate = "2027-06-30T00:00:00Z"
    },
    @{
        pum_name = "Reduce Operational Costs by 20%"
        pum_description = "Automate manual processes and consolidate legacy systems to cut operational overhead"
        pum_launchdate = "2025-01-01T00:00:00Z"; pum_enddate = "2026-12-31T00:00:00Z"
    },
    @{
        pum_name = "Expand into New Markets"
        pum_description = "Enter three new geographic markets leveraging scalable cloud infrastructure by 2028"
        pum_launchdate = "2026-01-01T00:00:00Z"; pum_enddate = "2028-12-31T00:00:00Z"
    }
) | ForEach-Object {
    $id = Post-Record "pum_strategicobjectiveses" $_ "pum_strategicobjectivesid" "Objective: $($_.pum_name)"
    $objIds += $id
}

# ─────────────────────────────────────────────────────────────
# PHASE 5 — PORTFOLIOS
# ─────────────────────────────────────────────────────────────
Write-Host "`nPhase 5: Portfolios" -ForegroundColor Yellow

$portDT = Post-Record "pum_portfolios" @{
    pum_portfolio   = "Digital Transformation Portfolio"
    pum_description = "Strategic portfolio covering all digital transformation initiatives across the organization"
    pum_totalbudget = 8500000
} "pum_portfolioid" "Portfolio: Digital Transformation"

$portEE = Post-Record "pum_portfolios" @{
    pum_portfolio   = "Enterprise Excellence Portfolio"
    pum_description = "Operational improvement and compliance initiatives supporting core business functions"
    pum_totalbudget = 4200000
} "pum_portfolioid" "Portfolio: Enterprise Excellence"

# ─────────────────────────────────────────────────────────────
# PHASE 6 — RESOURCES
# ─────────────────────────────────────────────────────────────
Write-Host "`nPhase 6: Resources" -ForegroundColor Yellow

function New-Resource { param($name,$first,$last,$email,$title,$dept,$hours,$rate,$type,$roleKey,$rbsId)
    $body = @{
        pum_name              = $name
        pum_firstname         = $first
        pum_lastname          = $last
        pum_email             = $email
        pum_jobtitle          = $title
        pum_department        = $dept
        pum_dailycapacityhours= $hours
        pum_rate              = $rate
        pum_resourcetype      = $type
    }
    if ($roleIds[$roleKey]) { $body["pum_Role@odata.bind"] = "/pum_roles($($roleIds[$roleKey]))" }
    if ($rbsId)             { $body["pum_RBS@odata.bind"]  = "/pum_rbses($rbsId)" }
    Post-Record "pum_resources" $body "pum_resourceid" "Resource: $name"
}

# 493840000=Named, 493840001=Generic
$r1  = New-Resource "Alice Johnson"    "Alice"    "Johnson"   "alice.johnson@contoso.com"    "Senior PM"           "IT PMO"              8 1200 493840000 "Project Manager"    $rbsIT
$r2  = New-Resource "Bob Smith"        "Bob"      "Smith"     "bob.smith@contoso.com"        "Solution Architect"  "IT Architecture"     8 1500 493840000 "Solution Architect" $rbsArch
$r3  = New-Resource "Carol White"      "Carol"    "White"     "carol.white@contoso.com"      "Lead BA"             "IT PMO"              8  900 493840000 "Business Analyst"   $rbsStrat
$r4  = New-Resource "David Brown"      "David"    "Brown"     "david.brown@contoso.com"      "Senior Developer"    "Software Eng"        8 1100 493840000 "Senior Developer"   $rbsDev
$r5  = New-Resource "Eva Martinez"     "Eva"      "Martinez"  "eva.martinez@contoso.com"     "Senior Developer"    "Software Eng"        8 1050 493840000 "Senior Developer"   $rbsDev
$r6  = New-Resource "Frank Lee"        "Frank"    "Lee"       "frank.lee@contoso.com"        "QA Lead"             "Quality Assurance"   8  850 493840000 "QA Engineer"        $rbsQA
$r7  = New-Resource "Grace Kim"        "Grace"    "Kim"       "grace.kim@contoso.com"        "UX Designer"         "Product Design"      8  800 493840000 "UX Designer"        $rbsBiz
$r8  = New-Resource "Henry Chen"       "Henry"    "Chen"      "henry.chen@contoso.com"       "DevOps Engineer"     "IT Operations"       8  950 493840000 "DevOps Engineer"    $rbsOps2
$r9  = New-Resource "Isabelle Dupont"  "Isabelle" "Dupont"    "isabelle.dupont@contoso.com"  "Project Manager"     "IT PMO"              8 1050 493840000 "Project Manager"    $rbsIT
$r10 = New-Resource "James Wilson"     "James"    "Wilson"    "james.wilson@contoso.com"     "Junior Developer"    "Software Eng"        8  650 493840000 "Junior Developer"   $rbsDev

$allResources = @($r1,$r2,$r3,$r4,$r5,$r6,$r7,$r8,$r9,$r10)

# ─────────────────────────────────────────────────────────────
# PHASE 7 — IDEAS
# ─────────────────────────────────────────────────────────────
Write-Host "`nPhase 7: Ideas" -ForegroundColor Yellow

function New-Idea { param($name,$desc,$portId,$budget,$benefits,$start,$end,$score)
    $body = @{
        pum_name           = $name
        pum_description    = $desc
        pum_budgetestimate = $budget
        pum_benefitsestimate = $benefits
        pum_ideascore      = $score
        pum_proposedstart  = $start
        pum_proposedend    = $end
        pum_rank           = 1
    }
    if ($portId) { $body["pum_Portfolio@odata.bind"] = "/pum_portfolios($portId)" }
    Post-Record "pum_ideas" $body "pum_ideaid" "Idea: $name"
}

$idea1  = New-Idea "AI-Powered Customer Portal"            "Replace legacy portal with an AI-driven self-service experience reducing support calls by 40%"           $portDT 1200000 3500000 "2025-03-01T00:00:00Z" "2026-06-30T00:00:00Z" 87
$idea2  = New-Idea "Unified Data Lake Platform"            "Centralize all enterprise data into a governed lake to enable analytics and ML workloads"                  $portDT 2100000 5000000 "2025-01-01T00:00:00Z" "2026-12-31T00:00:00Z" 92
$idea3  = New-Idea "Mobile Workforce App"                  "Empower field staff with a mobile app for real-time task management and reporting"                         $portDT  450000  900000 "2025-06-01T00:00:00Z" "2026-03-31T00:00:00Z" 74
$idea4  = New-Idea "ERP Cloud Migration"                   "Migrate on-premises ERP to cloud to reduce infrastructure costs by 35% and improve scalability"            $portEE 3200000 7000000 "2025-04-01T00:00:00Z" "2027-06-30T00:00:00Z" 95
$idea5  = New-Idea "Automated Compliance Reporting"        "Automate GDPR, SOX, and ISO audit reporting to cut compliance preparation time from 3 weeks to 2 days"     $portEE  380000  850000 "2025-02-01T00:00:00Z" "2025-12-31T00:00:00Z" 82
$idea6  = New-Idea "Digital Onboarding Platform"           "Fully digital employee onboarding reducing time-to-productivity from 4 weeks to 1 week"                   $portEE  290000  600000 "2025-07-01T00:00:00Z" "2026-04-30T00:00:00Z" 68
$idea7  = New-Idea "API Gateway & Developer Portal"        "Create an internal API marketplace enabling teams to share services and accelerate integration projects"    $portDT  520000 1200000 "2025-05-01T00:00:00Z" "2026-02-28T00:00:00Z" 78
$idea8  = New-Idea "Predictive Maintenance IoT Solution"   "Deploy IoT sensors and ML models to predict equipment failures, reducing downtime by 60%"                  $portDT 1800000 4200000 "2026-01-01T00:00:00Z" "2027-06-30T00:00:00Z" 85

# ─────────────────────────────────────────────────────────────
# PHASE 8 — PROGRAMS
# ─────────────────────────────────────────────────────────────
Write-Host "`nPhase 8: Programs" -ForegroundColor Yellow

function New-Program { param($name,$desc,$portId,$start,$end,$budget,$status)
    $body = @{
        pum_program      = $name
        pum_description  = $desc
        pum_programstart = $start
        pum_programfinish= $end
        pum_totalbudget  = $budget
        pum_status       = $status
        pum_rank         = 1
    }
    if ($portId) { $body["pum_Portfolio@odata.bind"] = "/pum_portfolios($portId)" }
    Post-Record "pum_programs" $body "pum_programid" "Program: $name"
}

# pum_status: 493840000=Active, 493840005=Proposed, 493840003=Completed
$prog1 = New-Program "Customer Platform Modernization"   "End-to-end modernization of customer-facing digital platforms and self-service capabilities"   $portDT "2025-01-01T00:00:00Z" "2026-12-31T00:00:00Z" 3500000 493840000
$prog2 = New-Program "Data & AI Enablement"              "Build enterprise data foundation with analytics, ML, and AI capabilities across business units"  $portDT "2025-03-01T00:00:00Z" "2027-06-30T00:00:00Z" 4800000 493840000
$prog3 = New-Program "ERP Consolidation & Cloud Lift"    "Consolidate fragmented ERP instances and migrate to a unified cloud platform"                   $portEE "2025-04-01T00:00:00Z" "2027-09-30T00:00:00Z" 3200000 493840000
$prog4 = New-Program "Workplace Transformation"          "Modernize employee tools, HR systems, and workplace collaboration to boost productivity"         $portEE "2025-06-01T00:00:00Z" "2026-09-30T00:00:00Z" 1100000 493840000

# ─────────────────────────────────────────────────────────────
# PHASE 9 — INITIATIVES (Projects)
# ─────────────────────────────────────────────────────────────
Write-Host "`nPhase 9: Initiatives (Projects)" -ForegroundColor Yellow
# pum_status: 493840005=Proposed, 493840004=Under Evaluation, 493840006=Authorized, 493840000=Active, 493840001=On Hold, 493840002=Closing, 493840003=Completed
# pum_kpisummary: 493840000=Not Set, 493840001=Need help, 493840002=At risk, 493840003=No issue

function New-Initiative { param($name,$desc,$progId,$portId,$start,$end,$budget,$status,$kpi)
    $body = @{
        pum_name             = $name
        pum_description      = $desc
        pum_initiativestart  = $start
        pum_initiativefinish = $end
        pum_budget           = $budget
        pum_status           = $status
        pum_kpisummary       = $kpi
        pum_rank             = 1
    }
    if ($progId) { $body["pum_program@odata.bind"]    = "/pum_programs($progId)" }
    if ($portId) { $body["pum_Portfolio@odata.bind"] = "/pum_portfolios($portId)" }
    Post-Record "pum_initiatives" $body "pum_initiativeid" "Initiative: $name"
}

# Program 1 — Customer Platform Modernization
$ini1  = New-Initiative "Customer Self-Service Portal Redesign"  "Redesign the customer portal with modern UX, AI chatbot, and account management features"  $prog1 $portDT "2025-01-15T00:00:00Z" "2025-12-31T00:00:00Z" 850000 493840000 493840003
$ini2  = New-Initiative "Mobile App for Field Service"           "Native mobile app for field technicians with offline capability, job scheduling, and digital forms" $prog1 $portDT "2025-03-01T00:00:00Z" "2025-11-30T00:00:00Z" 480000 493840000 493840002
$ini3  = New-Initiative "CRM Integration & Automation"          "Integrate CRM with ERP and marketing platform to automate lead-to-cash process"               $prog1 $portDT "2025-06-01T00:00:00Z" "2026-03-31T00:00:00Z" 620000 493840006 493840000

# Program 2 — Data & AI Enablement
$ini4  = New-Initiative "Enterprise Data Lake Phase 1"          "Ingest operational data from 12 source systems into a governed Azure Data Lake"               $prog2 $portDT "2025-03-01T00:00:00Z" "2025-12-31T00:00:00Z" 1200000 493840000 493840003
$ini5  = New-Initiative "Sales Forecasting ML Model"            "Deploy ML model for 90-day sales forecasting integrated with CRM dashboard"                   $prog2 $portDT "2025-07-01T00:00:00Z" "2026-02-28T00:00:00Z"  380000 493840000 493840002
$ini6  = New-Initiative "Real-Time Analytics Dashboard"         "Executive and operational dashboards powered by real-time data from the data lake"            $prog2 $portDT "2025-09-01T00:00:00Z" "2026-06-30T00:00:00Z"  520000 493840005 493840000

# Program 3 — ERP Consolidation
$ini7  = New-Initiative "ERP Assessment & Blueprint"            "Current-state assessment, gap analysis, and future-state blueprint for ERP consolidation"     $prog3 $portEE "2025-04-01T00:00:00Z" "2025-09-30T00:00:00Z"  280000 493840003 493840003
$ini8  = New-Initiative "Finance Module Cloud Migration"        "Migrate financial management and consolidation modules to cloud ERP with zero data loss"      $prog3 $portEE "2025-10-01T00:00:00Z" "2026-09-30T00:00:00Z" 1400000 493840000 493840002
$ini9  = New-Initiative "Supply Chain Module Implementation"    "Implement cloud SCM module covering procurement, inventory, and logistics"                    $prog3 $portEE "2026-04-01T00:00:00Z" "2027-03-31T00:00:00Z" 1100000 493840006 493840000

# Program 4 — Workplace Transformation
$ini10 = New-Initiative "Digital Onboarding Platform"          "Fully automated digital onboarding covering IT provisioning, HR induction, and compliance training" $prog4 $portEE "2025-06-01T00:00:00Z" "2026-01-31T00:00:00Z"  310000 493840000 493840003
$ini11 = New-Initiative "Automated Compliance Reporting"       "Automate generation of GDPR, SOX, and ISO 27001 audit reports from source systems"             $prog4 $portEE "2025-07-01T00:00:00Z" "2026-03-31T00:00:00Z"  390000 493840000 493840001
$ini12 = New-Initiative "M365 Collaboration Rollout"           "Deploy Microsoft 365 including Teams, SharePoint Online, and Copilot across all business units" $prog4 $portEE "2025-09-01T00:00:00Z" "2026-04-30T00:00:00Z"  420000 493840000 493840003

$allInitiatives = @($ini1,$ini2,$ini3,$ini4,$ini5,$ini6,$ini7,$ini8,$ini9,$ini10,$ini11,$ini12)

# ─────────────────────────────────────────────────────────────
# PHASE 10 — WORK PACKAGES
# ─────────────────────────────────────────────────────────────
Write-Host "`nPhase 10: Work Packages" -ForegroundColor Yellow

function New-WP { param($name,$iniId)
    $body = @{ pum_name = $name }
    if ($iniId) { $body["pum_Initiative@odata.bind"] = "/pum_initiatives($iniId)" }
    Post-Record "pum_workpackages" $body "pum_workpackageid" "WorkPackage: $name"
}

New-WP "Discovery & Requirements"              $ini1
New-WP "UX Design & Prototyping"               $ini1
New-WP "Backend Development"                   $ini1
New-WP "AI Chatbot Integration"                $ini1
New-WP "UAT & Go-Live"                         $ini1

New-WP "iOS & Android Development"             $ini2
New-WP "Offline Sync Architecture"             $ini2
New-WP "Field Testing & Rollout"               $ini2

New-WP "CRM-ERP Integration Design"            $ini3
New-WP "API Development & Testing"             $ini3
New-WP "Data Migration & Validation"           $ini3

New-WP "Data Source Onboarding"                $ini4
New-WP "Data Governance Framework"             $ini4
New-WP "Ingestion Pipeline Development"        $ini4

New-WP "Model Training & Validation"           $ini5
New-WP "CRM Dashboard Integration"             $ini5

New-WP "Dashboard Design & Wireframes"         $ini6
New-WP "Data Pipeline to Dashboards"           $ini6

New-WP "Current State Assessment"              $ini7
New-WP "Vendor Selection & RFP"                $ini7

New-WP "Finance Module Configuration"          $ini8
New-WP "Data Migration — Finance"              $ini8
New-WP "Parallel Run & Cutover"                $ini8

New-WP "Digital Onboarding Workflow Design"    $ini10
New-WP "IT Provisioning Automation"            $ini10

New-WP "Report Template Development"           $ini11
New-WP "Source System Integration"             $ini11

New-WP "Tenant Setup & Configuration"          $ini12
New-WP "User Migration & Training"             $ini12

# ─────────────────────────────────────────────────────────────
# PHASE 11 — TEAM MEMBERS
# ─────────────────────────────────────────────────────────────
Write-Host "`nPhase 11: Team Members" -ForegroundColor Yellow
# pum_accesslevel: need to check, but let's try 493840000 and omit if it fails

function Add-TeamMember { param($resId,$iniId,$progId,$name)
    $body = @{ pum_teammember = $name }
    if ($resId)  { $body["pum_Resource@odata.bind"]   = "/pum_resources($resId)" }
    if ($iniId)  { $body["pum_Initiative@odata.bind"] = "/pum_initiatives($iniId)" }
    if ($progId) { $body["pum_Program@odata.bind"]    = "/pum_programs($progId)" }
    Post-Record "pum_teammemberses" $body "pum_teammembersid" "TeamMember: $name"
}

# Program team members
Add-TeamMember $r1  $null $prog1 "Alice Johnson (PM - Prog1)"
Add-TeamMember $r9  $null $prog2 "Isabelle Dupont (PM - Prog2)"
Add-TeamMember $r1  $null $prog3 "Alice Johnson (PM - Prog3)"
Add-TeamMember $r9  $null $prog4 "Isabelle Dupont (PM - Prog4)"

# Initiative team members
Add-TeamMember $r3  $ini1  $null "Carol White (BA - Portal)"
Add-TeamMember $r4  $ini1  $null "David Brown (Dev - Portal)"
Add-TeamMember $r7  $ini1  $null "Grace Kim (UX - Portal)"
Add-TeamMember $r6  $ini1  $null "Frank Lee (QA - Portal)"

Add-TeamMember $r4  $ini2  $null "David Brown (Dev - Mobile)"
Add-TeamMember $r5  $ini2  $null "Eva Martinez (Dev - Mobile)"
Add-TeamMember $r6  $ini2  $null "Frank Lee (QA - Mobile)"
Add-TeamMember $r8  $ini2  $null "Henry Chen (DevOps - Mobile)"

Add-TeamMember $r3  $ini3  $null "Carol White (BA - CRM)"
Add-TeamMember $r2  $ini3  $null "Bob Smith (Arch - CRM)"
Add-TeamMember $r5  $ini3  $null "Eva Martinez (Dev - CRM)"

Add-TeamMember $r2  $ini4  $null "Bob Smith (Arch - DataLake)"
Add-TeamMember $r4  $ini4  $null "David Brown (Dev - DataLake)"
Add-TeamMember $r8  $ini4  $null "Henry Chen (DevOps - DataLake)"

Add-TeamMember $r4  $ini5  $null "David Brown (Dev - ML)"
Add-TeamMember $r5  $ini5  $null "Eva Martinez (Dev - ML)"

Add-TeamMember $r3  $ini8  $null "Carol White (BA - Finance ERP)"
Add-TeamMember $r2  $ini8  $null "Bob Smith (Arch - Finance ERP)"
Add-TeamMember $r10 $ini8  $null "James Wilson (Dev - Finance ERP)"

Add-TeamMember $r3  $ini10 $null "Carol White (BA - Onboarding)"
Add-TeamMember $r7  $ini10 $null "Grace Kim (UX - Onboarding)"
Add-TeamMember $r10 $ini10 $null "James Wilson (Dev - Onboarding)"

Add-TeamMember $r8  $ini12 $null "Henry Chen (DevOps - M365)"
Add-TeamMember $r6  $ini12 $null "Frank Lee (QA - M365)"

# ─────────────────────────────────────────────────────────────
# PHASE 12 — RISKS
# ─────────────────────────────────────────────────────────────
Write-Host "`nPhase 12: Risks" -ForegroundColor Yellow
# pum_riskstatus: 493840000=Identified, 493840001=Active, 493840002=Mitigated, 493840003=Resolved, 436130000=Issue
# pum_probability: 976880001=20%, 976880002=40%, 976880003=60%, 976880004=80%
# pum_riskimpact: 976880000=VeryLow, 976880001=Low, 976880002=Medium, 976880003=High, 976880004=Extreme

function New-Risk { param($name,$desc,$mitigation,$iniId,$portId,$progId,$status,$prob,$impact,$cost,$dueDate)
    $body = @{
        pum_name        = $name
        pum_riskdescription = $desc
        pum_riskmitigation  = $mitigation
        pum_riskstatus  = $status
        pum_probability = $prob
        pum_riskimpact  = $impact
        pum_riskcost    = $cost
        pum_riskduedate = $dueDate
    }
    if ($iniId)  { $body["pum_Initiative@odata.bind"] = "/pum_initiatives($iniId)" }
    if ($portId) { $body["pum_Portfolio@odata.bind"]  = "/pum_portfolios($portId)" }
    if ($progId) { $body["pum_Program@odata.bind"]    = "/pum_programs($progId)" }
    Post-Record "pum_risks" $body "pum_riskid" "Risk: $name"
}

New-Risk "Legacy API Incompatibility" `    "Third-party APIs used in portal may not support OAuth 2.0 required by new platform" `    "Conduct API audit in Sprint 1; engage vendors for migration roadmap if needed" `    $ini1 $portDT $null 493840001 976880003 60000 "2025-04-30T00:00:00Z"

New-Risk "Scope Creep from Stakeholders" `    "Business stakeholders continue requesting feature additions after design freeze" `    "Strict change control board — any new request goes through formal impact assessment" `    $ini1 $portDT $null 493840001 976880004 40000 "2025-05-15T00:00:00Z"

New-Risk "Offline Sync Data Conflicts" `    "Concurrent edits by field users when device reconnects may cause data inconsistencies" `    "Implement conflict resolution UI and last-write-wins fallback with audit log" `    $ini2 $portDT $null 493840001 976880002 15000 "2025-06-30T00:00:00Z"

New-Risk "Device Fragmentation" `    "Wide variety of Android device models in field may cause rendering or performance issues" `    "Define supported device matrix; conduct compatibility testing on top 10 models" `    $ini2 $portDT $null 493840002 976880002 8000 "2025-05-01T00:00:00Z"

New-Risk "CRM Data Quality Issues" `    "Source CRM data has duplicate records and inconsistent formats affecting integration quality" `    "Run data profiling tool pre-integration; deduplicate and standardize before go-live" `    $ini3 $portDT $null 493840001 976880003 25000 "2025-08-31T00:00:00Z"

New-Risk "Data Lake Storage Cost Overrun" `    "Raw data volume from source systems exceeds initial sizing estimates by up to 3x" `    "Implement tiered storage policy and lifecycle management to control costs" `    $ini4 $portDT $null 493840002 976880002 90000 "2025-07-31T00:00:00Z"

New-Risk "ML Model Bias in Sales Forecasting" `    "Training data may not represent seasonal anomalies, leading to inaccurate Q4 predictions" `    "Include synthetic data for rare events; implement ongoing model drift monitoring" `    $ini5 $portDT $null 493840001 976880003 0 "2025-10-31T00:00:00Z"

New-Risk "ERP Vendor Support Gap" `    "Current on-premises ERP version reaches end-of-support before migration completes" `    "Negotiate extended support agreement with vendor; prioritize finance modules in migration" `    $ini8 $portEE $null 493840001 976880004 200000 "2025-12-31T00:00:00Z"

New-Risk "Data Loss During ERP Migration" `    "Incomplete mapping of custom fields may result in data loss during finance module cutover" `    "Full field-level mapping review; parallel run for 90 days; rollback plan documented" `    $ini8 $portEE $null 493840001 976880004 500000 "2026-06-30T00:00:00Z"

New-Risk "Key Resource Unavailability" `    "Lead architect (Bob Smith) has competing commitments that may reduce capacity 50% in Q3" `    "Identify backup architect; document key design decisions to reduce single-point dependency" `    $null $portDT $prog2 493840001 976880003 80000 "2025-09-30T00:00:00Z"

New-Risk "GDPR Compliance Gap in New Portal" `    "New portal's data residency and consent management may not meet GDPR requirements at launch" `    "Engage DPO for privacy-by-design review in Sprint 2; conduct DPIA before go-live" `    $ini1 $portDT $null 493840001 976880004 120000 "2025-08-31T00:00:00Z"

New-Risk "Teams Adoption Resistance" `    "Employees accustomed to email-first culture may resist migrating to Teams for collaboration" `    "Change management program: champions network, training sessions, and usage dashboards" `    $ini12 $portEE $null 493840001 976880002 30000 "2025-11-30T00:00:00Z"

New-Risk "Supply Chain Module Integration Complexity" `    "SCM module integration with 5 external logistics providers is significantly more complex than estimated" `    "Bring in SI partner with ERP SCM expertise; revise project timeline accordingly" `    $ini9 $portEE $null 493840001 976880003 150000 "2026-09-30T00:00:00Z"

New-Risk "Compliance Report Accuracy" `    "Automated GDPR reports may miss data flows through undocumented shadow IT systems" `    "Conduct shadow IT audit; include API gateway monitoring to capture all data flows" `    $ini11 $portEE $null 493840001 976880004 0 "2026-01-31T00:00:00Z"

New-Risk "Budget Overrun — Data Lake" `    "Phase 1 data lake cost has exceeded initial estimate by 18% due to unexpected data quality work" `    "Revise Phase 2 scope; present revised business case to portfolio steering committee" `    $ini4 $portDT $null 436130000 976880004 180000 "2025-11-30T00:00:00Z"

# ─────────────────────────────────────────────────────────────
# PHASE 13 — CHANGE REQUESTS
# ─────────────────────────────────────────────────────────────
Write-Host "`nPhase 13: Change Requests" -ForegroundColor Yellow

function New-CR { param($title,$desc,$iniId,$changeNo,$approved)
    $body = @{
        pum_name        = $title
        pum_description = $desc
        pum_changeno    = $changeNo
        pum_approved    = $approved
    }
    if ($iniId) { $body["pum_Initiative@odata.bind"] = "/pum_initiatives($iniId)" }
    if ($approved) { $body["pum_dateapproved"] = (Get-Date).AddDays(-30).ToString("yyyy-MM-ddTHH:mm:ssZ") }
    Post-Record "pum_changerequests" $body "pum_changerequestid" "CR: $title"
}

New-CR "Add Accessibility (WCAG 2.1 AA) to Portal"    "Business requires WCAG 2.1 AA compliance for all portal pages — adds 3 sprints"                   $ini1  "CR-001" $true
New-CR "Extend Portal to Support 5 Languages"          "Marketing requests multilingual support; requires i18n framework and translation pipeline"           $ini1  "CR-002" $false
New-CR "Add Barcode Scanning to Mobile App"            "Field teams need barcode scanner integration for equipment tracking"                                 $ini2  "CR-003" $true
New-CR "Integrate with SAP HR for Org Chart Data"      "CRM integration scope extended to pull org chart data from SAP HR module"                           $ini3  "CR-004" $true
New-CR "Add Real-Time Anomaly Detection to Data Lake"  "Data team requests streaming anomaly detection pipeline alongside batch ingestion"                   $ini4  "CR-005" $false
New-CR "Extend Finance Module to Include Tax Reporting" "Tax team requires automated VAT and withholding tax reporting as part of finance migration"         $ini8  "CR-006" $true
New-CR "Add SSO to Digital Onboarding Portal"          "IT security requires SSO via Azure AD for all new onboarding portal users"                          $ini10 "CR-007" $true
New-CR "Include Copilot for All Users in M365 Rollout" "Executive request to include Microsoft 365 Copilot licences for all knowledge workers"              $ini12 "CR-008" $false

# ─────────────────────────────────────────────────────────────
# PHASE 14 — STATUS REPORTS
# ─────────────────────────────────────────────────────────────
Write-Host "`nPhase 14: Status Reports" -ForegroundColor Yellow
# pum_kpinewsummary/cost/schedule etc. use same KPI option set
# 493840000=Not Set, 493840001=Need help, 493840002=At risk, 493840003=No issue

function New-StatusReport { param($name,$iniId,$progId,$comment,$phase,$kpiSummary,$kpiCost,$kpiSchedule,$kpiScope,$progress,$budget,$actual)
    $body = @{
        pum_name             = $name
        pum_comment          = $comment
        pum_currentphase     = $phase
        pum_kpinewsummary    = $kpiSummary
        pum_kpinewcost       = $kpiCost
        pum_kpinewschedule   = $kpiSchedule
        pum_kpinewscope      = $kpiScope
        pum_scheduleprogress = $progress
        pum_budget           = $budget
        pum_actualcost       = $actual
        pum_statusdate       = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        pum_statuscategory   = 493840000
    }
    if ($iniId)  { $body["pum_Initiative@odata.bind"] = "/pum_initiatives($iniId)" }
    if ($progId) { $body["pum_Program@odata.bind"]    = "/pum_programs($progId)" }
    Post-Record "pum_statusreportings" $body "pum_statusreportingid" "StatusReport: $name"
}

New-StatusReport "Portal Redesign - April Status"     $ini1 $null "Development on track. AI chatbot integration completed ahead of schedule. UAT planned for May."               "Development"      493840003 493840003 493840003 493840003 72  850000 610000
New-StatusReport "Mobile App - April Status"          $ini2 $null "Offline sync complexity higher than estimated. Risk raised. Revised plan submitted to steering committee."  "Development"      493840002 493840002 493840002 493840003 58  480000 305000
New-StatusReport "CRM Integration - March Status"     $ini3 $null "Requirements phase complete. Architecture approved. Development kick-off scheduled for April 15th."          "Design"           493840003 493840003 493840003 493840003 25  620000  82000
New-StatusReport "Data Lake Ph1 - April Status"       $ini4 $null "9 of 12 source systems onboarded. Data quality issues in legacy CRM causing delays."                        "Execution"        493840002 493840001 493840002 493840003 68 1200000 870000
New-StatusReport "Sales ML Model - March Status"      $ini5 $null "Model training completed. Accuracy at 87% — below 90% target. Re-training with enriched dataset underway."  "Testing"          493840002 493840003 493840002 493840002 55  380000 225000
New-StatusReport "ERP Assessment - Final Status"      $ini7 $null "Assessment completed successfully. Blueprint approved by executive committee. Project closed."               "Closed"           493840003 493840003 493840003 493840003 100 280000 265000
New-StatusReport "Finance ERP - April Status"         $ini8 $null "Configuration 60% complete. Data migration readiness assessment scheduled for May. EOS risk active."        "Configuration"    493840002 493840002 493840002 493840003 42 1400000 590000
New-StatusReport "M365 Rollout - April Status"        $ini12 $null "Tenant configured. Pilot group of 200 users live. Full rollout begins May 1st. No major issues."          "Pilot Rollout"    493840003 493840003 493840003 493840003 35  420000 148000

# ─────────────────────────────────────────────────────────────
# PHASE 15 — LESSONS LEARNED
# ─────────────────────────────────────────────────────────────
Write-Host "`nPhase 15: Lessons Learned" -ForegroundColor Yellow
# pum_impact: try common Projectum values; pum_learningcategory: similar
# We'll omit picklist fields we haven't verified

function New-LL { param($title,$desc,$iniId)
    $body = @{
        pum_name        = $title
        pum_description = $desc
    }
    if ($iniId) { $body["pum_Initiative@odata.bind"] = "/pum_initiatives($iniId)" }
    Post-Record "pum_lessonslearneds" $body "pum_lessonslearnedid" "LL: $title"
}

New-LL "Involve DPO from Day 1" `    "GDPR review in Sprint 5 caused rework on consent flows. Engaging the DPO in Sprint 1 would have saved 3 weeks of remediation work." $ini1
New-LL "API Audit Before Architecture Design" `    "Legacy API audit should have been part of inception phase. Discovering OAuth incompatibilities during build required design changes." $ini1
New-LL "Mobile Device Test Matrix Must Be Defined Early" `    "Device fragmentation testing started too late. Future mobile projects should establish supported device matrix in Sprint 0." $ini2
New-LL "Offline Sync Requires Dedicated Architecture Spike" `    "Underestimating offline sync complexity led to mid-project design changes. Allocate a full sprint for proof-of-concept before committing to architecture." $ini2
New-LL "Data Quality Must Be Assessed Before Integration Starts" `    "CRM data quality issues discovered during integration delayed go-live by 6 weeks. Pre-integration data profiling is now mandatory." $ini3
New-LL "Data Lake Sizing Should Use 3x Safety Margin" `    "Initial data volume estimates were 3x lower than actuals due to undocumented historical data. Future lake projects must include buffer capacity." $ini4
New-LL "Parallel Run Period Saved the ERP Cutover" `    "90-day parallel run between legacy and new ERP caught 47 discrepancies before cutover. Never skip parallel run for financial systems." $ini7
New-LL "Executive Sponsorship is Critical for Culture Change" `    "Compliance reporting adoption was low until CFO personally endorsed the tool in an all-hands. Secure executive sponsorship before rollout." $ini11
New-LL "Change Management Budget Was Insufficient" `    "M365 adoption training was underbudgeted. Resistance from email-first users required additional workshops and a champions network to overcome." $ini12
New-LL "Involve IT Security in Architecture Reviews" `    "SSO requirement was raised post-design causing rework. IT Security should be a standing member of all architecture review boards going forward." $ini10

# ─────────────────────────────────────────────────────────────
# PHASE 16 — STAKEHOLDERS
# ─────────────────────────────────────────────────────────────
Write-Host "`nPhase 16: Stakeholders" -ForegroundColor Yellow
# pum_influence/interest: need values — omit for now, focus on names and type
# pum_stakeholdertype: try 493840000, 493840001

function New-Stakeholder { param($name,$initials,$iniId,$progId,$type,$email)
    $body = @{
        pum_name              = $name
        pum_stakeholderinitials = $initials
        pum_stakeholdertype   = $type
    }
    if ($email)  { $body["pum_emailexternal"] = $email }
    if ($iniId)  { $body["pum_Initiative@odata.bind"] = "/pum_initiatives($iniId)" }
    if ($progId) { $body["pum_Program@odata.bind"]    = "/pum_programs($progId)" }
    Post-Record "pum_stakeholders" $body "pum_stakeholderid" "Stakeholder: $name"
}

# Type: 493840000 / 493840001 (internal/external — guessing; will set null if wrong)
New-Stakeholder "Michael Thompson (CIO)"       "MT" $null $prog1 493840000 $null
New-Stakeholder "Sarah Ng (CFO)"               "SN" $null $prog3 493840000 $null
New-Stakeholder "Rachel Foster (CDO)"          "RF" $null $prog2 493840000 $null
New-Stakeholder "Tom Bradley (VP Operations)"  "TB" $null $prog4 493840000 $null
New-Stakeholder "Emily Clarke (PMO Director)"  "EC" $ini1 $null  493840000 $null
New-Stakeholder "Kevin Park (Head of Sales)"   "KP" $ini5 $null  493840000 $null
New-Stakeholder "Anna Schmidt (Legal/DPO)"     "AS" $ini1 $null  493840000 $null
New-Stakeholder "John Davis (IT Security)"     "JD" $ini3 $null  493840000 $null
New-Stakeholder "Accenture - SI Partner"       "AC" $null $prog3 493840001 "delivery@accenture.com"
New-Stakeholder "Microsoft - Account Team"     "MS" $ini12 $null 493840001 "enterprise@microsoft.com"
New-Stakeholder "Salesforce - Support"         "SF" $ini3 $null  493840001 "support@salesforce.com"
New-Stakeholder "KPMG - External Auditor"      "KG" $ini11 $null 493840001 "audit@kpmg.com"

# ─────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Creation Complete!" -ForegroundColor Cyan
Write-Host "  Succeeded : $($script:ok)"  -ForegroundColor Green
Write-Host "  Failed    : $($script:err)" -ForegroundColor $(if ($script:err -gt 0) { "Red" } else { "Green" })
Write-Host "============================================" -ForegroundColor Cyan
