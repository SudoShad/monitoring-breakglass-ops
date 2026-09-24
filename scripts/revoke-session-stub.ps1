#Requires -Version 5.1
<#
.SYNOPSIS
    Document / dry-run the Microsoft Graph sign-in session revoke pattern.
.DESCRIPTION
    Default behavior is dry-run: prints the Graph call that would revoke refresh
    tokens for a user. Does not connect to Graph unless -Execute is passed AND
    Microsoft Graph modules + app auth are available (lab only).
    Companion live script: helpdesk-graph-toolkit Revoke-UserSessions.ps1
.PARAMETER UserPrincipalName
    Target UPN (use fiction in demos, e.g. jdoe@contoso.example).
.PARAMETER Execute
    Opt-in to attempt a real revoke (requires Graph auth). Prefer lab tenants.
.EXAMPLE
    .\revoke-session-stub.ps1 -UserPrincipalName 'jdoe@contoso.example' -WhatIf
.EXAMPLE
    .\revoke-session-stub.ps1 -UserPrincipalName 'jdoe@contoso.example'
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$UserPrincipalName,

    [switch]$Execute
)

$ErrorActionPreference = 'Stop'

$graphUri = "https://graph.microsoft.com/v1.0/users/{upn-or-id}/revokeSignInSessions"
$cmdletHint = 'Revoke-MgUserSignInSession -UserId <id>'
$permissionHint = 'User.RevokeSessions.All (application) or appropriate delegated permission'

Write-Host "=== revoke-session-stub (monitoring-breakglass-ops) ==="
Write-Host "Target UPN : $UserPrincipalName"
Write-Host "Graph POST : $graphUri"
Write-Host "Cmdlet     : $cmdletHint"
Write-Host "Permission : $permissionHint"
Write-Host "Companion  : https://github.com/SudoShad/helpdesk-graph-toolkit (Revoke-UserSessions.ps1)"
Write-Host ""

if ($WhatIfPreference -or -not $Execute) {
    Write-Host "DRY-RUN: no Graph call made. Pass -Execute only in a lab tenant with proper auth."
    Write-Host "WhatIf detail: would POST revokeSignInSessions for '$UserPrincipalName'"
    return
}

if (-not $PSCmdlet.ShouldProcess($UserPrincipalName, 'Revoke sign-in sessions via Microsoft Graph')) {
    Write-Host 'Cancelled.'
    return
}

if (-not (Get-Module Microsoft.Graph.Authentication -ListAvailable)) {
    Write-Error "Microsoft.Graph.Authentication not installed. Stay on dry-run or install Graph SDK for a lab tenant."
    exit 1
}

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Import-Module Microsoft.Graph.Users.Actions -ErrorAction SilentlyContinue

# Expect an existing Graph connection from the operator (lab). Do not embed secrets.
try {
    $ctx = Get-MgContext -ErrorAction Stop
}
catch {
    Write-Error "No Graph context. Connect in a lab (see helpdesk-graph-toolkit docs/SETUP.md), then re-run with -Execute."
    exit 1
}

Write-Host "Connected tenant (lab check): $($ctx.TenantId)"
$user = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$([uri]::EscapeDataString($UserPrincipalName))?`$select=id,userPrincipalName,displayName"
Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/users/$($user.id)/revokeSignInSessions" | Out-Null
Write-Host "AUDIT: revoked sessions for $($user.userPrincipalName) ($($user.id))"
Write-Host "User must sign in again. Pair with password reset if compromise is suspected."
