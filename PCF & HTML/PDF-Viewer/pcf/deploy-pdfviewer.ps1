<#
.SYNOPSIS
  Build, package, and deploy the PdfViewer PCF control solution to Dataverse.

.DESCRIPTION
  Builds the control with pcf-scripts, assembles the unmanaged solution zip described in
  README.md (Package & deploy section), imports it via the Dataverse Web API
  (ImportSolutionAsync + poll + PublishAllXml), and verifies the deployed control version.
  No `pac` CLI is used, per repo convention (see root CLAUDE.md).

.PARAMETER BuildMode
  pcf-scripts build mode: "production" (default, minified) or "debug".

.PARAMETER SkipBuild
  Skip the `npm run build` / pcf-scripts build step and package whatever is already in out/.

.PARAMETER EnvFile
  Path to the env file providing DATAVERSE_URL, TENANT_ID, CLIENT_ID, CLIENT_SECRET.
  Defaults to the repo root's `.env` file (falls back to `env` if `.env` is not found).

.EXAMPLE
  pwsh ./deploy-pdfviewer.ps1

.EXAMPLE
  pwsh ./deploy-pdfviewer.ps1 -BuildMode debug -SkipBuild
#>
param(
    [ValidateSet("production", "debug")]
    [string]$BuildMode = "production",
    [switch]$SkipBuild,
    [string]$EnvFile
)

$ErrorActionPreference = "Stop"

$projectDir = $PSScriptRoot
$controlName = "context_ContextAnd.PdfViewer"
$solutionUniqueName = "ContextAndPdfViewer"
$publisherPrefix = "context"
$optionValuePrefix = "23615"

# ── Resolve repo root + env file ─────────────────────────────────────────────
function Find-RepoRoot {
    param([string]$StartDir)
    $dir = $StartDir
    while ($dir -and -not (Test-Path (Join-Path $dir ".git"))) {
        $parent = Split-Path $dir -Parent
        if ($parent -eq $dir) { return $null }
        $dir = $parent
    }
    return $dir
}

if (-not $EnvFile) {
    $repoRoot = Find-RepoRoot -StartDir $projectDir
    if (-not $repoRoot) { throw "Could not locate repo root (no .git ancestor of $projectDir). Pass -EnvFile explicitly." }
    $dotEnv = Join-Path $repoRoot ".env"
    $plainEnv = Join-Path $repoRoot "env"
    if (Test-Path $dotEnv) { $EnvFile = $dotEnv }
    elseif (Test-Path $plainEnv) { $EnvFile = $plainEnv }
    else { throw "No .env or env file found at repo root ($repoRoot). Pass -EnvFile explicitly." }
}
if (-not (Test-Path $EnvFile)) { throw "EnvFile not found: $EnvFile" }

Write-Host "Using env file: $EnvFile" -ForegroundColor Gray
Get-Content $EnvFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        [System.Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim())
    }
}

$baseUrl = $env:DATAVERSE_URL
$tenantId = $env:TENANT_ID
$clientId = $env:CLIENT_ID
$clientSecret = $env:CLIENT_SECRET
foreach ($required in @("DATAVERSE_URL", "TENANT_ID", "CLIENT_ID", "CLIENT_SECRET")) {
    if (-not (Get-Item "env:$required" -ErrorAction SilentlyContinue)) {
        throw "Missing required env var: $required (from $EnvFile)"
    }
}
$resource = ($baseUrl -replace '/api/data/v9.2.*', '')

# ── Auth ──────────────────────────────────────────────────────────────────────
function Get-Token {
    $body = @{
        grant_type    = "client_credentials"
        client_id     = $clientId
        client_secret = $clientSecret
        scope         = "$resource/.default"
    }
    $resp = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
                               -Method Post -Body $body
    return $resp.access_token
}

# ── Step 1: build ─────────────────────────────────────────────────────────────
if (-not $SkipBuild) {
    Write-Host "`n=== Build ($BuildMode) ===" -ForegroundColor Cyan
    Push-Location $projectDir
    try {
        if (-not (Test-Path (Join-Path $projectDir "node_modules"))) {
            Write-Host "Installing npm dependencies..." -ForegroundColor Yellow
            npm install
            if ($LASTEXITCODE -ne 0) { throw "npm install failed" }
        }
        npx pcf-scripts build --buildMode $BuildMode
        if ($LASTEXITCODE -ne 0) { throw "pcf-scripts build failed" }
    } finally {
        Pop-Location
    }
} else {
    Write-Host "`n=== Skipping build (-SkipBuild) ===" -ForegroundColor Yellow
}

$outControlDir = Join-Path $projectDir "out/controls/PdfViewer"
$bundlePath = Join-Path $outControlDir "bundle.js"
$compiledManifestPath = Join-Path $outControlDir "ControlManifest.xml"
if (-not (Test-Path $bundlePath)) { throw "Build output not found: $bundlePath" }
if (-not (Test-Path $compiledManifestPath)) { throw "Build output not found: $compiledManifestPath" }

# ── Step 2: read version from the source manifest ────────────────────────────
# Match the <control ...> tag's version specifically -- the file's first version="..."
# attribute is actually the XML declaration's version="1.0".
$manifestInputPath = Join-Path $projectDir "PdfViewer/ControlManifest.Input.xml"
$manifestInputContent = Get-Content -LiteralPath $manifestInputPath -Raw
if ($manifestInputContent -notmatch '<control[\s\S]*?\bversion="([^"]+)"') { throw "Could not read the control version= from $manifestInputPath" }
$version = $matches[1]
Write-Host "Control version: $version" -ForegroundColor Gray

# The <ImportExportXml> root needs SolutionPackageVersion set to the target org's Dataverse
# version, or the importer assumes an incompatible on-premises package and rejects it.
$orgVersionToken = Get-Token
$orgVersionResp = Invoke-RestMethod -Uri "$baseUrl/RetrieveVersion" -Headers @{ Authorization = "Bearer $orgVersionToken"; Accept = "application/json" }
$orgVersion = $orgVersionResp.Version
Write-Host "Target org Dataverse version: $orgVersion" -ForegroundColor Gray

# ── Step 3: stage the solution folder ────────────────────────────────────────
$stageDir = Join-Path $projectDir "out/solution"
if (Test-Path $stageDir) { Remove-Item $stageDir -Recurse -Force }
New-Item -ItemType Directory -Path $stageDir | Out-Null

$controlsDir = Join-Path $stageDir "Controls/$controlName"
New-Item -ItemType Directory -Path $controlsDir | Out-Null

Set-Content -LiteralPath (Join-Path $stageDir "[Content_Types].xml") -Encoding UTF8 -NoNewline -Value @"
<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="xml" ContentType="text/xml" />
  <Default Extension="js" ContentType="text/javascript" />
</Types>
"@

Set-Content -LiteralPath (Join-Path $stageDir "solution.xml") -Encoding UTF8 -NoNewline -Value @"
<?xml version="1.0" encoding="utf-8"?>
<ImportExportXml version="9.2" SolutionPackageVersion="$orgVersion" languagecode="1033" generatedBy="CrmLive">
  <SolutionManifest>
    <UniqueName>$solutionUniqueName</UniqueName>
    <LocalizedNames>
      <LocalizedName description="$solutionUniqueName" languagecode="1033" />
    </LocalizedNames>
    <Descriptions />
    <Version>$version</Version>
    <Managed>0</Managed>
    <Publisher>
      <UniqueName>ContextAnd</UniqueName>
      <LocalizedNames>
        <LocalizedName description="ContextAnd" languagecode="1033" />
      </LocalizedNames>
      <Descriptions />
      <EMailAddress xsi:nil="true" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" />
      <SupportingWebsiteUrl xsi:nil="true" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" />
      <CustomizationPrefix>$publisherPrefix</CustomizationPrefix>
      <CustomizationOptionValuePrefix>$optionValuePrefix</CustomizationOptionValuePrefix>
    </Publisher>
    <RootComponents>
      <RootComponent type="66" schemaName="$controlName" behavior="0" />
    </RootComponents>
    <MissingDependencies />
  </SolutionManifest>
</ImportExportXml>
"@

Set-Content -LiteralPath (Join-Path $stageDir "customizations.xml") -Encoding UTF8 -NoNewline -Value @"
<?xml version="1.0" encoding="utf-8"?>
<ImportExportXml version="9.2" SolutionPackageVersion="$orgVersion" languagecode="1033" generatedBy="CrmLive">
  <Entities />
  <Roles />
  <Workflows />
  <FieldSecurityProfiles />
  <Templates />
  <EntityMaps />
  <EntityRelationships />
  <OrganizationSettings />
  <optionsets />
  <CustomControls>
    <CustomControl>
      <Name>$controlName</Name>
      <FileName>/Controls/$controlName/ControlManifest.xml</FileName>
    </CustomControl>
  </CustomControls>
  <Languages>
    <Language>1033</Language>
  </Languages>
</ImportExportXml>
"@

# Compiled manifest, with the XML declaration stripped (README requirement).
$compiledManifest = Get-Content -LiteralPath $compiledManifestPath -Raw
$compiledManifest = $compiledManifest -replace '^﻿?<\?xml[^>]*\?>\s*', ''
Set-Content -LiteralPath (Join-Path $controlsDir "ControlManifest.xml") -Encoding UTF8 -NoNewline -Value $compiledManifest

Copy-Item -LiteralPath $bundlePath -Destination (Join-Path $controlsDir "bundle.js") -Force

# ── Step 4: zip ───────────────────────────────────────────────────────────────
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$zipPath = Join-Path $stageDir "ContextAndPdfViewer_$version.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

$zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $filesToZip = Get-ChildItem -Path $stageDir -Recurse -File | Where-Object { $_.FullName -ne $zipPath }
    foreach ($file in $filesToZip) {
        $relativePath = $file.FullName.Substring($stageDir.Length + 1) -replace '\\', '/'
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $relativePath) | Out-Null
    }
} finally {
    $zip.Dispose()
}
Write-Host "Packaged: $zipPath" -ForegroundColor Gray

# ── Step 5: import (async) + poll ────────────────────────────────────────────
Write-Host "`n=== Import ===" -ForegroundColor Cyan
$token = Get-Token
$headers = @{
    Authorization      = "Bearer $token"
    "Content-Type"     = "application/json"
    "OData-MaxVersion" = "4.0"
    "OData-Version"    = "4.0"
    Accept             = "application/json"
}

$bytes = [System.IO.File]::ReadAllBytes($zipPath)
$b64 = [Convert]::ToBase64String($bytes)
$jobId = [Guid]::NewGuid().ToString()

$body = @{
    CustomizationFile                = $b64
    OverwriteUnmanagedCustomizations = $true
    PublishWorkflows                 = $true
    ImportJobId                      = $jobId
    HoldingSolution                  = $false
    SkipProductUpdateDependencies    = $false
    ConvertToManaged                 = $false
    AsyncRibbonProcessing            = $true
} | ConvertTo-Json -Depth 3

Write-Host "Submitting import job..." -ForegroundColor Yellow
$resp = Invoke-RestMethod -Uri "$baseUrl/ImportSolutionAsync" -Method Post -Headers $headers -Body $body
$asyncOpId = $resp.AsyncOperationId
if (-not $asyncOpId) { throw "No AsyncOperationId returned from ImportSolutionAsync." }
Write-Host "Job ID: $asyncOpId" -ForegroundColor Gray

$pollUrl = "$baseUrl/asyncoperations($asyncOpId)?`$select=statecode,statuscode,message,friendlymessage"
$deadline = (Get-Date).AddMinutes(15)
$succeeded = $false

while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 10
    $token = Get-Token   # refresh — long imports can expire token
    $headers.Authorization = "Bearer $token"

    try {
        $op = Invoke-RestMethod -Uri $pollUrl -Headers $headers
    } catch {
        Write-Host "  Polling error (will retry): $_" -ForegroundColor DarkYellow
        continue   # deadline still advances — the bug this fixes was a loop that never timed out
    }

    if ($op.statecode -eq 3) {
        if ($op.statuscode -eq 30) {
            Write-Host "  Import succeeded" -ForegroundColor Green
            $succeeded = $true
        } else {
            $msg = if ($op.friendlymessage) { $op.friendlymessage } else { $op.message }
            throw "Import failed (statuscode=$($op.statuscode)): $msg"
        }
        break
    }
    Write-Host "  Waiting... (statecode=$($op.statecode))" -ForegroundColor DarkGray
}

if (-not $succeeded) { throw "Import did not complete within 15 minutes (asyncoperation $asyncOpId)." }

# ── Step 6: publish ───────────────────────────────────────────────────────────
Write-Host "`n=== Publish ===" -ForegroundColor Cyan
$token = Get-Token
$headers.Authorization = "Bearer $token"
Invoke-RestMethod -Uri "$baseUrl/PublishAllXml" -Method Post -Headers $headers -Body "{}" | Out-Null
Write-Host "  PublishAllXml completed" -ForegroundColor Green

# ── Step 7: verify ────────────────────────────────────────────────────────────
Write-Host "`n=== Verify ===" -ForegroundColor Cyan
$token = Get-Token
$headers.Authorization = "Bearer $token"
$verifyUrl = "$baseUrl/customcontrols?`$select=version,modifiedon&`$filter=name eq '$controlName'"
$verify = Invoke-RestMethod -Uri $verifyUrl -Headers $headers

if (-not $verify.value -or $verify.value.Count -eq 0) {
    throw "Verification failed: no customcontrol found named $controlName"
}
$deployed = $verify.value[0]
Write-Host "  Deployed version: $($deployed.version)  (modified: $($deployed.modifiedon))" -ForegroundColor Gray

if ($deployed.version -ne $version) {
    throw "Version mismatch: expected $version, found $($deployed.version)"
}

Write-Host "`nDeployed $controlName v$version successfully." -ForegroundColor Green
