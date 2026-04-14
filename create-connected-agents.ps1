param([string]$EnvFile = (Join-Path $PSScriptRoot 'env'))

Get-Content $EnvFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        [System.Environment]::SetEnvironmentVariable($Matches[1].Trim(), $Matches[2].Trim(), 'Process')
    }
}

$tokenUrl = "https://login.microsoftonline.com/$env:TENANT_ID/oauth2/v2.0/token"
$body = @{ grant_type='client_credentials'; client_id=$env:CLIENT_ID; client_secret=$env:CLIENT_SECRET; scope='https://pdaprimary.api.crm4.dynamics.com/.default' }
$token = (Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $body).access_token

$headers = @{
    Authorization      = "Bearer $token"
    Accept             = 'application/json'
    'Content-Type'     = 'application/json; charset=utf-8'
    'OData-MaxVersion' = '4.0'
    'OData-Version'    = '4.0'
}

$whoami = Invoke-RestMethod -Uri "$env:DATAVERSE_URL/WhoAmI" -Headers $headers
$ownerId = $whoami.UserId

$agents = @(
    @{
        schemaname  = 'pda_xpm_risk_analyst'
        name        = 'Risk Analyst'
        description = 'Handles all risk-related requests. Use for identifying, scoring, mitigating, or logging risks on projects. Has read and write access to the risk table.'
    },
    @{
        schemaname  = 'pda_xpm_health_monitor'
        name        = 'Project Health Monitor'
        description = 'Produces executive status reports with RAG (Red/Amber/Green) colouring. Use for snapshot reports combining project, milestone, and task data into a concise narrative.'
    }
)

$configuration = @{
    '$kind'                  = 'BotConfiguration'
    settings                 = @{ GenerativeActionsEnabled = $true }
    isAgentConnectable       = $true
    aISettings               = @{
        '$kind'                  = 'AISettings'
        useModelKnowledge        = $true
        isFileAnalysisEnabled    = $false
        isSemanticSearchEnabled  = $false
        contentModeration        = 'High'
        optInUseLatestModels     = $false
    }
    recognizer               = @{ '$kind' = 'GenerativeAIRecognizer' }
} | ConvertTo-Json -Depth 10

foreach ($agent in $agents) {
    $payload = @{
        schemaname            = $agent.schemaname
        name                  = $agent.name
        language              = 1033
        authenticationtrigger = 0
        authenticationmode    = 1
        runtimeprovider       = 0
        statecode             = 0
        accesscontrolpolicy   = 0
        configuration         = $configuration
        'ownerid@odata.bind'  = "/systemusers($ownerId)"
    } | ConvertTo-Json -Depth 10

    Write-Host "Creating '$($agent.name)'..."
    try {
        $response = Invoke-WebRequest -Method Post -Uri "$env:DATAVERSE_URL/bots" -Headers $headers -Body $payload -UseBasicParsing
        $botId = $response.Headers['OData-EntityId'] -replace '.*bots\((.+)\).*', '$1'
        Write-Host "  Created. BotId: $botId"

        # Add to XPMCopilotSkills solution
        $addPayload = @{
            ComponentId           = $botId
            ComponentType         = 10212
            SolutionUniqueName    = 'XPMCopilotSkills'
            AddRequiredComponents = $false
        } | ConvertTo-Json

        Invoke-RestMethod -Method Post -Uri "$env:DATAVERSE_URL/AddSolutionComponent" -Headers $headers -Body $addPayload | Out-Null
        Write-Host "  Added to XPMCopilotSkills."
    } catch {
        Write-Host "  ERROR: $($_.Exception.Message)"
        if ($_.ErrorDetails.Message) { Write-Host "  $($_.ErrorDetails.Message)" }
    }
}
