#Requires -Version 5.1
<#
.SYNOPSIS
    Mock break-glass request ticket + dual-control approval checklist.
.DESCRIPTION
    Generates a fictional emergency-access ticket JSON and prints an approval
    checklist. Does NOT call Entra, AD, or any IdP. For interview / lab demos.
.PARAMETER Requester
    Who is asking for elevation (samAccount / alias).
.PARAMETER Approver
    Approver identity (must differ from requester for dual-control demo).
.PARAMETER Reason
    Business / incident justification.
.PARAMETER DurationMinutes
    Requested window (default 60).
.PARAMETER Role
    Requested role label (default 'Emergency-Helpdesk-Elevated').
.PARAMETER OutDir
    Directory for ticket JSON (default ./out).
.EXAMPLE
    .\breakglass-request.ps1 -Requester jdoe -Approver asmith -Reason 'P1 outage' -DurationMinutes 60
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Requester,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Reason,

    [ValidateRange(5, 480)]
    [int]$DurationMinutes = 60,

    [string]$Approver = 'pending-approver',

    [string]$Role = 'Emergency-Helpdesk-Elevated',

    [string]$OutDir = ''
)

$ErrorActionPreference = 'Stop'

if ($Requester -eq $Approver) {
    Write-Error "Dual-control demo: Approver must differ from Requester."
    exit 2
}

if (-not $OutDir) {
    $OutDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'out'
}
if (-not (Test-Path -LiteralPath $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir | Out-Null
}

$ticketId = 'BG-{0:yyyyMMdd}-{1}' -f (Get-Date), (Get-Random -Minimum 1000 -Maximum 9999)
$now = (Get-Date).ToString('o')
$end = (Get-Date).AddMinutes($DurationMinutes).ToString('o')

$ticket = [ordered]@{
    ticketId          = $ticketId
    type              = 'break-glass-request'
    status            = if ($Approver -eq 'pending-approver') { 'pending-approval' } else { 'approved-demo' }
    requester         = $Requester
    approver          = $Approver
    roleRequested     = $Role
    reason            = $Reason
    durationMinutes   = $DurationMinutes
    requestedAt       = $now
    plannedEndAt      = $end
    dualControl       = $true
    secretsInRepo     = $false
    revokeRequired    = $true
    checklist         = @(
        'Confirm severity and blast radius documented'
        'Confirm standard privileged path (PIM/JIT) is insufficient or unavailable'
        'Approver is a different person than requester'
        'Duration is minimized (prefer <= 60 minutes)'
        'Monitoring/audit alert acknowledged for emergency role activation'
        'Plan recorded for session revoke + group/PIM end at window close'
        'Post-incident note will link this ticket id'
    )
    notes             = 'EXAMPLE mock ticket only — no IdP calls were made.'
}

$outFile = Join-Path $OutDir "$ticketId.json"
($ticket | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $outFile -Encoding UTF8

Write-Host "Break-glass mock ticket: $ticketId"
Write-Host "Wrote: $outFile"
Write-Host ""
Write-Host "Approval checklist:"
foreach ($item in $ticket.checklist) {
    Write-Host "  [ ] $item"
}
Write-Host ""
Write-Host "After use: run revoke-session-stub.ps1 -WhatIf (or live revoke in a lab via helpdesk-graph-toolkit)."
Write-Output $outFile
