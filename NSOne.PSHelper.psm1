Add-Type -AssemblyName System.Security
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
    $nsoneConfig.apitoken = $null
}

function Get-NSOneZone {
    param(
        [Parameter(Mandatory=$true,Position=0)][string]$zone
    )
    <#
    curl -X GET -H "X-NSONE-Key: $API_KEY" https://api.nsone.net/v1/zones/{zone_name}
    #>
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $uri = "https://api.nsone.net/v1/zones/$zone"
    try {
        $webresponse = invoke-webrequest -uri $uri -method Get -headers @{"X-NSONE-Key" = "$($nsoneConfig.apitoken)"}
        ConvertFrom-JSON $webresponse.Content
    } catch {
        Set-NSOneRESTErrorResponse
    }
}

function Get-NSOneRecord {
    param(
        [Parameter(Mandatory=$true,Position=0)][string]$zone,
        [Parameter(Mandatory=$true,Position=1)][string]$domain,
        [Parameter(Mandatory=$true,Position=2)][string]$type
    )
    <#
    curl -X GET -H "X-NSONE-Key: $API_KEY" https://api.nsone.net/v1/zones/:zone/:domain/:type
    #>
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $uri = "https://api.nsone.net/v1/zones/$zone/$domain/$type"
    try {
        $webresponse = invoke-webrequest -uri $uri -method Get -headers @{"X-NSONE-Key" = "$($nsoneConfig.apitoken)"}
        ConvertFrom-JSON $webresponse.Content
    } catch {
        Set-NSOneRESTErrorResponse
    }
}

function Get-NSOneRecord {
    param(
        [Parameter(Mandatory=$true,Position=0)][string]$zone,
        [Parameter(Mandatory=$true,Position=1)][string]$domain,
        [Parameter(Mandatory=$true,Position=2)][string]$type
    )
    <#
    curl -X GET -H "X-NSONE-Key: $API_KEY" https://api.nsone.net/v1/zones/:zone/:domain/:type
    #>
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $uri = "https://api.nsone.net/v1/zones/$zone/$domain/$type"
    try {
        $webresponse = invoke-webrequest -uri $uri -method Get -headers @{"X-NSONE-Key" = "$($nsoneConfig.apitoken)"}
        ConvertFrom-JSON $webresponse.Content
    } catch {
        Set-NSOneRESTErrorResponse
    }
}

function Update-NSOneZone {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline)][PSObject[]]$records
    )
    <#
    curl -X POST -H "X-NSONE-Key: $API_KEY" -d '{ "expiry": 0, "hostmaster": "string", "nx_ttl": 0, "primary": { "enabled": true, "secondaries": [ { "ip": "string", "networks": [0],"notify": true, "port": 0 }]}, "refresh": 0, "retry": 0, "ttl": 0, "zone": "string", "local_tags": ["string"], "tags": {}}﻿'  https://api.nsone.net/v1/zones/<zone_name>
    #>
    begin {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }
    process {
        foreach ($record in $records) { 
            $uri = "https://api.nsone.net/v1/zones/$($record.zone)"
            #$uri = "https://minerva.sfatech.net/v1/zones/$($record.zone)"
            try {
                $zonedata = $record | Select-Object -Property expiry, hostmaster, nx_ttl, primary, local_tags, tags
                $body = ConvertTo-JSON -Depth 9 $zonedata
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
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline)][PSObject[]]$records,
        [Parameter(Mandatory=$true,Position=0)][string]$answer,
        [Parameter(Mandatory=$true,Position=1)][string]$property
    )
    begin {
    }
    process {
        foreach ($record in $records) {
            $value = ($record.answers | where {$_.answer -eq $answer}).meta.$property
            $resultObject = New-Object PSObject
            $resultObject | Add-Member Noteproperty Zone $record.zone
            $resultObject | Add-Member Noteproperty Domain $record.domain
            $resultObject | Add-Member Noteproperty Type $record.type
            $resultObject | Add-Member Noteproperty Answer $answer
            $resultObject | Add-Member Noteproperty Property $property
            $resultObject | Add-Member Noteproperty Value $value
            $resultObject
        }
    }
    end {
    }
}

function Set-NSOneRecordAnswerMetaProperty {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline)][PSObject[]]$records,
        [Parameter(Mandatory=$true,Position=0)][string]$answer,
        [Parameter(Mandatory=$true,Position=1)][string]$property,
        [Parameter(Mandatory=$true,Position=2)][string]$value
    )
    begin {
    }
    process {
        foreach ($record in $records) { 
            ($record.answers | where {$_.answer -eq $answer}).meta.$property = $value
            $record
        }
    }
    end {
    }
}

function Get-NSOneRecordAnswer {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline)][PSObject[]]$records,
        [Parameter(Mandatory=$false,Position=0,ParameterSetName="byIndex")][string]$index
    )
    begin {
    }
    process {
        foreach ($record in $records) {
            if ($index) {
                $resultObject = New-Object PSObject
                $resultObject | Add-Member Noteproperty Zone $record.zone
                $resultObject | Add-Member Noteproperty Domain $record.domain
                $resultObject | Add-Member Noteproperty Type $record.type
                $resultObject | Add-Member Noteproperty Answer $record.answers[$index]
                $resultObject
            } else {
                foreach ($answer in $record.answers) {
                    $resultObject = New-Object PSObject
                    $resultObject | Add-Member Noteproperty Zone $record.zone
                    $resultObject | Add-Member Noteproperty Domain $record.domain
                    $resultObject | Add-Member Noteproperty Type $record.type
                    $resultObject | Add-Member Noteproperty Answer $answer[0]
                    $resultObject
                }
            }
        }
    }
    end {
    }
}

function Set-NSOneRecordAnswer {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline)][PSObject[]]$records,
        [Parameter(Mandatory=$true,Position=0,ParameterSetName="byName")][string]$answer,
        [Parameter(Mandatory=$true,Position=0,ParameterSetName="byIndex")][string]$index,
        [Parameter(Mandatory=$true,Position=1)][string]$value
    )
    begin {
    }
    process {
        foreach ($record in $records) {
            if ($answer) {
                $answers = $record.answers | where {$_.answer -eq $answer}
                if ($answers.answer) {
                    ($record.answers | where {$_.answer -eq $answer}).answer = @($value) 
                    $record
                }
            } else {
                $answers = $record.answers[$index]
                if ($answers.answer) {
                    $record.answers[$index].answer = @($value) 
                    $record
                }
            }
        }
    }
    end {
    }
}

function Get-NSOneDynamicIP {
    param(
        [Parameter(Mandatory=$true,Position=0)][string]$uri,
        [Parameter(Mandatory=$false,Position=1)][string]$method = 'Get'
    )
    try {
        $response = (invoke-webrequest -uri $uri -method $method).Content
        ($response | Select-String -Pattern "\d{1,3}(\.\d{1,3}){3}" -AllMatches).Matches.Value
    } catch {
        Set-NSOneRESTErrorResponse
    }
}

function Set-NSOneRESTErrorResponse {
    if ($_.Exception.Response) {
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
Write-Warning "Use Connect-NSOne to set API key`n"
Write-host "Cmdlets added:`n$(Get-Command | where {$_.ModuleName -eq 'NSOne.PSHelper'})`n"