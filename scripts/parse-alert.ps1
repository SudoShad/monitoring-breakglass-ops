#Requires -Version 5.1
<#
.SYNOPSIS
    Parse a sample monitoring alert JSON into severity + recommended action.
.DESCRIPTION
    Reads alert JSON (Prometheus-ish webhook or generic helpdesk shape) and prints
    a triage summary. No network calls. See examples/ for sample payloads.
.PARAMETER Path
    Path to alert JSON file.
.EXAMPLE
    .\parse-alert.ps1 -Path .\examples\sample-alert-p1.json
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$Path
)

$ErrorActionPreference = 'Stop'
$raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
$alert = $raw | ConvertFrom-Json

function Get-Prop {
    param($Obj, [string[]]$Names, $Default = $null)
    foreach ($n in $Names) {
        if ($null -ne $Obj -and ($Obj.PSObject.Properties.Name -contains $n)) {
            $v = $Obj.$n
            if ($null -ne $v -and "$v" -ne '') { return $v }
        }
    }
    return $Default
}

# Support flat alerts and Prometheus-style { status, alerts: [ { labels, annotations } ] }
$target = $alert
if ($alert.PSObject.Properties.Name -contains 'alerts' -and $alert.alerts) {
    $target = $alert.alerts[0]
}

$labels = Get-Prop $target @('labels') $null
$annotations = Get-Prop $target @('annotations') $null

$severityRaw = Get-Prop $target @('severity', 'Severity', 'priority', 'Priority')
if (-not $severityRaw -and $labels) {
    $severityRaw = Get-Prop $labels @('severity', 'priority')
}
$name = Get-Prop $target @('alertname', 'AlertName', 'name', 'Name', 'title', 'Title') 'unnamed-alert'
if ($name -eq 'unnamed-alert' -and $labels) {
    $name = Get-Prop $labels @('alertname') 'unnamed-alert'
}
$summary = Get-Prop $target @('summary', 'Summary', 'description', 'Description', 'message', 'Message')
if (-not $summary -and $annotations) {
    $summary = Get-Prop $annotations @('summary', 'description') '(no summary)'
}
$instance = Get-Prop $target @('instance', 'Instance', 'host', 'Host', 'resource', 'Resource')
if (-not $instance -and $labels) {
    $instance = Get-Prop $labels @('instance', 'host') 'unknown'
}
$startsAt = Get-Prop $target @('startsAt', 'StartsAt', 'start', 'firedAt') '(not set)'

$sev = ("$severityRaw").ToUpperInvariant()
switch -Regex ($sev) {
    '^(P1|CRITICAL|CRIT|PAGE)$' { $normalized = 'P1'; $action = 'Ack immediately. Confirm blast radius. Join incident channel. Escalate early if no access. Consider break-glass only if standard rights cannot remediate.' }
    '^(P2|HIGH|MAJOR|WARNING|WARN)$' { $normalized = 'P2'; $action = 'Stabilize within the shift. Ticket + owner. Check recent changes. Escalate if customer impact grows.' }
    '^(P3|MEDIUM|LOW|INFO|MINOR)$' { $normalized = 'P3'; $action = 'Queue / schedule. Document workaround. Do not page overnight unless policy says otherwise.' }
    default {
        $normalized = 'UNKNOWN'
        $action = 'Severity missing or unrecognized — treat cautiously (assume P2 until classified). Add severity label to the alert rule.'
    }
}

$result = [ordered]@{
    SourceFile        = (Resolve-Path -LiteralPath $Path).Path
    AlertName         = "$name"
    SeverityRaw       = if ($severityRaw) { "$severityRaw" } else { '(missing)' }
    SeverityNormalized= $normalized
    Instance          = "$instance"
    StartsAt          = "$startsAt"
    Summary           = "$summary"
    RecommendedAction = $action
}

$result | ConvertTo-Json -Depth 5
Write-Host ""
Write-Host ("[{0}] {1} on {2}" -f $normalized, $name, $instance) -ForegroundColor $(
    switch ($normalized) { 'P1' { 'Red' } 'P2' { 'Yellow' } 'P3' { 'Cyan' } default { 'Gray' } }
)
Write-Host "Action: $action"
