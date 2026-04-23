#!/usr/bin/env pwsh
# Creates financial data for all 12 xPM initiatives:
#   - 4 Cost Specifications (shared reference data)
#   - 1 Cost Plan Version per initiative
#   - Budget / Actuals / Forecast rows per initiative × cost spec × year

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

# ── Reference IDs (Financial Structure a452c3a9) ─────────────────────────
$fsId       = "a452c3a9-2a3f-f111-bec6-70a8a59a44c4"
$areaCapex  = "c652c3a9-2a3f-f111-bec6-70a8a59a44c4"
$areaOpex   = "cc52c3a9-2a3f-f111-bec6-70a8a59a44c4"
$typeBudget  = "ad52c3a9-2a3f-f111-bec6-70a8a59a44c4"
$typeActuals = "b652c3a9-2a3f-f111-bec6-70a8a59a44c4"
$typeFcast   = "bc52c3a9-2a3f-f111-bec6-70a8a59a44c4"
$catIntCapex = "d152c3a9-2a3f-f111-bec6-70a8a59a44c4"   # Internal Resources (CAPEX) def=1
$catExtCapex = "e452c3a9-2a3f-f111-bec6-70a8a59a44c4"   # External Resources (CAPEX) def=2
$catSoftCap  = "fd52c3a9-2a3f-f111-bec6-70a8a59a44c4"   # Capitalized Software & Technology def=4
$catIntOpex  = "3d53c3a9-2a3f-f111-bec6-70a8a59a44c4"   # Internal Resources (OPEX) def=101
$catLicOpex  = "4f53c3a9-2a3f-f111-bec6-70a8a59a44c4"   # Licenses & Subscriptions (OPEX) def=102

# ── Step 1: Cost Specifications ───────────────────────────────────────────
Write-Host "`nCreating Cost Specifications..." -ForegroundColor Yellow

$specIntLabCapex = Post-Record "pum_pf_costspecifications" @{
    pum_costspecification = "Internal Labor (CAPEX)"
    pum_pf_costspec_order = 1
    "pum_FinancialStructure@odata.bind"           = "/pum_financialstructures($fsId)"
    "pum_pf_costspec_pf_costarea@odata.bind"      = "/pum_pf_costareas($areaCapex)"
    "pum_pf_costspec_pf_costcategory@odata.bind"  = "/pum_pf_costcategories($catIntCapex)"
} "pum_pf_costspecificationid" "CostSpec: Internal Labor (CAPEX)"

$specExtConsCapex = Post-Record "pum_pf_costspecifications" @{
    pum_costspecification = "External Consulting (CAPEX)"
    pum_pf_costspec_order = 2
    "pum_FinancialStructure@odata.bind"           = "/pum_financialstructures($fsId)"
    "pum_pf_costspec_pf_costarea@odata.bind"      = "/pum_pf_costareas($areaCapex)"
    "pum_pf_costspec_pf_costcategory@odata.bind"  = "/pum_pf_costcategories($catExtCapex)"
} "pum_pf_costspecificationid" "CostSpec: External Consulting (CAPEX)"

$specSoftCapex = Post-Record "pum_pf_costspecifications" @{
    pum_costspecification = "Software & Technology (CAPEX)"
    pum_pf_costspec_order = 3
    "pum_FinancialStructure@odata.bind"           = "/pum_financialstructures($fsId)"
    "pum_pf_costspec_pf_costarea@odata.bind"      = "/pum_pf_costareas($areaCapex)"
    "pum_pf_costspec_pf_costcategory@odata.bind"  = "/pum_pf_costcategories($catSoftCap)"
} "pum_pf_costspecificationid" "CostSpec: Software & Technology (CAPEX)"

$specIntOpsOpex = Post-Record "pum_pf_costspecifications" @{
    pum_costspecification = "Internal Operations (OPEX)"
    pum_pf_costspec_order = 4
    "pum_FinancialStructure@odata.bind"           = "/pum_financialstructures($fsId)"
    "pum_pf_costspec_pf_costarea@odata.bind"      = "/pum_pf_costareas($areaOpex)"
    "pum_pf_costspec_pf_costcategory@odata.bind"  = "/pum_pf_costcategories($catIntOpex)"
} "pum_pf_costspecificationid" "CostSpec: Internal Operations (OPEX)"

$specLicOpex = Post-Record "pum_pf_costspecifications" @{
    pum_costspecification = "Software Licenses (OPEX)"
    pum_pf_costspec_order = 5
    "pum_FinancialStructure@odata.bind"           = "/pum_financialstructures($fsId)"
    "pum_pf_costspec_pf_costarea@odata.bind"      = "/pum_pf_costareas($areaOpex)"
    "pum_pf_costspec_pf_costcategory@odata.bind"  = "/pum_pf_costcategories($catLicOpex)"
} "pum_pf_costspecificationid" "CostSpec: Software Licenses (OPEX)"

Write-Host "  Cost Specs: IntLabCapex=$specIntLabCapex" -ForegroundColor DarkGray
Write-Host "              ExtConsCapex=$specExtConsCapex" -ForegroundColor DarkGray
Write-Host "              SoftCapex=$specSoftCapex" -ForegroundColor DarkGray
Write-Host "              IntOpsOpex=$specIntOpsOpex" -ForegroundColor DarkGray
Write-Host "              LicOpex=$specLicOpex" -ForegroundColor DarkGray

# ── Helper: create financial data row ─────────────────────────────────────
function New-FinRow {
    param(
        [string]$IniId, [string]$CpvId,
        [string]$SpecId, [string]$AreaId, [string]$CatId, [string]$TypeId,
        [decimal]$Value, [int]$Year, [string]$Label
    )
    $body = @{
        pum_pf_year     = $Year
        pum_pf_month    = 0
        pum_pf_valuedec = [double]$Value
        pum_pf_value    = [double]$Value
        "pum_pf_initiative@odata.bind"        = "/pum_initiatives($IniId)"
        "pum_pf_costplan_version@odata.bind"  = "/pum_pf_costplan_versions($CpvId)"
        "pum_pf_costspecification@odata.bind" = "/pum_pf_costspecifications($SpecId)"
        "pum_pf_costarea@odata.bind"          = "/pum_pf_costareas($AreaId)"
        "pum_pf_costcategory@odata.bind"      = "/pum_pf_costcategories($CatId)"
        "pum_pf_costtype@odata.bind"          = "/pum_pf_costtypes($TypeId)"
        "pum_FinancialStructure@odata.bind"   = "/pum_financialstructures($fsId)"
    }
    Post-Record "pum_pf_powerfinancialsdatas" $body "pum_pf_powerfinancialsdataid" "  FinRow: $Label" | Out-Null
}

# ── Step 2: Per-initiative financial data ─────────────────────────────────
# Columns per initiative:
#  @(iniId, name, cpvName, @( @(spec,area,cat,type,value,year,label), ... ))
# Budget type for all periods; Actuals for completed years; Forecast for future

$today = [DateTime]"2026-04-23"

$initiatives = @(
    @{
        Id="d6351a72-0a3f-f111-bec6-70a8a59a44c4"; Name="Customer Self-Service Portal Redesign"
        CpvName="Budget Plan 2025"; Status="Complete"
        Rows=@(
            # Budget
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeBudget,480000,2025,"Budget IntLab 2025")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeBudget,320000,2025,"Budget ExtCons 2025")
            ,@($specSoftCapex,$areaCapex,$catSoftCap,$typeBudget,250000,2025,"Budget Soft 2025")
            ,@($specIntOpsOpex,$areaOpex,$catIntOpex,$typeBudget,150000,2025,"Budget IntOps 2025")
            # Actuals (complete)
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeActuals,478500,2025,"Actuals IntLab 2025")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeActuals,315000,2025,"Actuals ExtCons 2025")
            ,@($specSoftCapex,$areaCapex,$catSoftCap,$typeActuals,248000,2025,"Actuals Soft 2025")
            ,@($specIntOpsOpex,$areaOpex,$catIntOpex,$typeActuals,148500,2025,"Actuals IntOps 2025")
        )
    }
    @{
        Id="f8351a72-0a3f-f111-bec6-70a8a59a44c4"; Name="Mobile App for Field Service"
        CpvName="Budget Plan 2025"; Status="Complete"
        Rows=@(
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeBudget,180000,2025,"Budget IntLab 2025")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeBudget,120000,2025,"Budget ExtCons 2025")
            ,@($specSoftCapex,$areaCapex,$catSoftCap,$typeBudget,80000,2025,"Budget Soft 2025")
            ,@($specLicOpex,$areaOpex,$catLicOpex,$typeBudget,70000,2025,"Budget Lic 2025")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeActuals,182000,2025,"Actuals IntLab 2025")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeActuals,118500,2025,"Actuals ExtCons 2025")
            ,@($specSoftCapex,$areaCapex,$catSoftCap,$typeActuals,79000,2025,"Actuals Soft 2025")
            ,@($specLicOpex,$areaOpex,$catLicOpex,$typeActuals,68000,2025,"Actuals Lic 2025")
        )
    }
    @{
        Id="18361a72-0a3f-f111-bec6-70a8a59a44c4"; Name="CRM Integration & Automation"
        CpvName="Budget Plan 2025-2026"; Status="Complete"
        Rows=@(
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeBudget,150000,2025,"Budget IntLab 2025")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeBudget,100000,2025,"Budget ExtCons 2025")
            ,@($specIntOpsOpex,$areaOpex,$catIntOpex,$typeBudget,60000,2025,"Budget IntOps 2025")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeBudget,40000,2026,"Budget IntLab 2026")
            ,@($specIntOpsOpex,$areaOpex,$catIntOpex,$typeBudget,30000,2026,"Budget IntOps 2026")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeActuals,152000,2025,"Actuals IntLab 2025")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeActuals,98000,2025,"Actuals ExtCons 2025")
            ,@($specIntOpsOpex,$areaOpex,$catIntOpex,$typeActuals,59500,2025,"Actuals IntOps 2025")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeActuals,38000,2026,"Actuals IntLab 2026")
            ,@($specIntOpsOpex,$areaOpex,$catIntOpex,$typeActuals,28500,2026,"Actuals IntOps 2026")
        )
    }
    @{
        Id="37361a72-0a3f-f111-bec6-70a8a59a44c4"; Name="Enterprise Data Lake Phase 1"
        CpvName="Budget Plan 2025"; Status="Complete"
        Rows=@(
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeBudget,700000,2025,"Budget IntLab 2025")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeBudget,500000,2025,"Budget ExtCons 2025")
            ,@($specSoftCapex,$areaCapex,$catSoftCap,$typeBudget,600000,2025,"Budget Soft 2025")
            ,@($specIntOpsOpex,$areaOpex,$catIntOpex,$typeBudget,300000,2025,"Budget IntOps 2025")
            # Overrun on actuals
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeActuals,720000,2025,"Actuals IntLab 2025")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeActuals,540000,2025,"Actuals ExtCons 2025")
            ,@($specSoftCapex,$areaCapex,$catSoftCap,$typeActuals,615000,2025,"Actuals Soft 2025")
            ,@($specIntOpsOpex,$areaOpex,$catIntOpex,$typeActuals,405000,2025,"Actuals IntOps 2025")
        )
    }
    @{
        Id="b7611778-0a3f-f111-bec6-70a8a59a44c4"; Name="Sales Forecasting ML Model"
        CpvName="Budget Plan 2025-2026"; Status="Complete"
        Rows=@(
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeBudget,120000,2025,"Budget IntLab 2025")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeBudget,80000,2025,"Budget ExtCons 2025")
            ,@($specSoftCapex,$areaCapex,$catSoftCap,$typeBudget,40000,2025,"Budget Soft 2025")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeBudget,25000,2026,"Budget IntLab 2026")
            ,@($specLicOpex,$areaOpex,$catLicOpex,$typeBudget,15000,2026,"Budget Lic 2026")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeActuals,118000,2025,"Actuals IntLab 2025")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeActuals,79500,2025,"Actuals ExtCons 2025")
            ,@($specSoftCapex,$areaCapex,$catSoftCap,$typeActuals,39000,2025,"Actuals Soft 2025")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeActuals,24500,2026,"Actuals IntLab 2026")
            ,@($specLicOpex,$areaOpex,$catLicOpex,$typeActuals,14000,2026,"Actuals Lic 2026")
        )
    }
    @{
        Id="52621778-0a3f-f111-bec6-70a8a59a44c4"; Name="Digital Onboarding Platform"
        CpvName="Budget Plan 2025-2026"; Status="Complete"
        Rows=@(
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeBudget,120000,2025,"Budget IntLab 2025")
            ,@($specSoftCapex,$areaCapex,$catSoftCap,$typeBudget,70000,2025,"Budget Soft 2025")
            ,@($specIntOpsOpex,$areaOpex,$catIntOpex,$typeBudget,50000,2025,"Budget IntOps 2025")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeBudget,30000,2026,"Budget IntLab 2026")
            ,@($specLicOpex,$areaOpex,$catLicOpex,$typeBudget,20000,2026,"Budget Lic 2026")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeActuals,119000,2025,"Actuals IntLab 2025")
            ,@($specSoftCapex,$areaCapex,$catSoftCap,$typeActuals,68500,2025,"Actuals Soft 2025")
            ,@($specIntOpsOpex,$areaOpex,$catIntOpex,$typeActuals,49500,2025,"Actuals IntOps 2025")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeActuals,29000,2026,"Actuals IntLab 2026")
            ,@($specLicOpex,$areaOpex,$catLicOpex,$typeActuals,19500,2026,"Actuals Lic 2026")
        )
    }
    @{
        Id="f5611778-0a3f-f111-bec6-70a8a59a44c4"; Name="ERP Assessment & Blueprint"
        CpvName="Budget Plan 2025"; Status="Complete"
        Rows=@(
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeBudget,80000,2025,"Budget IntLab 2025")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeBudget,70000,2025,"Budget ExtCons 2025")
            ,@($specIntOpsOpex,$areaOpex,$catIntOpex,$typeBudget,30000,2025,"Budget IntOps 2025")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeActuals,79000,2025,"Actuals IntLab 2025")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeActuals,70500,2025,"Actuals ExtCons 2025")
            ,@($specIntOpsOpex,$areaOpex,$catIntOpex,$typeActuals,30500,2025,"Actuals IntOps 2025")
        )
    }
    @{
        Id="14621778-0a3f-f111-bec6-70a8a59a44c4"; Name="Finance Module Cloud Migration"
        CpvName="Budget Plan 2025-2026"; Status="InProgress"
        Rows=@(
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeBudget,800000,2025,"Budget IntLab 2025")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeBudget,600000,2025,"Budget ExtCons 2025")
            ,@($specSoftCapex,$areaCapex,$catSoftCap,$typeBudget,400000,2025,"Budget Soft 2025")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeBudget,600000,2026,"Budget IntLab 2026")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeBudget,500000,2026,"Budget ExtCons 2026")
            ,@($specSoftCapex,$areaCapex,$catSoftCap,$typeBudget,200000,2026,"Budget Soft 2026")
            ,@($specLicOpex,$areaOpex,$catLicOpex,$typeBudget,100000,2026,"Budget Lic 2026")
            # Actuals 2025 (complete year)
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeActuals,810000,2025,"Actuals IntLab 2025")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeActuals,595000,2025,"Actuals ExtCons 2025")
            ,@($specSoftCapex,$areaCapex,$catSoftCap,$typeActuals,405000,2025,"Actuals Soft 2025")
            # Actuals 2026 partial (through Apr)
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeActuals,200000,2026,"Actuals IntLab 2026 (YTD)")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeActuals,165000,2026,"Actuals ExtCons 2026 (YTD)")
            # Forecast remaining 2026
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeFcast,400000,2026,"Forecast IntLab 2026")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeFcast,335000,2026,"Forecast ExtCons 2026")
            ,@($specSoftCapex,$areaCapex,$catSoftCap,$typeFcast,200000,2026,"Forecast Soft 2026")
            ,@($specLicOpex,$areaOpex,$catLicOpex,$typeFcast,100000,2026,"Forecast Lic 2026")
        )
    }
    @{
        Id="17154a7e-0a3f-f111-bec6-70a8a59a44c4"; Name="M365 Collaboration Rollout"
        CpvName="Budget Plan 2025-2026"; Status="NearlyComplete"
        Rows=@(
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeBudget,120000,2025,"Budget IntLab 2025")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeBudget,80000,2025,"Budget ExtCons 2025")
            ,@($specLicOpex,$areaOpex,$catLicOpex,$typeBudget,120000,2025,"Budget Lic 2025")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeBudget,50000,2026,"Budget IntLab 2026")
            ,@($specLicOpex,$areaOpex,$catLicOpex,$typeBudget,50000,2026,"Budget Lic 2026")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeActuals,118500,2025,"Actuals IntLab 2025")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeActuals,79000,2025,"Actuals ExtCons 2025")
            ,@($specLicOpex,$areaOpex,$catLicOpex,$typeActuals,118000,2025,"Actuals Lic 2025")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeActuals,48000,2026,"Actuals IntLab 2026 (YTD)")
            ,@($specLicOpex,$areaOpex,$catLicOpex,$typeActuals,20000,2026,"Actuals Lic 2026 (YTD)")
            ,@($specLicOpex,$areaOpex,$catLicOpex,$typeFcast,30000,2026,"Forecast Lic 2026")
        )
    }
    @{
        Id="d6611778-0a3f-f111-bec6-70a8a59a44c4"; Name="Real-Time Analytics Dashboard"
        CpvName="Budget Plan 2025-2026"; Status="InProgress"
        Rows=@(
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeBudget,100000,2025,"Budget IntLab 2025")
            ,@($specSoftCapex,$areaCapex,$catSoftCap,$typeBudget,80000,2025,"Budget Soft 2025")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeBudget,100000,2026,"Budget IntLab 2026")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeBudget,50000,2026,"Budget ExtCons 2026")
            ,@($specLicOpex,$areaOpex,$catLicOpex,$typeBudget,20000,2026,"Budget Lic 2026")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeActuals,98000,2025,"Actuals IntLab 2025")
            ,@($specSoftCapex,$areaCapex,$catSoftCap,$typeActuals,78500,2025,"Actuals Soft 2025")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeActuals,40000,2026,"Actuals IntLab 2026 (YTD)")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeActuals,18000,2026,"Actuals ExtCons 2026 (YTD)")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeFcast,60000,2026,"Forecast IntLab 2026")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeFcast,32000,2026,"Forecast ExtCons 2026")
            ,@($specLicOpex,$areaOpex,$catLicOpex,$typeFcast,20000,2026,"Forecast Lic 2026")
        )
    }
    @{
        Id="71621778-0a3f-f111-bec6-70a8a59a44c4"; Name="Automated Compliance Reporting"
        CpvName="Budget Plan 2025-2026"; Status="Complete"
        Rows=@(
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeBudget,130000,2025,"Budget IntLab 2025")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeBudget,80000,2025,"Budget ExtCons 2025")
            ,@($specSoftCapex,$areaCapex,$catSoftCap,$typeBudget,60000,2025,"Budget Soft 2025")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeBudget,60000,2026,"Budget IntLab 2026")
            ,@($specIntOpsOpex,$areaOpex,$catIntOpex,$typeBudget,50000,2026,"Budget IntOps 2026")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeActuals,128500,2025,"Actuals IntLab 2025")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeActuals,79500,2025,"Actuals ExtCons 2025")
            ,@($specSoftCapex,$areaCapex,$catSoftCap,$typeActuals,59000,2025,"Actuals Soft 2025")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeActuals,59500,2026,"Actuals IntLab 2026")
            ,@($specIntOpsOpex,$areaOpex,$catIntOpex,$typeActuals,49000,2026,"Actuals IntOps 2026")
        )
    }
    @{
        Id="33621778-0a3f-f111-bec6-70a8a59a44c4"; Name="Supply Chain Module Implementation"
        CpvName="Budget Plan 2026-2027"; Status="NotStarted"
        Rows=@(
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeBudget,600000,2026,"Budget IntLab 2026")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeBudget,700000,2026,"Budget ExtCons 2026")
            ,@($specSoftCapex,$areaCapex,$catSoftCap,$typeBudget,400000,2026,"Budget Soft 2026")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeBudget,500000,2027,"Budget IntLab 2027")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeBudget,350000,2027,"Budget ExtCons 2027")
            ,@($specLicOpex,$areaOpex,$catLicOpex,$typeBudget,250000,2027,"Budget Lic 2027")
            # Small actuals (just started Apr 2026)
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeActuals,45000,2026,"Actuals IntLab 2026 (YTD)")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeActuals,30000,2026,"Actuals ExtCons 2026 (YTD)")
            # Forecast remaining
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeFcast,555000,2026,"Forecast IntLab 2026")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeFcast,670000,2026,"Forecast ExtCons 2026")
            ,@($specSoftCapex,$areaCapex,$catSoftCap,$typeFcast,400000,2026,"Forecast Soft 2026")
            ,@($specIntLabCapex,$areaCapex,$catIntCapex,$typeFcast,500000,2027,"Forecast IntLab 2027")
            ,@($specExtConsCapex,$areaCapex,$catExtCapex,$typeFcast,350000,2027,"Forecast ExtCons 2027")
            ,@($specLicOpex,$areaOpex,$catLicOpex,$typeFcast,250000,2027,"Forecast Lic 2027")
        )
    }
)

foreach ($ini in $initiatives) {
    Write-Host "`n--- $($ini.Name) ---" -ForegroundColor Cyan

    # Create Cost Plan Version
    $cpvId = Post-Record "pum_pf_costplan_versions" @{
        pum_pf_costplan_version             = $ini.CpvName
        pum_pf_costplan_version_default     = $true
        pum_planofrecord                    = $true
        "pum_pf_initiative_cpv@odata.bind"  = "/pum_initiatives($($ini.Id))"
    } "pum_pf_costplan_versionid" "CostPlanVersion: $($ini.Name)"

    if (-not $cpvId) { Write-Host "  SKIP - no version ID" -ForegroundColor Red; continue }

    # Create financial data rows
    foreach ($row in $ini.Rows) {
        # row: [0]=specId [1]=areaId [2]=catId [3]=typeId [4]=value [5]=year [6]=label
        New-FinRow -IniId $ini.Id -CpvId $cpvId `
            -SpecId $row[0] -AreaId $row[1] -CatId $row[2] -TypeId $row[3] `
            -Value ([double]$row[4]) -Year ([int]$row[5]) -Label "$($ini.Name) | $($row[6])"
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Financial Data Complete!"
Write-Host "  Succeeded : $($script:ok)"  -ForegroundColor Green
Write-Host "  Failed    : $($script:err)" -ForegroundColor $(if ($script:err -gt 0) { 'Red' } else { 'Green' })
Write-Host "============================================" -ForegroundColor Cyan
