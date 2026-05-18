#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Update main forms for all three Fitness Training tables to include all custom columns.
#>
param(
    [string]$SolutionName = "ContextFitnessAgent"
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "helpers.psm1"))) {
    $root = Split-Path $root -Parent
}
Import-Module (Join-Path $root "helpers.psm1") -Force
$conn = Get-DataverseHeaders -SolutionName $SolutionName -EnvPath (Join-Path $root ".env")

# ---- classid constants ----
$cs = @{
    String   = "{4273EDBD-AC1D-40d3-9FB2-095C621B552D}"
    Memo     = "{E0DECE4B-6FC8-4a8f-A065-082708572369}"
    Numeric  = "{C6D124CA-7EDA-4a60-AEA9-7FB8D318B68F}"   # Integer & Decimal
    Choice   = "{3EF39988-22BB-4f0b-BBBE-64B5A3748AEE}"
    DateTime = "{5B773807-9FB2-42db-97C3-7A91EFF8ADFF}"
    Lookup   = "{270BD3DB-D9AF-4782-9025-509E298DEC0A}"
}

function g { [System.Guid]::NewGuid().ToString("B").ToUpper() }

function New-Row {
    param([hashtable[]]$Cells)
    $cellXml = $Cells | ForEach-Object {
        $id = g
        if ($_.Empty) {
            "<cell id=`"$id`" showlabel=`"false`" />"
        } else {
            @"
<cell id="$id">
              <labels><label description="$($_.Label)" languagecode="1033" /></labels>
              <control id="$($_.Field)" classid="$($_.ClassId)" datafieldname="$($_.Field)" disabled="false" />
            </cell>
"@
        }
    }
    "<row>" + ($cellXml -join "") + "</row>"
}

function New-Section {
    param([string]$Title, [int]$Columns = 2, [string]$RowsXml)
    $id = g
    @"
<section name="sec_$([System.Guid]::NewGuid().ToString('N').Substring(0,8))" showlabel="true" showbar="false" columns="$Columns" id="$id">
            <labels><label description="$Title" languagecode="1033" /></labels>
            <rows>
              $RowsXml
            </rows>
          </section>
"@
}

function New-Form {
    param([string]$SectionsXml)
    $tabId = g
    @"
<form>
  <tabs>
    <tab verticallayout="true" id="$tabId" IsUserDefined="1">
      <labels><label description="General" languagecode="1033" /></labels>
      <columns>
        <column width="100%">
          <sections>
            $SectionsXml
          </sections>
        </column>
      </columns>
    </tab>
  </tabs>
</form>
"@
}

function Update-Form {
    param([string]$TableLogicalName, [string]$FormXml)

    # Get the main form id (type 2)
    $formsResp = Invoke-RestMethod -Uri "$($conn.BaseUrl)/systemforms?`$filter=objecttypecode eq '$TableLogicalName' and type eq 2&`$select=formid,name" -Headers $conn.Headers
    if ($formsResp.value.Count -eq 0) { Write-Host "  No main form found for $TableLogicalName" -ForegroundColor Yellow; return }

    $form = $formsResp.value[0]
    Write-Host "  Updating form '$($form.name)' ($($form.formid))..." -ForegroundColor Gray

    $patchBody = @{ formxml = $FormXml } | ConvertTo-Json
    $patchHeaders = $conn.Headers.Clone()
    $patchHeaders["If-Match"] = "*"

    Invoke-RestMethod -Method PATCH -Uri "$($conn.BaseUrl)/systemforms($($form.formid))" -Headers $patchHeaders -Body $patchBody
    Write-Host "  Updated." -ForegroundColor Green

    # Publish
    $pubBody = @{ ParameterXml = "<importexportxml><entities><entity>$TableLogicalName</entity></entities></importexportxml>" } | ConvertTo-Json
    Invoke-RestMethod -Method POST -Uri "$($conn.BaseUrl)/PublishXml" -Headers $conn.Headers -Body $pubBody
}

# ============================================================
# Training Profile form
# ============================================================
Write-Host "`nUpdating Training Profile form..." -ForegroundColor Cyan

$profileSection1Rows = @(
    (New-Row @(@{ Label="Name";        Field="context_name";   ClassId=$cs.String  }, @{ Label="Gender";     Field="context_gender"; ClassId=$cs.Choice  })),
    (New-Row @(@{ Label="Age";         Field="context_age";    ClassId=$cs.Numeric }, @{ Label="Weight (kg)";Field="context_weight"; ClassId=$cs.Numeric })),
    (New-Row @(@{ Label="Height (cm)"; Field="context_height"; ClassId=$cs.Numeric }, @{ Empty=$true }))
) -join "`n"

$profileSection2Rows = @(
    (New-Row @(@{ Label="Goals";       Field="context_goals";       ClassId=$cs.Memo })),
    (New-Row @(@{ Label="Injuries";    Field="context_injuries";    ClassId=$cs.Memo })),
    (New-Row @(@{ Label="Preferences"; Field="context_preferences"; ClassId=$cs.Memo }))
) -join "`n"

$profileFormXml = New-Form -SectionsXml (
    (New-Section -Title "Personal Details"       -Columns 2 -RowsXml $profileSection1Rows) + "`n" +
    (New-Section -Title "Fitness Goals and Notes" -Columns 1 -RowsXml $profileSection2Rows)
)
Update-Form -TableLogicalName "context_trainingprofile" -FormXml $profileFormXml

# ============================================================
# Training Programme form
# ============================================================
Write-Host "`nUpdating Training Programme form..." -ForegroundColor Cyan

$programmeSection1Rows = @(
    (New-Row @(@{ Label="Name";             Field="context_name";              ClassId=$cs.String   }, @{ Label="Training Profile"; Field="context_trainingprofileid"; ClassId=$cs.Lookup   })),
    (New-Row @(@{ Label="Start Date";       Field="context_startdate";         ClassId=$cs.DateTime }, @{ Label="Duration (weeks)"; Field="context_durationweeks";     ClassId=$cs.Numeric  })),
    (New-Row @(@{ Label="Status";           Field="context_status";            ClassId=$cs.Choice   }, @{ Empty=$true }))
) -join "`n"

$programmeSection2Rows = @(
    (New-Row @(@{ Label="Notes"; Field="context_notes"; ClassId=$cs.Memo }))
) -join "`n"

$programmeFormXml = New-Form -SectionsXml (
    (New-Section -Title "Programme Details" -Columns 2 -RowsXml $programmeSection1Rows) + "`n" +
    (New-Section -Title "Notes"             -Columns 1 -RowsXml $programmeSection2Rows)
)
Update-Form -TableLogicalName "context_trainingprogramme" -FormXml $programmeFormXml

# ============================================================
# Exercise form
# ============================================================
Write-Host "`nUpdating Exercise form..." -ForegroundColor Cyan

$exerciseSection1Rows = @(
    (New-Row @(@{ Label="Name";               Field="context_name";               ClassId=$cs.String  }, @{ Label="Training Programme"; Field="context_trainingprogrammeid"; ClassId=$cs.Lookup  })),
    (New-Row @(@{ Label="Day of Week";        Field="context_dayofweek";          ClassId=$cs.Choice  }, @{ Label="Sequence";            Field="context_sequence";            ClassId=$cs.Numeric })),
    (New-Row @(@{ Label="Sets";               Field="context_sets";               ClassId=$cs.Numeric }, @{ Label="Reps";                Field="context_reps";                ClassId=$cs.String  })),
    (New-Row @(@{ Label="Weight / Intensity"; Field="context_weightintensity";    ClassId=$cs.String  }, @{ Label="Rest (seconds)";      Field="context_restperiod";          ClassId=$cs.Numeric }))
) -join "`n"

$exerciseSection2Rows = @(
    (New-Row @(@{ Label="Notes"; Field="context_exercisenotes"; ClassId=$cs.Memo }))
) -join "`n"

$exerciseFormXml = New-Form -SectionsXml (
    (New-Section -Title "Exercise Details" -Columns 2 -RowsXml $exerciseSection1Rows) + "`n" +
    (New-Section -Title "Notes"            -Columns 1 -RowsXml $exerciseSection2Rows)
)
Update-Form -TableLogicalName "context_exercise" -FormXml $exerciseFormXml

Write-Host "`nAll forms updated." -ForegroundColor Green
