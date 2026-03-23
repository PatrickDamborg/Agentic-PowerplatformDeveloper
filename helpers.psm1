function Initialize-DataverseConnection {
    param(
        [string]$EnvPath = (Join-Path $PSScriptRoot ".env")
    )

    # Load .env file
    Get-Content $EnvPath | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            [System.Environment]::SetEnvironmentVariable($Matches[1].Trim(), $Matches[2].Trim(), "Process")
        }
    }

    $dataverseUrl = $env:DATAVERSE_URL

    # Derive scope from DATAVERSE_URL (strip path, append /.default)
    $uri = [System.Uri]$dataverseUrl
    $scope = "$($uri.Scheme)://$($uri.Host)/.default"

    # Client credentials flow
    $tokenUrl = "https://login.microsoftonline.com/$env:TENANT_ID/oauth2/v2.0/token"
    $tokenBody = @{
        grant_type    = "client_credentials"
        client_id     = $env:CLIENT_ID
        client_secret = $env:CLIENT_SECRET
        scope         = $scope
    }

    $tokenResponse = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $tokenBody
    $accessToken = $tokenResponse.access_token

    $headers = @{
        Authorization      = "Bearer $accessToken"
        Accept             = "application/json"
        "Content-Type"     = "application/json; charset=utf-8"
        "OData-MaxVersion" = "4.0"
        "OData-Version"    = "4.0"
    }

    return @{
        Headers = $headers
        BaseUrl = $dataverseUrl
        Token   = $accessToken
    }
}

function Get-DataverseHeaders {
    param(
        [Parameter(Mandatory)][string]$SolutionName,
        [string]$EnvPath = (Join-Path $PSScriptRoot ".env")
    )

    $conn = Initialize-DataverseConnection -EnvPath $EnvPath
    $conn.Headers["MSCRM.SolutionUniqueName"] = $SolutionName
    return $conn
}

function Invoke-DataverseRequest {
    param(
        [Parameter(Mandatory)][string]$Method,
        [Parameter(Mandatory)][string]$Endpoint,
        [Parameter(Mandatory)][string]$BaseUrl,
        [Parameter(Mandatory)][hashtable]$Headers,
        [string]$Body
    )

    $url = "$BaseUrl/$Endpoint"

    $params = @{
        Method         = $Method
        Uri            = $url
        Headers        = $Headers
        UseBasicParsing = $true
    }
    if ($Body) {
        $params.Body = $Body
    }

    try {
        $response = Invoke-WebRequest @params
        if ($response.Content -and $response.Content.Length -gt 0) {
            return $response.Content | ConvertFrom-Json
        }
        return $response
    }
    catch {
        $errorMsg = $_.Exception.Message
        if ($_.ErrorDetails.Message) {
            try {
                $detail = $_.ErrorDetails.Message | ConvertFrom-Json
                $errorMsg = $detail.error.message
            }
            catch {
                $errorMsg = $_.ErrorDetails.Message
            }
        }
        throw "Dataverse API error: $errorMsg"
    }
}

Export-ModuleMember -Function Initialize-DataverseConnection, Get-DataverseHeaders, Invoke-DataverseRequest
