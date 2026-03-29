#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Create the ActivityLog Dataverse table for the Activity Dashboard.
.DESCRIPTION
    Creates a table to store all actions taken by the AI agent in a Dataverse environment.
    Each record captures the what, why, how, and best-practice notes for educational traceability.
.PARAMETER Prefix
    Publisher prefix (e.g. "pda"). Do NOT include trailing underscore.
.PARAMETER SolutionName
    Solution unique name to associate the table with.
.EXAMPLE
    pwsh dashboard/create-activity-log-table.ps1 -Prefix "pda" -SolutionName "PPMextension"
#>
param(
    [Parameter(Mandatory)][string]$Prefix,
    [Parameter(Mandatory)][string]$SolutionName
)

$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "helpers.psm1"))) {
    $root = Split-Path $root -Parent
}
if (-not $root) { throw "Cannot find helpers.psm1 in any parent directory." }
Import-Module (Join-Path $root "helpers.psm1") -Force

$conn = Get-DataverseHeaders -SolutionName $SolutionName -EnvPath (Join-Path $root ".env")

$schemaName = "${Prefix}_ActivityLog"
$logicalName = $schemaName.ToLower()

# --- Step 1: Create the table with primary name column ---
Write-Host "Creating table '$schemaName'..." -ForegroundColor Cyan

$tableBody = @{
    "@odata.type"       = "Microsoft.Dynamics.CRM.EntityMetadata"
    SchemaName          = $schemaName
    DisplayName         = @{
        "@odata.type"   = "Microsoft.Dynamics.CRM.Label"
        LocalizedLabels = @(@{
            "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
            Label         = "Activity Log"
            LanguageCode  = 1033
        })
    }
    DisplayCollectionName = @{
        "@odata.type"   = "Microsoft.Dynamics.CRM.Label"
        LocalizedLabels = @(@{
            "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
            Label         = "Activity Logs"
            LanguageCode  = 1033
        })
    }
    Description         = @{
        "@odata.type"   = "Microsoft.Dynamics.CRM.Label"
        LocalizedLabels = @(@{
            "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
            Label         = "Tracks all AI agent actions with educational context (what, why, how, best practices) for traceability and learning."
            LanguageCode  = 1033
        })
    }
    OwnershipType       = "UserOwned"
    IsActivity          = $false
    HasActivities       = $false
    HasNotes            = $true
    PrimaryNameAttribute = "${Prefix}_title".ToLower()
    Attributes          = @(@{
        "@odata.type" = "Microsoft.Dynamics.CRM.StringAttributeMetadata"
        SchemaName    = "${Prefix}_Title"
        AttributeType = "String"
        MaxLength     = 500
        FormatName    = @{ Value = "Text" }
        DisplayName   = @{
            "@odata.type"   = "Microsoft.Dynamics.CRM.Label"
            LocalizedLabels = @(@{
                "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                Label         = "Title"
                LanguageCode  = 1033
            })
        }
        Description   = @{
            "@odata.type"   = "Microsoft.Dynamics.CRM.Label"
            LocalizedLabels = @(@{
                "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                Label         = "Short summary of the action taken"
                LanguageCode  = 1033
            })
        }
        IsPrimaryName = $true
        RequiredLevel = @{ Value = "ApplicationRequired" }
    })
} | ConvertTo-Json -Depth 20

Invoke-DataverseRequest -Method POST -Endpoint "EntityDefinitions" -BaseUrl $conn.BaseUrl -Headers $conn.Headers -Body $tableBody
Write-Host "Table created." -ForegroundColor Green

# --- Step 2: Add additional columns ---
Write-Host "Adding columns..." -ForegroundColor Cyan

$attributesEndpoint = "EntityDefinitions(LogicalName='$logicalName')/Attributes"

# Multiline text columns: What, Why, How, BestPractice
$textColumns = @(
    @{ Name = "What";         Label = "What";          Description = "What action was performed — describes the operation in plain language" }
    @{ Name = "Why";          Label = "Why";           Description = "The business reason or design decision behind this action" }
    @{ Name = "How";          Label = "How";           Description = "Technical details — API calls, scripts, configurations used" }
    @{ Name = "BestPractice"; Label = "Best Practice";  Description = "Best-practice notes and recommendations for learning" }
    @{ Name = "Entity";       Label = "Component";     Description = "The Dataverse component affected (table, column, flow, etc.)" }
    @{ Name = "ApiEndpoint";  Label = "API Endpoint";  Description = "The API endpoint or operation used" }
    @{ Name = "SessionId";    Label = "Session ID";    Description = "Groups actions from the same agent session" }
    @{ Name = "Environment";  Label = "Environment";   Description = "The Dataverse environment URL where the action was performed" }
)

foreach ($col in $textColumns) {
    $isMultiline = $col.Name -in @("What", "Why", "How", "BestPractice")
    $maxLen = if ($isMultiline) { 10000 } else { 2000 }
    $format = if ($isMultiline) { "TextArea" } else { "Text" }

    $colBody = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.StringAttributeMetadata"
        SchemaName    = "${Prefix}_$($col.Name)"
        AttributeType = "String"
        MaxLength     = $maxLen
        FormatName    = @{ Value = $format }
        DisplayName   = @{
            "@odata.type"   = "Microsoft.Dynamics.CRM.Label"
            LocalizedLabels = @(@{
                "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                Label         = $col.Label
                LanguageCode  = 1033
            })
        }
        Description   = @{
            "@odata.type"   = "Microsoft.Dynamics.CRM.Label"
            LocalizedLabels = @(@{
                "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                Label         = $col.Description
                LanguageCode  = 1033
            })
        }
        RequiredLevel = @{ Value = "None" }
    } | ConvertTo-Json -Depth 20

    Invoke-DataverseRequest -Method POST -Endpoint $attributesEndpoint -BaseUrl $conn.BaseUrl -Headers $conn.Headers -Body $colBody
    Write-Host "  + $($col.Label)" -ForegroundColor White
}

# DateTime column: ExecutedOn
$dateBody = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.DateTimeAttributeMetadata"
    SchemaName    = "${Prefix}_ExecutedOn"
    AttributeType = "DateTime"
    Format        = "DateAndTime"
    DisplayName   = @{
        "@odata.type"   = "Microsoft.Dynamics.CRM.Label"
        LocalizedLabels = @(@{
            "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
            Label         = "Executed On"
            LanguageCode  = 1033
        })
    }
    Description   = @{
        "@odata.type"   = "Microsoft.Dynamics.CRM.Label"
        LocalizedLabels = @(@{
            "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
            Label         = "When the action was performed"
            LanguageCode  = 1033
        })
    }
    RequiredLevel = @{ Value = "None" }
} | ConvertTo-Json -Depth 20

Invoke-DataverseRequest -Method POST -Endpoint $attributesEndpoint -BaseUrl $conn.BaseUrl -Headers $conn.Headers -Body $dateBody
Write-Host "  + Executed On" -ForegroundColor White

# Choice column: Category
$categoryBody = @{
    "@odata.type"  = "Microsoft.Dynamics.CRM.PicklistAttributeMetadata"
    SchemaName     = "${Prefix}_Category"
    AttributeType  = "Picklist"
    DisplayName    = @{
        "@odata.type"   = "Microsoft.Dynamics.CRM.Label"
        LocalizedLabels = @(@{
            "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
            Label         = "Category"
            LanguageCode  = 1033
        })
    }
    Description    = @{
        "@odata.type"   = "Microsoft.Dynamics.CRM.Label"
        LocalizedLabels = @(@{
            "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
            Label         = "The type of action performed"
            LanguageCode  = 1033
        })
    }
    RequiredLevel  = @{ Value = "None" }
    OptionSet      = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.OptionSetMetadata"
        IsGlobal      = $false
        OptionSetType = "Picklist"
        Options       = @(
            @{ Value = 100000000; Label = @{ "@odata.type" = "Microsoft.Dynamics.CRM.Label"; LocalizedLabels = @(@{ "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"; Label = "Schema Change"; LanguageCode = 1033 }) } }
            @{ Value = 100000001; Label = @{ "@odata.type" = "Microsoft.Dynamics.CRM.Label"; LocalizedLabels = @(@{ "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"; Label = "Cloud Flow"; LanguageCode = 1033 }) } }
            @{ Value = 100000002; Label = @{ "@odata.type" = "Microsoft.Dynamics.CRM.Label"; LocalizedLabels = @(@{ "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"; Label = "Solution Operation"; LanguageCode = 1033 }) } }
            @{ Value = 100000003; Label = @{ "@odata.type" = "Microsoft.Dynamics.CRM.Label"; LocalizedLabels = @(@{ "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"; Label = "Security"; LanguageCode = 1033 }) } }
            @{ Value = 100000004; Label = @{ "@odata.type" = "Microsoft.Dynamics.CRM.Label"; LocalizedLabels = @(@{ "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"; Label = "Configuration"; LanguageCode = 1033 }) } }
            @{ Value = 100000005; Label = @{ "@odata.type" = "Microsoft.Dynamics.CRM.Label"; LocalizedLabels = @(@{ "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"; Label = "Data Migration"; LanguageCode = 1033 }) } }
            @{ Value = 100000006; Label = @{ "@odata.type" = "Microsoft.Dynamics.CRM.Label"; LocalizedLabels = @(@{ "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"; Label = "Other"; LanguageCode = 1033 }) } }
        )
    }
} | ConvertTo-Json -Depth 20

Invoke-DataverseRequest -Method POST -Endpoint $attributesEndpoint -BaseUrl $conn.BaseUrl -Headers $conn.Headers -Body $categoryBody
Write-Host "  + Category" -ForegroundColor White

# Choice column: Status
$statusBody = @{
    "@odata.type"  = "Microsoft.Dynamics.CRM.PicklistAttributeMetadata"
    SchemaName     = "${Prefix}_ActionStatus"
    AttributeType  = "Picklist"
    DisplayName    = @{
        "@odata.type"   = "Microsoft.Dynamics.CRM.Label"
        LocalizedLabels = @(@{
            "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
            Label         = "Action Status"
            LanguageCode  = 1033
        })
    }
    Description    = @{
        "@odata.type"   = "Microsoft.Dynamics.CRM.Label"
        LocalizedLabels = @(@{
            "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
            Label         = "Whether the action completed successfully"
            LanguageCode  = 1033
        })
    }
    RequiredLevel  = @{ Value = "None" }
    OptionSet      = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.OptionSetMetadata"
        IsGlobal      = $false
        OptionSetType = "Picklist"
        Options       = @(
            @{ Value = 100000000; Label = @{ "@odata.type" = "Microsoft.Dynamics.CRM.Label"; LocalizedLabels = @(@{ "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"; Label = "Completed"; LanguageCode = 1033 }) } }
            @{ Value = 100000001; Label = @{ "@odata.type" = "Microsoft.Dynamics.CRM.Label"; LocalizedLabels = @(@{ "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"; Label = "In Progress"; LanguageCode = 1033 }) } }
            @{ Value = 100000002; Label = @{ "@odata.type" = "Microsoft.Dynamics.CRM.Label"; LocalizedLabels = @(@{ "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"; Label = "Failed"; LanguageCode = 1033 }) } }
        )
    }
} | ConvertTo-Json -Depth 20

Invoke-DataverseRequest -Method POST -Endpoint $attributesEndpoint -BaseUrl $conn.BaseUrl -Headers $conn.Headers -Body $statusBody
Write-Host "  + Action Status" -ForegroundColor White

# --- Step 3: Publish ---
Write-Host "Publishing customizations..." -ForegroundColor Cyan
$publishBody = @{
    ParameterXml = "<importexportxml><entities><entity>$logicalName</entity></entities></importexportxml>"
} | ConvertTo-Json
Invoke-DataverseRequest -Method POST -Endpoint "PublishXml" -BaseUrl $conn.BaseUrl -Headers $conn.Headers -Body $publishBody

Write-Host "`nActivity Log table created successfully!" -ForegroundColor Green
Write-Host "  Table: $logicalName" -ForegroundColor White
Write-Host "  Columns: Title, What, Why, How, Best Practice, Component, API Endpoint, Session ID, Environment, Executed On, Category, Action Status" -ForegroundColor White
