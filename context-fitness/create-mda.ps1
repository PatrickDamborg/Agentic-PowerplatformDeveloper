#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Create the "Context & Fitness" model-driven app for the JBT Marel workshop.
    Delegates to the generic create-mda skill script.
#>
param(
    [string]$SolutionName = "ContextFitnessAgent"
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "helpers.psm1"))) {
    $root = Split-Path $root -Parent
}

$siteMapXml = @'
<SiteMap>
  <Area Id="fitness_area" Title="Fitness Training" ShowGroups="true">
    <Group Id="fitness_group" Title="Training Data" IsProfile="false">
      <SubArea Id="nav_trainingprofiles"   Entity="context_trainingprofile"   Title="Training Profiles"   />
      <SubArea Id="nav_trainingprogrammes" Entity="context_trainingprogramme" Title="Training Programmes" />
      <SubArea Id="nav_exercises"          Entity="context_exercise"          Title="Exercises"           />
    </Group>
  </Area>
</SiteMap>
'@

& (Join-Path $root ".claude/skills/model-driven-app/create-mda.ps1") `
    -AppDisplayName    "Context & Fitness" `
    -AppUniqueName     "ContextFitness" `
    -SiteMapXml        $siteMapXml `
    -EntityLogicalNames @("context_trainingprofile", "context_trainingprogramme", "context_exercise") `
    -SolutionName      $SolutionName `
    -Description       "Workshop verification app — view training profiles, programmes, and exercises written by the personal training agent"
