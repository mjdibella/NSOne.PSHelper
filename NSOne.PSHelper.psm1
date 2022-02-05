﻿Add-Type -AssemblyName System.Security
Add-Type -AssemblyName System.Web

function Connect-NSOne {
    param(
        [Parameter(Mandatory=$true)][string]$apitoken
    )
    $nsoneConfig.apitoken = $apitoken
    New-Item -Path $nsoneConfig.registryURL -Force | Out-null
    New-ItemProperty -Path $nsoneConfig.registryURL -Name apitoken -Value $apitoken -Force | Out-Null
    Write-host "Connected to NSOne`n"
}

function Disconnect-NSOne {
    Remove-ItemProperty -Path $nsoneConfig.registryURL -Name apitoken | Out-Null
    $nsoneconfig.tenant = $null
    $nsoneConfig.apitoken = $null
    $nsoneConfig.logtoken = $null
}

function Get-NSOneRecord {
    param(
        [Parameter(Mandatory=$true)][string]$zone,
        [Parameter(Mandatory=$true)][string]$domain,
        [Parameter(Mandatory=$true)][string]$type
    )
    <#
    curl -X GET -H "X-NSONE-Key: $API_KEY" https://api.nsone.net/v1/zones/:zone/:domain/:type
    #>
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $uri = "https://api.nsone.net/v1/zones/$zone/$domain/$type"
    try {
        $webresponse = invoke-webrequest -uri $uri -method Get -headers @{"X-NSONE-Key" = "$($nsoneConfig.apitoken)"}
        $webresponse.content
        ConvertFrom-JSON $webresponse.Content
    } catch {
        Set-NSOneRESTErrorResponse
    }
}

function Update-NSOneRecord {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline)][PSObject[]]$records
    )
    <#
    curl -X POST -H 'X-NSONE-Key: qACMD09OJXBxT7XOuRs8' -d '{"use_client_subnet":false}' https://api.nsone.net/v1/zones/example.com/example.com/A
    #>
    begin {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }
    process {
        foreach ($record in $records) { 
            $uri = "https://api.nsone.net/v1/zones/$($record.zone)/$($record.domain)/$($record.type)"
            try {
                $body = ConvertTo-JSON -Depth 4 $record
                $webresponse = invoke-webrequest -uri $uri -method Post -headers @{"X-NSONE-Key" = "$($nsoneConfig.apitoken)"} -body $body -ContentType "application/json"
                ConvertFrom-JSON $webresponse.Content
            } catch {
                Set-NSOneRESTErrorResponse
            }
        }
    }
    end {
    }
}

function Get-NSOneRecordAnswerMetaProperty {
    param(
        [Parameter(Mandatory=$true)][string]$zone,
        [Parameter(Mandatory=$true)][string]$domain,
        [Parameter(Mandatory=$true)][string]$type,
        [Parameter(Mandatory=$true)][string]$answer,
        [Parameter(Mandatory=$true)][string]$property
    )
    <#
    curl -X GET -H "X-NSONE-Key: $API_KEY" https://api.nsone.net/v1/zones/:zone/:domain/:type
    #>
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $uri = "https://api.nsone.net/v1/zones/$zone/$domain/$type"
    try {
        $webresponse = invoke-webrequest -uri $uri -method Get -headers @{"X-NSONE-Key" = "$($nsoneConfig.apitoken)"}
        $record = ConvertFrom-JSON $webresponse.Content
        ($record.answers | where {$_.answer -eq $answer}).meta.$property
    } catch {
        Set-NSOneRESTErrorResponse
    }
}

function Set-NSOneRecordAnswerMetaProperty {
    param(
        [Parameter(Mandatory=$true)][string]$zone,
        [Parameter(Mandatory=$true)][string]$domain,
        [Parameter(Mandatory=$true)][string]$type,
        [Parameter(Mandatory=$true)][string]$answer,
        [Parameter(Mandatory=$true)][string]$property,
        [Parameter(Mandatory=$true)][string]$value
    )
    <#
    curl -X GET -H "X-NSONE-Key: $API_KEY" https://api.nsone.net/v1/zones/:zone/:domain/:type
    #>
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $uri = "https://api.nsone.net/v1/zones/$zone/$domain/$type"
    try {
        $webresponse = invoke-webrequest -uri $uri -method Get -headers @{"X-NSONE-Key" = "$($nsoneConfig.apitoken)"}
        $record = ConvertFrom-JSON $webresponse.Content
        ($record.answers | where {$_.answer -eq $answer}).meta.$property = $value
        $record
    } catch {
        Set-NSOneRESTErrorResponse
    }
}

function Set-NSOneRESTErrorResponse {
    if ($_.Exception.Response) {
        $nsoneRESTErrorResponse.tenant = $nsoneConfig.tenant
        $nsoneRESTErrorResponse.apitoken = $nsoneConfig.apitoken
        $nsoneRESTErrorResponse.statusCode = $_.Exception.Response.StatusCode
        $nsoneRESTErrorResponse.statusDescription = $_.Exception.Response.StatusDescription
        $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $nsoneRESTErrorResponse.responseBody = $reader.ReadToEnd();
        $nsoneRESTErrorResponse.responseError = (ConvertFrom-JSON $nsoneRESTErrorResponse.responsebody).message
        $nsoneRESTErrorResponse
    } else {
        write-error $_
    }
    break
}

# get values for API access
$nsoneConfig = [ordered]@{
    registryUrl = "HKCU:\Software\NSOne\NSOne.PSHelper"
    apitoken = $null
}
New-Variable -Name nsoneconfig -Value $nsoneConfig -Scope script -Force
$nsoneRESTErrorResponse = [ordered]@{
    apiToken = $null
    statusCode = $null
    statusDescription = $null
    responseBody = $null
    responseError = $null
}
New-Variable -Name nsoneRESTErrorResponse -Value $nsoneRESTErrorResponse -Scope script -Force
$registryKey = (Get-ItemProperty -Path $nsoneConfig.registryURL -ErrorAction SilentlyContinue)
if ($registryKey -eq $null) {
    Write-Warning "Autoconnect failed.  API key not found in registry.  Use Connect-NSOne to connect manually."
} else {
    $nsoneConfig.apiToken = $registryKey.apitoken
    Write-host "Connected to NSOne`n"
}
Write-host "Cmdlets added:`n$(Get-Command | where {$_.ModuleName -eq 'NSOne.PSHelper'})`n"