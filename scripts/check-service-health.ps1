#Requires -Version 5.1
<#
.SYNOPSIS
    HTTP or TCP health probe with clear exit codes.
.DESCRIPTION
    Portfolio demo for monitoring-style checks. Exit 0 = healthy, 1 = unhealthy, 2 = usage error.
.PARAMETER Uri
    HTTP/HTTPS URL to probe.
.PARAMETER ComputerName
    Hostname for TCP probe (requires -Port).
.PARAMETER Port
    TCP port.
.PARAMETER TimeoutSec
    Connect / request timeout seconds (default 5).
.PARAMETER ExpectCode
    Expected HTTP status (default 200).
.EXAMPLE
    .\check-service-health.ps1 -Uri 'https://example.com' -TimeoutSec 5
.EXAMPLE
    .\check-service-health.ps1 -ComputerName 'example.com' -Port 443
#>
[CmdletBinding(DefaultParameterSetName = 'Http')]
param(
    [Parameter(ParameterSetName = 'Http', Mandatory)]
    [string]$Uri,

    [Parameter(ParameterSetName = 'Tcp', Mandatory)]
    [string]$ComputerName,

    [Parameter(ParameterSetName = 'Tcp', Mandatory)]
    [ValidateRange(1, 65535)]
    [int]$Port,

    [ValidateRange(1, 120)]
    [int]$TimeoutSec = 5,

    [Parameter(ParameterSetName = 'Http')]
    [int]$ExpectCode = 200
)

$ErrorActionPreference = 'Stop'

function Exit-WithCode {
    param([int]$Code, [string]$Message)
    Write-Output $Message
    exit $Code
}

if ($PSCmdlet.ParameterSetName -eq 'Http') {
    try {
        $resp = Invoke-WebRequest -Uri $Uri -Method Get -TimeoutSec $TimeoutSec -UseBasicParsing -MaximumRedirection 5
        $code = [int]$resp.StatusCode
        if ($code -eq $ExpectCode) {
            Exit-WithCode -Code 0 -Message "HEALTHY url=$Uri http=$code expect=$ExpectCode timeout=${TimeoutSec}s"
        }
        Exit-WithCode -Code 1 -Message "UNHEALTHY url=$Uri http=$code expect=$ExpectCode"
    }
    catch {
        Exit-WithCode -Code 1 -Message "UNHEALTHY url=$Uri reason=$($_.Exception.Message)"
    }
}

# TCP
try {
    $client = New-Object System.Net.Sockets.TcpClient
    $iar = $client.BeginConnect($ComputerName, $Port, $null, $null)
    $ok = $iar.AsyncWaitHandle.WaitOne([TimeSpan]::FromSeconds($TimeoutSec), $false)
    if (-not $ok) {
        try { $client.Close() } catch { }
        Exit-WithCode -Code 1 -Message "UNHEALTHY host=$ComputerName port=$Port reason=timeout"
    }
    $client.EndConnect($iar) | Out-Null
    $client.Close()
    Exit-WithCode -Code 0 -Message "HEALTHY host=$ComputerName port=$Port timeout=${TimeoutSec}s"
}
catch {
    Exit-WithCode -Code 1 -Message "UNHEALTHY host=$ComputerName port=$Port reason=$($_.Exception.Message)"
}
