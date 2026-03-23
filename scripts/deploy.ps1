#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploys the current working tree to GitHub by staging, committing, and pushing.
.PARAMETER CommitMessage
    The commit message. If omitted, a default message with timestamp is used.
.PARAMETER Branch
    The branch to push to. Defaults to the current branch.
.EXAMPLE
    ./scripts/deploy.ps1 -CommitMessage "Add new flow definitions"
#>
param(
    [string]$CommitMessage,
    [string]$Branch
)

$ErrorActionPreference = 'Stop'
$repo = "https://github.com/PatrickDamborg/Agentic-PowerplatformDeveloper"

# Resolve branch
if (-not $Branch) {
    $Branch = git rev-parse --abbrev-ref HEAD 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Not inside a git repository."
        exit 1
    }
}

Write-Host "== Deploy to $repo ==" -ForegroundColor Cyan
Write-Host "Branch: $Branch" -ForegroundColor Cyan

# Check for changes
$status = git status --porcelain
if (-not $status) {
    Write-Host "Nothing to deploy - working tree is clean." -ForegroundColor Yellow
    exit 0
}

Write-Host "`nChanges to deploy:" -ForegroundColor Green
git status --short

# Guard against committing secrets
$secretPatterns = @('*.env', '*.pfx', '*.key', 'credentials.json', '*.pem')
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
    if (-not $skip) {
        $filesToStage += $file
    }
}

if ($skippedFiles.Count -gt 0) {
    Write-Host "`nSkipped (possible secrets):" -ForegroundColor Red
    $skippedFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
}

if ($filesToStage.Count -eq 0) {
    Write-Host "No files to stage after filtering secrets." -ForegroundColor Yellow
    exit 0
}

# Stage files
Write-Host "`nStaging $($filesToStage.Count) file(s)..." -ForegroundColor Green
foreach ($f in $filesToStage) {
    git add -- $f
}

# Scan staged content for hardcoded secrets
$secretContentPatterns = @(
    'client_secret\s*=\s*["\u0027][A-Za-z0-9~_.]{20,}',
    'CLIENT_SECRET\s*=\s*["\u0027]?[A-Za-z0-9~_.]{20,}',
    'password\s*=\s*["\u0027][^\$][^"]{8,}',
    '["\u0027]eyJ[A-Za-z0-9_-]{50,}'
)
$diff = git diff --cached --unified=0
$leaksFound = @()
foreach ($pattern in $secretContentPatterns) {
    $matches = $diff | Select-String -Pattern $pattern -AllMatches
    if ($matches) {
        $leaksFound += $matches
    }
}
if ($leaksFound.Count -gt 0) {
    Write-Host "`nPossible hardcoded secrets detected in staged changes:" -ForegroundColor Red
    $leaksFound | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    Write-Host "Aborting deploy. Remove secrets and use environment variables instead." -ForegroundColor Red
    git reset HEAD -- . > $null
    exit 1
}

# Commit
if (-not $CommitMessage) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $CommitMessage = "Deploy update $timestamp"
}

$fullMessage = "$CommitMessage`n`nCo-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"

Write-Host "Committing: $CommitMessage" -ForegroundColor Green
git commit -m $fullMessage
if ($LASTEXITCODE -ne 0) {
    Write-Error "Commit failed."
    exit 1
}

# Push
Write-Host "Pushing to origin/$Branch..." -ForegroundColor Green
git push -u origin $Branch
if ($LASTEXITCODE -ne 0) {
    Write-Error "Push failed. You may need to pull first: git pull --rebase origin $Branch"
    exit 1
}

$shortSha = git rev-parse --short HEAD
Write-Host "`n== Deployed successfully ==" -ForegroundColor Cyan
Write-Host "Commit: $shortSha" -ForegroundColor Cyan
Write-Host "Branch: $repo/tree/$Branch" -ForegroundColor Cyan
