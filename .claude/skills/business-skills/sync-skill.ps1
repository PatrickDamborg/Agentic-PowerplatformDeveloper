#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Create or update a Dataverse Business Skill record (and its reference-file
    resources) from a local SKILL.md-style folder, associated with a solution.
.DESCRIPTION
    Business Skills are a native Dataverse entity (logical name "skill", entity
    set "skills") — solution-aware, distinct from Copilot Studio's portal-only
    "Agent Skills" upload feature. This script pushes a local skill folder
    (SKILL.md + optional references/*.md) into Dataverse via the Web API.

    Frontmatter (name/description) is NOT parsed automatically — YAML
    single-quote escaping in real skill descriptions is fragile to regex.
    Read the file yourself, extract a clean DisplayName/Description, and pass
    them as parameters. The script only strips the frontmatter block to get
    the body (a plain "first two '---' lines" split — always reliable), and
    handles all the Dataverse mechanics: create/update, solution association,
    and file-content upload for reference files.
.PARAMETER SkillMdPath
    Path to the skill's SKILL.md file.
.PARAMETER DisplayName
    Human-readable name for the Business Skill record (e.g. "Portfolio summary skill").
.PARAMETER UniqueName
    Schema-like unique name (e.g. "xPM_portfolioSummary"). Must be unique in the environment.
.PARAMETER Description
    Plain-text description (extract by hand from the SKILL.md frontmatter — do not
    pass the raw YAML value, since embedded '' escaping will leak into the record).
.PARAMETER SolutionName
    Solution unique name to associate the skill (and its resources) with.
.PARAMETER ExistingSkillId
    If provided, updates this skill record instead of creating a new one.
    Look it up first: skills?$filter=uniquename eq '<UniqueName>'&$select=skillid
.PARAMETER ReferencesFolder
    Optional path to a references/ folder of supporting .md files. Each is
    synced as a skillresource child record with its file content uploaded.
    Existing resources are matched and updated by filename; new ones are created.
.EXAMPLE
    pwsh .claude/skills/business-skills/sync-skill.ps1 `
        -SkillMdPath "deliverables/skills/portfolio-summary/SKILL.md" `
        -DisplayName "Portfolio summary skill" `
        -UniqueName "xPM_portfolioSummary" `
        -Description "Produce a structured, data-grounded summary of one xPM entity..." `
        -SolutionName "xPMAIUseCasesdemo"
.EXAMPLE
    # Update an existing skill and sync its reference files
    pwsh .claude/skills/business-skills/sync-skill.ps1 `
        -SkillMdPath "deliverables/skills/status-report-drafter/SKILL.md" `
        -DisplayName "Status reporting skill" `
        -UniqueName "xPM_statusReporting" `
        -Description "Draft a 5-dimension KPI status report..." `
        -SolutionName "xPMAIUseCasesdemo" `
        -ExistingSkillId "3a325ea4-7874-f111-ab0e-0022480412bf" `
        -ReferencesFolder "deliverables/skills/status-report-drafter/references"
#>
param(
    [Parameter(Mandatory)][string]$SkillMdPath,
    [Parameter(Mandatory)][string]$DisplayName,
    [Parameter(Mandatory)][string]$UniqueName,
    [Parameter(Mandatory)][string]$Description,
    [Parameter(Mandatory)][string]$SolutionName,
    [string]$ExistingSkillId,
    [string]$ReferencesFolder
)

$ErrorActionPreference = 'Stop'

# Resolve repository root
$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "helpers.psm1"))) {
    $root = Split-Path $root -Parent
}
if (-not $root) { throw "Cannot find helpers.psm1 in any parent directory." }
Import-Module (Join-Path $root "helpers.psm1") -Force

$conn = Get-DataverseHeaders -SolutionName $SolutionName -EnvPath (Join-Path $root ".env")
$h = $conn.Headers
$url = $conn.BaseUrl

function Strip-Frontmatter {
    param([string]$Text)
    $lines = $Text -split "`n"
    if ($lines[0].Trim() -ne '---') { throw "File does not start with YAML frontmatter (---)." }
    $endIdx = $null
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') { $endIdx = $i; break }
    }
    if ($null -eq $endIdx) { throw "No closing --- found for frontmatter." }
    return (($lines[($endIdx + 1)..($lines.Count - 1)] -join "`n")).TrimStart("`n")
}

if (-not (Test-Path $SkillMdPath)) { throw "SKILL.md not found: $SkillMdPath" }
$raw = Get-Content $SkillMdPath -Raw
$body = Strip-Frontmatter -Text $raw

$skillBody = @{
    name        = $DisplayName
    uniquename  = $UniqueName
    description = $Description
    body        = $body
} | ConvertTo-Json -Depth 5

$skillId = $ExistingSkillId
if ($skillId) {
    Write-Host "Updating skill '$DisplayName' ($skillId)..." -ForegroundColor Cyan
    Invoke-WebRequest -Method Patch -Uri "$url/skills($skillId)" -Headers $h -Body $skillBody -UseBasicParsing | Out-Null
    Write-Host "  Updated." -ForegroundColor Green
}
else {
    Write-Host "Creating skill '$DisplayName'..." -ForegroundColor Cyan
    $resp = Invoke-WebRequest -Method Post -Uri "$url/skills" -Headers $h -Body $skillBody -UseBasicParsing
    $entityUri = $resp.Headers["OData-EntityId"]
    $skillId = $entityUri -replace '.*\(([^)]+)\).*', '$1'
    Write-Host "  Created: $skillId" -ForegroundColor Green
}

if ($ReferencesFolder) {
    if (-not (Test-Path $ReferencesFolder)) { throw "References folder not found: $ReferencesFolder" }
    $mdFiles = Get-ChildItem -Path $ReferencesFolder -Filter "*.md"
    foreach ($file in $mdFiles) {
        Write-Host "Syncing resource '$($file.Name)'..." -ForegroundColor Cyan

        # Look up an existing resource by filename under this skill
        $filterQuery = "skillresources?`$filter=_skillid_value eq $skillId and filename eq '$($file.Name)'&`$select=skillresourceid"
        $existing = Invoke-DataverseRequest -Method GET -Endpoint $filterQuery -BaseUrl $url -Headers $h
        $resourceId = $null

        if ($existing.value.Count -gt 0) {
            $resourceId = $existing.value[0].skillresourceid
            $patchBody = @{ filename = $file.Name } | ConvertTo-Json
            Invoke-WebRequest -Method Patch -Uri "$url/skillresources($resourceId)" -Headers $h -Body $patchBody -UseBasicParsing | Out-Null
            Write-Host "  Row updated (re-registers solution membership): $resourceId" -ForegroundColor Green
        }
        else {
            $resourceUniqueName = "${UniqueName}_$($file.BaseName -replace '[^a-zA-Z0-9]', '')"
            $createBody = @{
                filename              = $file.Name
                uniquename            = $resourceUniqueName
                "skillid@odata.bind"  = "/skills($skillId)"
            } | ConvertTo-Json
            $resp = Invoke-WebRequest -Method Post -Uri "$url/skillresources" -Headers $h -Body $createBody -UseBasicParsing
            $entityUri = $resp.Headers["OData-EntityId"]
            $resourceId = $entityUri -replace '.*\(([^)]+)\).*', '$1'
            Write-Host "  Row created: $resourceId" -ForegroundColor Green
        }

        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        $fileHeaders = $h.Clone()
        $fileHeaders.Remove('Content-Type') | Out-Null
        $fileHeaders['Content-Type'] = 'application/octet-stream'
        $fileHeaders['x-ms-file-name'] = $file.Name
        Invoke-WebRequest -Method Patch -Uri "$url/skillresources($resourceId)/filecontent" -Headers $fileHeaders -Body $bytes -UseBasicParsing | Out-Null
        Write-Host "  File content uploaded." -ForegroundColor Green
    }
}

Write-Host "`nDone. skillid: $skillId" -ForegroundColor Green
