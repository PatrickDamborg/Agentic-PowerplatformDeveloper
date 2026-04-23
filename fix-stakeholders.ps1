#!/usr/bin/env pwsh
# Creates the 38 stakeholders that failed due to wrong picklist values for
# pum_influence and pum_interest (accepted: 493840001=Low, 493840002=Medium, 493840003=High)

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

$ini1  = "d6351a72-0a3f-f111-bec6-70a8a59a44c4"
$ini2  = "f8351a72-0a3f-f111-bec6-70a8a59a44c4"
$ini3  = "18361a72-0a3f-f111-bec6-70a8a59a44c4"
$ini4  = "37361a72-0a3f-f111-bec6-70a8a59a44c4"
$ini5  = "b7611778-0a3f-f111-bec6-70a8a59a44c4"
$ini6  = "52621778-0a3f-f111-bec6-70a8a59a44c4"
$ini7  = "f5611778-0a3f-f111-bec6-70a8a59a44c4"
$ini8  = "14621778-0a3f-f111-bec6-70a8a59a44c4"
$ini9  = "17154a7e-0a3f-f111-bec6-70a8a59a44c4"
$ini10 = "d6611778-0a3f-f111-bec6-70a8a59a44c4"
$ini11 = "71621778-0a3f-f111-bec6-70a8a59a44c4"
$ini12 = "33621778-0a3f-f111-bec6-70a8a59a44c4"

# pum_stakeholdertype: 493840000=Internal 493840001=External
# pum_influence / pum_interest: 493840001=Low 493840002=Medium 493840003=High

function New-Stakeholder {
    param($name,$iniId,$type,$influence,$interest)
    $body = @{
        pum_name            = $name
        pum_stakeholdertype = $type
        pum_influence       = $influence
        pum_interest        = $interest
        "pum_Initiative@odata.bind" = "/pum_initiatives($iniId)"
    }
    Post-Record "pum_stakeholders" $body "pum_stakeholderid" "Stakeholder: $name"
}

Write-Host "`n=== Stakeholders (only the 23 that previously failed) ===" -ForegroundColor Yellow

# Customer Self-Service Portal
New-Stakeholder "Emma Larsson"      $ini1  493840000 493840003 493840003
New-Stakeholder "Maria Santos"      $ini1  493840000 493840002 493840002

# Mobile App for Field Service
New-Stakeholder "Jake Williams"     $ini2  493840000 493840003 493840003
New-Stakeholder "Tom Mueller"       $ini2  493840001 493840002 493840002

# CRM Integration & Automation
New-Stakeholder "Sarah Mitchell"    $ini3  493840000 493840003 493840003
New-Stakeholder "Fiona Bradley"     $ini3  493840001 493840001 493840002

# Enterprise Data Lake
New-Stakeholder "Robert Kim"        $ini4  493840000 493840003 493840003
New-Stakeholder "Lars Eriksson"     $ini4  493840001 493840002 493840002

# Sales Forecasting ML
New-Stakeholder "James O'Brien"     $ini5  493840000 493840003 493840003
New-Stakeholder "Nicole Beaumont"   $ini5  493840001 493840002 493840002

# Digital Onboarding
New-Stakeholder "Michelle Harper"   $ini6  493840000 493840003 493840003
New-Stakeholder "Sophie Laurent"    $ini6  493840001 493840001 493840002

# ERP Assessment
New-Stakeholder "Diana Walsh"       $ini7  493840000 493840002 493840003

# Finance Module Migration
New-Stakeholder "Catherine Moore"   $ini8  493840000 493840003 493840003
New-Stakeholder "Helena Johansson"  $ini8  493840001 493840002 493840002

# M365 Collaboration
New-Stakeholder "Natasha Brooks"    $ini9  493840000 493840003 493840002
New-Stakeholder "Yuki Tanaka"       $ini9  493840001 493840002 493840002

# Real-Time Analytics Dashboard
New-Stakeholder "Simon Clarke"      $ini10 493840000 493840003 493840003
New-Stakeholder "Ahmed Hassan"      $ini10 493840001 493840002 493840002

# Automated Compliance
New-Stakeholder "Laura Henriksen"   $ini11 493840000 493840003 493840003
New-Stakeholder "Petra Kovacs"      $ini11 493840001 493840002 493840002

# Supply Chain
New-Stakeholder "Derek Chambers"    $ini12 493840000 493840003 493840003
New-Stakeholder "Clara Weiss"       $ini12 493840001 493840002 493840002

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Stakeholders Fix Complete!"
Write-Host "  Succeeded : $($script:ok)"  -ForegroundColor Green
Write-Host "  Failed    : $($script:err)" -ForegroundColor $(if ($script:err -gt 0) { 'Red' } else { 'Green' })
Write-Host "============================================" -ForegroundColor Cyan
