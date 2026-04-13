#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Verify prerequisites for `microsoft/skills-for-copilot-studio` and print install commands.
.DESCRIPTION
    The Microsoft plugin is installed via the `/plugin` slash command inside Claude Code
    or the GitHub Copilot CLI — a shell script cannot run those commands directly.
    This helper detects which host is available on the system and prints the exact
    commands the user should paste into that host. It also verifies Node.js 18+ and
    warns if the VS Code Copilot Studio Extension is not detectable.
.NOTES
    Cross-platform (Windows + macOS). Read-only; does not modify the system.
#>

$ErrorActionPreference = 'Stop'

function Write-Status { param([string]$Msg, [string]$Color = 'Cyan') Write-Host $Msg -ForegroundColor $Color }
function Write-Ok     { param([string]$Msg) Write-Host "  [ok]   $Msg" -ForegroundColor Green }
function Write-Warn   { param([string]$Msg) Write-Host "  [warn] $Msg" -ForegroundColor Yellow }
function Write-Miss   { param([string]$Msg) Write-Host "  [miss] $Msg" -ForegroundColor Red }

Write-Status "microsoft/skills-for-copilot-studio — prerequisite check" 'Cyan'
Write-Host  ""

# Node.js 18+
$nodeOk = $false
try {
    $nodeVersion = (& node --version 2>$null).TrimStart('v')
    if ($nodeVersion) {
        $major = [int]($nodeVersion.Split('.')[0])
        if ($major -ge 18) { Write-Ok "Node.js $nodeVersion"; $nodeOk = $true }
        else { Write-Miss "Node.js $nodeVersion — plugin requires >= 18" }
    }
}
catch { Write-Miss "Node.js not on PATH — install from https://nodejs.org" }

# Claude Code CLI
$claudeOk = $false
try {
    $claudeVersion = (& claude --version 2>$null)
    if ($claudeVersion) { Write-Ok "Claude Code: $claudeVersion"; $claudeOk = $true }
}
catch { Write-Warn "Claude Code CLI not on PATH (optional — may be installed elsewhere)" }

# GitHub Copilot CLI
$ghCopilotOk = $false
try {
    & gh copilot --help 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Ok "GitHub Copilot CLI detected"; $ghCopilotOk = $true }
}
catch { Write-Warn "GitHub Copilot CLI not detected (optional)" }

# VS Code Copilot Studio Extension — best-effort detection on common paths
$vscodeExtRoots = @(
    (Join-Path $HOME '.vscode/extensions'),
    (Join-Path $HOME '.vscode-insiders/extensions'),
    (Join-Path $env:USERPROFILE '.vscode/extensions')
) | Where-Object { $_ -and (Test-Path $_) }

$vsExtOk = $false
foreach ($root in $vscodeExtRoots) {
    $match = Get-ChildItem $root -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'copilot.?studio' } |
        Select-Object -First 1
    if ($match) { Write-Ok "VS Code Copilot Studio Extension: $($match.Name)"; $vsExtOk = $true; break }
}
if (-not $vsExtOk) { Write-Warn "VS Code Copilot Studio Extension not detected — required for push/pull/clone" }

Write-Host  ""
Write-Status "Install commands — run these inside your Claude Code or GH Copilot CLI session:" 'Cyan'
Write-Host  "  /plugin marketplace add microsoft/skills-for-copilot-studio"
Write-Host  "  /plugin install copilot-studio@skills-for-copilot-studio"
Write-Host  ""
Write-Status "After install, the plugin exposes four commands:" 'Cyan'
Write-Host  "  /copilot-studio:copilot-studio-manage"
Write-Host  "  /copilot-studio:copilot-studio-author"
Write-Host  "  /copilot-studio:copilot-studio-test"
Write-Host  "  /copilot-studio:copilot-studio-troubleshoot"
Write-Host  ""

if (-not $nodeOk) {
    Write-Host "Node.js 18+ is required before the plugin will run." -ForegroundColor Red
    exit 1
}
if (-not $vsExtOk) {
    Write-Host "Install the VS Code 'Copilot Studio' extension to enable clone/push/pull." -ForegroundColor Yellow
}
if (-not ($claudeOk -or $ghCopilotOk)) {
    Write-Host "Neither Claude Code nor GH Copilot CLI detected — install at least one plugin host." -ForegroundColor Yellow
}

Write-Host "Done." -ForegroundColor Green
