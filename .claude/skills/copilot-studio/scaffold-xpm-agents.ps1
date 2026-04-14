#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Scaffold the XPM orchestrator and three connected-agent YAMLs from templates.
.DESCRIPTION
    Creates copilot-agents/<prefix>_xpm_orchestrator/ and sibling folders for
    risk_analyst, status_reporting, project_summarization. Fills each folder's
    agent YAML from the corresponding template in this skill folder, substituting
    the user-confirmed publisher prefix.

    The script does NOT call the Dataverse Web API. It only produces local files.
    Push to Copilot Studio happens via the VS Code Copilot Studio Extension.
.PARAMETER Prefix
    Publisher prefix confirmed by the user (lowercase, no trailing underscore).
.PARAMETER OutputRoot
    Override the destination folder. Defaults to <repo-root>/copilot-agents.
.PARAMETER Force
    Overwrite existing YAMLs. Default is fail-if-exists to avoid clobbering edits.
.EXAMPLE
    pwsh .claude/skills/copilot-studio/scaffold-xpm-agents.ps1 -Prefix pum
#>
param(
    [Parameter(Mandatory)][ValidatePattern('^[a-z][a-z0-9]{1,7}$')][string]$Prefix,
    [string]$OutputRoot,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# Resolve repository root
$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "helpers.psm1"))) {
    $root = Split-Path $root -Parent
}
if (-not $root) { throw "Cannot find helpers.psm1 in any parent directory." }

$templateDir = $PSScriptRoot
if (-not $OutputRoot) { $OutputRoot = Join-Path $root "copilot-agents" }

$agents = @(
    @{ Role = 'orchestrator';          Template = 'orchestrator-agent.yaml'; Display = 'XPM Orchestrator' },
    @{ Role = 'risk_analyst';          Template = 'connected-agent.yaml';    Display = 'Risk Analyst' },
    @{ Role = 'status_reporting';      Template = 'connected-agent.yaml';    Display = 'Status Reporting' },
    @{ Role = 'project_summarization'; Template = 'connected-agent.yaml';    Display = 'Project Summarization' }
)

Write-Host "Scaffolding XPM agents with prefix '$Prefix' under $OutputRoot" -ForegroundColor Cyan

foreach ($a in $agents) {
    $agentName = "${Prefix}_xpm_$($a.Role)"
    $dest      = Join-Path $OutputRoot $agentName
    $destFile  = Join-Path $dest "$agentName.yaml"
    $tmplPath  = Join-Path $templateDir $a.Template

    if (-not (Test-Path $tmplPath)) { throw "Template not found: $tmplPath" }
    if ((Test-Path $destFile) -and -not $Force) {
        Write-Host "  [skip] $destFile exists (use -Force to overwrite)" -ForegroundColor Yellow
        continue
    }

    $null = New-Item -ItemType Directory -Path $dest -Force

    $content = Get-Content $tmplPath -Raw
    $content = $content.Replace('<prefix>', $Prefix)
    $content = $content.Replace('<role>',   $a.Role)
    $content = $content.Replace('<DisplayName>', $a.Display)

    Set-Content -Path $destFile -Value $content -Encoding utf8
    Write-Host "  [ok]   $destFile" -ForegroundColor Green
}

Write-Host "" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open each connected-agent YAML and fill in instructions and tools."
Write-Host "  2. Use the tool-*.yaml fragments in $templateDir as starting points."
Write-Host "  3. Run: pwsh .claude/skills/copilot-studio/validate-yaml.ps1 -Path $OutputRoot"
Write-Host "  4. Clone each agent's Copilot Studio shell via the VS Code extension,"
Write-Host "     then copy/paste these YAML bodies into the cloned folders and push."
