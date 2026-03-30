#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Start a local web server for the Activity Dashboard.
.DESCRIPTION
    Serves the dashboard on http://localhost:8080 using Python's built-in HTTP server.
    This URL must match the redirect URI configured in your Azure AD app registration.
.PARAMETER Port
    Port number (default: 8080).
#>
param([int]$Port = 8080)

$dashboardPath = $PSScriptRoot

Write-Host "Starting Activity Dashboard at http://localhost:$Port" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop." -ForegroundColor Gray
Write-Host ""

# Use Python (available on most systems) as a simple HTTP server
if (Get-Command python3 -ErrorAction SilentlyContinue) {
    python3 -m http.server $Port --directory $dashboardPath
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    python -m http.server $Port --directory $dashboardPath
} else {
    Write-Host "Python not found. Install Python or serve these files with any HTTP server." -ForegroundColor Red
    Write-Host "Alternative: npx http-server $dashboardPath -p $Port" -ForegroundColor Yellow
}
