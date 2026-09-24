#Requires -Version 5.1
<#
.SYNOPSIS
    Parser / AST smoke test for PowerShell scripts (no network, no Graph).
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$scripts = Get-ChildItem -Path (Join-Path $root 'scripts') -Filter '*.ps1'
$failed = 0

foreach ($s in $scripts) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($s.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors -and $errors.Count -gt 0) {
        Write-Host "FAIL $($s.Name): $($errors[0].Message)"
        $failed++
    }
    else {
        Write-Host "OK   $($s.Name)"
    }
}

# parse-alert against sample
$sample = Join-Path $root 'examples/sample-alert-p1.json'
& (Join-Path $root 'scripts/parse-alert.ps1') -Path $sample | Out-Null
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
    Write-Host "FAIL parse-alert.ps1 against sample-alert-p1.json"
    $failed++
}
else {
    Write-Host "OK   parse-alert.ps1 sample-alert-p1.json"
}

if ($failed -gt 0) {
    Write-Error "Smoke failed: $failed issue(s)"
    exit 1
}
Write-Host "Smoke-Syntax: all checks passed."
exit 0
