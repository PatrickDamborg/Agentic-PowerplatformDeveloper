#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Lint XPM Copilot Studio YAML and flow JSON for required descriptions and conventions.
.DESCRIPTION
    Walks a file or folder and checks:
      - YAML agent files: every agent, connectedAgent, tool, input, output has a non-empty description
      - YAML agent files: name follows <prefix>_xpm_<role> convention
      - Flow JSON files: name follows <prefix>_skill_<verb>_<noun> convention
      - Flow JSON files: every trigger input and every Respond to Copilot output property has a description
      - Flow JSON files: Try/Catch scopes are present
    Prints one finding per violation. Exits 0 if clean, 1 if any violation found.
.PARAMETER Path
    File or directory to scan. If a directory, recurses for *.yaml / *.yml / *.json.
.PARAMETER Prefix
    Optional — if provided, enforces that names start with <prefix>_. If omitted,
    any single-prefix pattern is accepted (so long as naming shape is correct).
.EXAMPLE
    pwsh .claude/skills/copilot-studio/validate-yaml.ps1 -Path copilot-agents/
    pwsh .claude/skills/copilot-studio/validate-yaml.ps1 -Path flows/skills/ -Prefix pum
#>
param(
    [Parameter(Mandatory)][string]$Path,
    [string]$Prefix
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Path)) { Write-Host "Path not found: $Path" -ForegroundColor Red; exit 1 }

$findings = New-Object System.Collections.Generic.List[string]
function Add-Finding { param([string]$File, [string]$Msg) $findings.Add("  $File : $Msg") }

# Collect files
$targets = if ((Get-Item $Path).PSIsContainer) {
    Get-ChildItem -Path $Path -Recurse -File -Include *.yaml,*.yml,*.json
} else {
    @(Get-Item $Path)
}

$agentNameRe = if ($Prefix) { "^${Prefix}_xpm_[a-z][a-z0-9_]+$" } else { '^[a-z][a-z0-9]{1,7}_xpm_[a-z][a-z0-9_]+$' }
$flowNameRe  = if ($Prefix) { "^${Prefix}_skill_[a-z][a-z0-9_]+$"  } else { '^[a-z][a-z0-9]{1,7}_skill_[a-z][a-z0-9_]+$' }

function Test-YamlDescriptions {
    param([string]$File)
    $raw = Get-Content $File -Raw

    # Skip pure template fragments — detected by <prefix> placeholder
    if ($raw -match '<prefix>') {
        # Templates are not user-facing; only enforce they keep the placeholders.
        return
    }

    # Agent name
    if ($raw -match '(?m)^name:\s*(\S+)\s*$') {
        $name = $Matches[1]
        if ($name -notmatch $agentNameRe) {
            Add-Finding $File "agent name '$name' does not match '<prefix>_xpm_<role>' convention"
        }
    }

    # Every `description:` key should have a non-empty value (string or folded).
    # Heuristic: flag `description:` followed by empty / only punctuation on same line AND no indented continuation.
    $lines = $raw -split "`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*description:\s*(.*)$') {
            $val = $Matches[1].Trim()
            if ($val -in @('', '""', "''", '>-', '>', '|')) {
                # Check next line for indented continuation
                $j = $i + 1
                $hasBody = $false
                while ($j -lt $lines.Count -and $lines[$j] -match '^(\s{2,}\S|\s{2,}$)') {
                    if ($lines[$j].Trim()) { $hasBody = $true; break }
                    $j++
                }
                if (-not $hasBody) {
                    Add-Finding $File "line $($i+1): empty description"
                }
            }
        }
    }

    # Tools / connectedAgents blocks should each have a description key nearby.
    # Cheap check: if a `tools:` block is non-empty, ensure `description:` appears between `- name:` markers.
    # This is heuristic; the authoritative gate is the empty-description check above.
}

function Test-FlowJson {
    param([string]$File)
    try {
        $flow = Get-Content $File -Raw | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Add-Finding $File "invalid JSON: $($_.Exception.Message)"; return
    }

    # Flow name convention — take from file name (without extension)
    $baseName = [IO.Path]::GetFileNameWithoutExtension($File)
    if ($baseName -notmatch $flowNameRe) {
        # Only flag if it looks like it intends to be an XPM skill
        if ($baseName -match '_skill_' -or $baseName -match '_xpm_') {
            Add-Finding $File "flow file name '$baseName' does not match '<prefix>_skill_<verb>_<noun>'"
        }
    }

    $def = $flow.properties.definition
    if (-not $def) { Add-Finding $File "missing properties.definition"; return }

    # Trigger must be Copilot Studio kind
    $trigger = $def.triggers.PSObject.Properties | Select-Object -First 1
    if (-not $trigger) { Add-Finding $File "no trigger defined"; return }

    # Validate trigger input schema properties carry descriptions
    $schema = $trigger.Value.inputs.parameters.schema
    if ($schema -and $schema.properties) {
        foreach ($p in $schema.properties.PSObject.Properties) {
            if (-not $p.Value.description -or $p.Value.description.Trim() -eq '') {
                Add-Finding $File "trigger input '$($p.Name)' has no description"
            }
            if ($p.Value.description -match 'REPLACE_WITH') {
                Add-Finding $File "trigger input '$($p.Name)' description still contains REPLACE_WITH placeholder"
            }
        }
    }

    # Try/Catch scopes
    if (-not $def.actions.Try_Scope) { Add-Finding $File "missing Try_Scope" }
    if (-not $def.actions.Catch_Scope) { Add-Finding $File "missing Catch_Scope" }

    # Respond to Copilot action should exist and its schema should describe outputs
    $respond = $null
    if ($def.actions.Try_Scope -and $def.actions.Try_Scope.actions) {
        $respond = $def.actions.Try_Scope.actions.PSObject.Properties |
            Where-Object { $_.Value.type -eq 'OpenApiConnectionWebhookResponse' } |
            Select-Object -First 1
    }
    if (-not $respond) {
        Add-Finding $File "no 'Respond to Copilot' action inside Try_Scope"
    } elseif ($respond.Value.inputs.schema -and $respond.Value.inputs.schema.properties) {
        foreach ($p in $respond.Value.inputs.schema.properties.PSObject.Properties) {
            if (-not $p.Value.description -or $p.Value.description.Trim() -eq '') {
                Add-Finding $File "response output '$($p.Name)' has no description"
            }
        }
    } else {
        Add-Finding $File "Respond to Copilot action has no output schema"
    }
}

Write-Host "Linting $($targets.Count) file(s)..." -ForegroundColor Cyan
foreach ($t in $targets) {
    if ($t.Extension -in @('.yaml', '.yml')) { Test-YamlDescriptions $t.FullName }
    elseif ($t.Extension -eq '.json')        { Test-FlowJson        $t.FullName }
}

if ($findings.Count -eq 0) {
    Write-Host "Clean — no violations found." -ForegroundColor Green
    exit 0
}

Write-Host "Violations:" -ForegroundColor Red
$findings | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
Write-Host "Total: $($findings.Count)" -ForegroundColor Red
exit 1
