#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Stage, commit, and push changes to a Git remote.
.DESCRIPTION
    Generic, reusable script for staging non-secret files, committing with a message,
    and pushing to a remote branch. Automatically skips secret files and scans for
    hardcoded credentials in staged diffs.
.PARAMETER CommitMessage
    The commit message. If omitted, a timestamped default is used.
.PARAMETER Branch
    Branch to push to. Defaults to the current branch.
.PARAMETER Remote
    Git remote name (default: "origin").
.PARAMETER DryRun
    If set, shows what would be committed/pushed without actually doing it.
.EXAMPLE
    pwsh .claude/skills/git-push/git-push.ps1 -CommitMessage "Add new table"
.EXAMPLE
    pwsh .claude/skills/git-push/git-push.ps1 -Branch "feature/my-branch" -DryRun
#>
param(
    [string]$CommitMessage,
    [string]$Branch,
    [string]$Remote = "origin",
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# Resolve branch
if (-not $Branch) {
    $Branch = git rev-parse --abbrev-ref HEAD 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Not inside a git repository." }
}

Write-Host "== Git Push ==" -ForegroundColor Cyan
Write-Host "Remote : $Remote" -ForegroundColor Cyan
Write-Host "Branch : $Branch" -ForegroundColor Cyan

# Check for changes
$status = git status --porcelain
if (-not $status) {
    Write-Host "Nothing to push — working tree is clean." -ForegroundColor Yellow
    exit 0
}

Write-Host "`nChanges:" -ForegroundColor Green
git status --short

# Filter secret files
$secretPatterns = @('*.env', '*.pfx', '*.key', 'credentials.json', '*.pem', '*.p12', '*.jks')
$filesToStage = @()
$skippedFiles = @()

foreach ($line in $status) {
    $file = ($line.Substring(3)).Trim()
    $skip = $false
    foreach ($pattern in $secretPatterns) {
        if ($file -like $pattern) {
            $skip = $true
            $skippedFiles += $file
            break
        }
    }
    if (-not $skip) { $filesToStage += $file }
}

if ($skippedFiles.Count -gt 0) {
    Write-Host "`nSkipped (possible secrets):" -ForegroundColor Red
    $skippedFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
}

if ($filesToStage.Count -eq 0) {
    Write-Host "No files to stage after filtering secrets." -ForegroundColor Yellow
    exit 0
}

if ($DryRun) {
    Write-Host "`n[DRY RUN] Would stage $($filesToStage.Count) file(s) and push to $Remote/$Branch" -ForegroundColor Yellow
    $filesToStage | ForEach-Object { Write-Host "  $_" }
    exit 0
}

# Stage
Write-Host "`nStaging $($filesToStage.Count) file(s)..." -ForegroundColor Green
foreach ($f in $filesToStage) { git add -- $f }

# Scan staged diff for hardcoded secrets
$secretContentPatterns = @(
    'client_secret\s*=\s*["\x27][A-Za-z0-9~_.]{20,}',
    'CLIENT_SECRET\s*=\s*["\x27]?[A-Za-z0-9~_.]{20,}',
    'password\s*=\s*["\x27][^\$][^"]{8,}',
    '["\x27]eyJ[A-Za-z0-9_-]{50,}'
)
$diff = git diff --cached --unified=0
$leaksFound = @()
foreach ($pattern in $secretContentPatterns) {
    $matches = $diff | Select-String -Pattern $pattern -AllMatches
    if ($matches) { $leaksFound += $matches }
}
if ($leaksFound.Count -gt 0) {
    Write-Host "`nPossible hardcoded secrets detected:" -ForegroundColor Red
    $leaksFound | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    Write-Host "Aborting. Remove secrets and use environment variables." -ForegroundColor Red
    git reset HEAD -- . > $null
    exit 1
}

# Commit
if (-not $CommitMessage) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $CommitMessage = "Update $timestamp"
}

Write-Host "Committing: $CommitMessage" -ForegroundColor Green
git commit -m "$CommitMessage"
if ($LASTEXITCODE -ne 0) { throw "Commit failed." }

# Push
Write-Host "Pushing to $Remote/$Branch..." -ForegroundColor Green
git push -u $Remote $Branch
if ($LASTEXITCODE -ne 0) {
    throw "Push failed. Try: git pull --rebase $Remote $Branch"
}

$shortSha = git rev-parse --short HEAD
Write-Host "`n== Pushed successfully ==" -ForegroundColor Cyan
Write-Host "Commit : $shortSha" -ForegroundColor Cyan
Write-Host "Branch : $Branch" -ForegroundColor Cyan
