param(
    [string[]]$Tables,
    [string]$SolutionName = "PPMextension",
    [string]$OutputPath
)

# Resolve repository root
$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "helpers.psm1"))) { $root = Split-Path $root -Parent }
if (-not $root) { throw "Cannot find helpers.psm1 in any parent directory." }
if (-not $OutputPath) { $OutputPath = Join-Path $root "schema_dump.json" }
Import-Module (Join-Path $root "helpers.psm1") -Force
$conn = Initialize-DataverseConnection -EnvPath (Join-Path $root ".env")
$h = $conn.Headers
$url = $conn.BaseUrl

Write-Host "Querying solution '$SolutionName' for tables..." -ForegroundColor Cyan

# Get solution ID
$sol = Invoke-DataverseRequest -Method GET -Endpoint "solutions?`$filter=uniquename eq '$SolutionName'&`$select=solutionid" -BaseUrl $url -Headers $h
$solutionId = $sol.value[0].solutionid
if (-not $solutionId) {
    throw "Solution '$SolutionName' not found"
}

# Get entity components (componenttype 1 = Entity)
$components = Invoke-DataverseRequest -Method GET -Endpoint "solutioncomponents?`$filter=_solutionid_value eq '$solutionId' and componenttype eq 1&`$select=objectid" -BaseUrl $url -Headers $h
$entityIds = $components.value | ForEach-Object { $_.objectid }

Write-Host "Found $($entityIds.Count) table(s) in solution" -ForegroundColor Green

$schema = @{
    generated   = (Get-Date -Format "o")
    environment = ([System.Uri]$url).GetLeftPart([System.UriPartial]::Authority)
    solution    = $SolutionName
    tables      = @{}
}

foreach ($entityId in $entityIds) {
    # Get entity metadata
    $entityMeta = Invoke-DataverseRequest -Method GET -Endpoint "EntityDefinitions($entityId)?`$select=LogicalName,SchemaName,EntitySetName,PrimaryIdAttribute,PrimaryNameAttribute,DisplayName" -BaseUrl $url -Headers $h

    $logicalName = $entityMeta.LogicalName

    # Skip if -Tables filter provided and this table doesn't match
    if ($Tables -and $Tables.Count -gt 0) {
        $match = $false
        foreach ($t in $Tables) {
            if ($logicalName -like "*$t*") { $match = $true; break }
        }
        if (-not $match) { continue }
    }

    Write-Host "  Dumping: $logicalName" -ForegroundColor Yellow

    $displayName = ""
    if ($entityMeta.DisplayName -and $entityMeta.DisplayName.UserLocalizedLabel) {
        $displayName = $entityMeta.DisplayName.UserLocalizedLabel.Label
    }

    # Get attributes (custom + primary)
    $attrs = Invoke-DataverseRequest -Method GET -Endpoint "EntityDefinitions($entityId)/Attributes?`$select=LogicalName,SchemaName,AttributeType,DisplayName,RequiredLevel,IsPrimaryId,IsPrimaryName&`$filter=IsCustomAttribute eq true or IsPrimaryId eq true or IsPrimaryName eq true" -BaseUrl $url -Headers $h

    $columns = @{}
    foreach ($attr in $attrs.value) {
        $colDisplayName = ""
        if ($attr.DisplayName -and $attr.DisplayName.UserLocalizedLabel) {
            $colDisplayName = $attr.DisplayName.UserLocalizedLabel.Label
        }

        $colDef = @{
            type        = $attr.AttributeType
            displayName = $colDisplayName
            required    = $attr.RequiredLevel.Value
        }

        # For Picklist columns, get options
        if ($attr.AttributeType -eq "Picklist") {
            try {
                $optionSet = Invoke-DataverseRequest -Method GET -Endpoint "EntityDefinitions($entityId)/Attributes($($attr.MetadataId))/Microsoft.Dynamics.CRM.PicklistAttributeMetadata?`$select=LogicalName&`$expand=OptionSet" -BaseUrl $url -Headers $h
                $options = @()
                foreach ($opt in $optionSet.OptionSet.Options) {
                    $optLabel = ""
                    if ($opt.Label -and $opt.Label.UserLocalizedLabel) {
                        $optLabel = $opt.Label.UserLocalizedLabel.Label
                    }
                    $options += @{ value = $opt.Value; label = $optLabel }
                }
                $colDef.options = $options
            }
            catch {
                Write-Host "    Warning: Could not fetch options for $($attr.LogicalName)" -ForegroundColor DarkYellow
            }
        }

        # For Lookup columns, get target entity
        if ($attr.AttributeType -eq "Lookup") {
            try {
                $lookupMeta = Invoke-DataverseRequest -Method GET -Endpoint "EntityDefinitions($entityId)/Attributes($($attr.MetadataId))/Microsoft.Dynamics.CRM.LookupAttributeMetadata?`$select=Targets" -BaseUrl $url -Headers $h
                if ($lookupMeta.Targets) {
                    $colDef.targets = $lookupMeta.Targets
                }
            }
            catch {
                Write-Host "    Warning: Could not fetch lookup targets for $($attr.LogicalName)" -ForegroundColor DarkYellow
            }
        }

        $columns[$attr.LogicalName] = $colDef
    }

    # Get relationships
    $oneToMany = Invoke-DataverseRequest -Method GET -Endpoint "EntityDefinitions($entityId)/OneToManyRelationships?`$select=SchemaName,ReferencedEntity,ReferencingEntity,ReferencingAttribute,ReferencedEntityNavigationPropertyName,ReferencingEntityNavigationPropertyName" -BaseUrl $url -Headers $h
    $manyToOne = Invoke-DataverseRequest -Method GET -Endpoint "EntityDefinitions($entityId)/ManyToOneRelationships?`$select=SchemaName,ReferencedEntity,ReferencingEntity,ReferencingAttribute,ReferencedEntityNavigationPropertyName,ReferencingEntityNavigationPropertyName" -BaseUrl $url -Headers $h
    $manyToMany = Invoke-DataverseRequest -Method GET -Endpoint "EntityDefinitions($entityId)/ManyToManyRelationships?`$select=SchemaName,Entity1LogicalName,Entity2LogicalName,Entity1NavigationPropertyName,Entity2NavigationPropertyName" -BaseUrl $url -Headers $h

    $schema.tables[$logicalName] = @{
        displayName   = $displayName
        entitySetName = $entityMeta.EntitySetName
        primaryId     = $entityMeta.PrimaryIdAttribute
        primaryName   = $entityMeta.PrimaryNameAttribute
        columns       = $columns
        relationships = @{
            oneToMany  = $oneToMany.value | ForEach-Object {
                @{
                    schemaName       = $_.SchemaName
                    referencedEntity = $_.ReferencedEntity
                    referencingEntity = $_.ReferencingEntity
                    referencingAttribute = $_.ReferencingAttribute
                    navigationProperty   = $_.ReferencedEntityNavigationPropertyName
                }
            }
            manyToOne  = $manyToOne.value | ForEach-Object {
                @{
                    schemaName       = $_.SchemaName
                    referencedEntity = $_.ReferencedEntity
                    referencingEntity = $_.ReferencingEntity
                    referencingAttribute = $_.ReferencingAttribute
                    navigationProperty   = $_.ReferencingEntityNavigationPropertyName
                }
            }
            manyToMany = $manyToMany.value | ForEach-Object {
                @{
                    schemaName = $_.SchemaName
                    entity1    = $_.Entity1LogicalName
                    entity2    = $_.Entity2LogicalName
                }
            }
        }
    }
}

$schema | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "`nSchema dumped to: $OutputPath" -ForegroundColor Green
Write-Host "Tables: $($schema.tables.Keys.Count)" -ForegroundColor Green
