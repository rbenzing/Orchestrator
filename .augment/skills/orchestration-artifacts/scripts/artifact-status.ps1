<#
.SYNOPSIS
    Show artifact completion dashboard for a project.
.DESCRIPTION
    Displays a compact overview of which phases have artifacts present,
    how many are found vs expected, and overall project progress.
.PARAMETER ProjectName
    Project identifier (e.g. "user-auth").
.PARAMETER Root
    Repository root. Defaults to current directory.
.EXAMPLE
    .augment\skills\orchestration-artifacts\scripts\artifact-status.ps1 -ProjectName "user-auth"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,
    [string]$Root = (Get-Location).Path,
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
if ($ExtraArgs) {
    Write-Host "  WARNING: Stray arguments ignored: $($ExtraArgs -join ', ')" -ForegroundColor Yellow
}

$base = Join-Path $Root (Join-Path "orchestration" "artifacts")

$phases = [ordered]@{
    "research"     = @("proposal.md","requirements.md","technical-constraints.md","specs/scenarios.md")
    "architecture" = @("architecture.md")
    "ui-design"    = @("ui-spec.md","design-system.md","accessibility.md")
    "planning"     = @("design.md","implementation-spec.md","story-breakdown.md")
    "development"  = @("implementation-notes.md","build-logs.txt")
    "reviews"      = @("code-review-report.md")
    "testing"      = @("test-results.md","test-coverage.md")
}

Write-Host "`n  Project: $ProjectName" -ForegroundColor White
Write-Host "  $("-" * 30)" -ForegroundColor DarkGray

$totalFound = 0; $totalExpected = 0

foreach ($phase in $phases.Keys) {
    $phaseDir = Join-Path $base (Join-Path $phase $ProjectName)
    $files = $phases[$phase]
    $total = $files.Count; $totalExpected += $total
    $found = 0
    foreach ($f in $files) { if (Test-Path (Join-Path $phaseDir $f)) { $found++ } }
    $totalFound += $found

    $pad = $phase.PadRight(15)
    if (-not (Test-Path $phaseDir)) {
        Write-Host "  ${pad}" -NoNewline; Write-Host "$([char]0x2014) not started" -ForegroundColor DarkGray
    } elseif ($found -eq $total) {
        Write-Host "  ${pad}" -NoNewline; Write-Host "$([char]0x2705) $found/$total" -ForegroundColor Green
    } elseif ($found -gt 0) {
        Write-Host "  ${pad}" -NoNewline; Write-Host "$([char]0x26A0) $found/$total" -ForegroundColor Yellow
    } else {
        Write-Host "  ${pad}" -NoNewline; Write-Host "$([char]0x274C) 0/$total" -ForegroundColor Red
    }
}

Write-Host "  $("-" * 30)" -ForegroundColor DarkGray
$pct = if ($totalExpected -gt 0) { [math]::Round(($totalFound / $totalExpected) * 100) } else { 0 }
Write-Host "  Overall: $totalFound/$totalExpected ($pct%)" -ForegroundColor White

