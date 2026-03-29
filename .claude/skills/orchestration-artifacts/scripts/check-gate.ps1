<#
.SYNOPSIS
    Validate quality gate for a project phase.
.DESCRIPTION
    Checks that required artifacts exist and contain expected section headers
    for a given phase. Returns pass/fail with details on what's missing.
.PARAMETER ProjectName
    Project identifier (e.g. "user-auth").
.PARAMETER Phase
    Phase to validate: research, architecture, ui-design, planning,
    development, reviews, testing, or "all".
.PARAMETER IsMigration
    Include migration-specific checks.
.PARAMETER Root
    Repository root. Defaults to current directory.
.EXAMPLE
    .claude\skills\orchestration-artifacts\scripts\check-gate.ps1 -ProjectName "user-auth" -Phase "research"
.EXAMPLE
    .claude\skills\orchestration-artifacts\scripts\check-gate.ps1 -ProjectName "billing" -Phase "all" -IsMigration
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,
    [Parameter(Mandatory = $true)]
    [ValidateSet("all","research","architecture","ui-design","planning","development","reviews","testing")]
    [string]$Phase,
    [switch]$IsMigration,
    [string]$Root = (Get-Location).Path,
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
if ($ExtraArgs) {
    Write-Host "  WARNING: Stray arguments ignored: $($ExtraArgs -join ', ')" -ForegroundColor Yellow
}

$base = Join-Path $Root (Join-Path "orchestration" "artifacts")

function Test-FileWithSections {
    param([string]$FilePath, [string[]]$RequiredSections)
    $r = @{ Exists = $false; MissingSections = @() }
    if (-not (Test-Path $FilePath)) { return $r }
    $r.Exists = $true
    if ($RequiredSections.Count -eq 0) { return $r }
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $r }
    foreach ($s in $RequiredSections) {
        if ($content -notmatch "(?i)#.*$([regex]::Escape($s))") { $r.MissingSections += $s }
    }
    return $r
}

$gates = [ordered]@{
    "research"     = @{ "proposal.md"=@("Why","Goals","Scope"); "requirements.md"=@("Functional","Non-Functional"); "technical-constraints.md"=@(); "specs/scenarios.md"=@() }
    "architecture" = @{ "architecture.md"=@("Overview","Components","Data") }
    "ui-design"    = @{ "ui-spec.md"=@("Screen","Component"); "design-system.md"=@("Tokens"); "accessibility.md"=@("WCAG") }
    "planning"     = @{ "design.md"=@("Architecture","Component","Data"); "implementation-spec.md"=@(); "story-breakdown.md"=@() }
    "development"  = @{ "implementation-notes.md"=@("Build Status") }
    "reviews"      = @{ "code-review-report.md"=@("Overall Assessment") }
    "testing"      = @{ "test-results.md"=@("Overall Assessment","Acceptance Criteria") }
}

$migrationGates = @{
    "research"  = @{ "specs/spec-before.md"=@() }
    "ui-design" = @{ "migration-map.md"=@("Source","Target") }
    "planning"  = @{ "spec-after.md"=@("Target","AST") }
}

$phasesToCheck = if ($Phase -eq "all") { $gates.Keys } else { @($Phase) }
$allPassed = $true

Write-Host "`n  Quality Gate: $ProjectName" -ForegroundColor White
Write-Host "  $("=" * 40)" -ForegroundColor DarkGray

foreach ($p in $phasesToCheck) {
    $phaseDir = Join-Path $base (Join-Path $p $ProjectName)
    $checks = $gates[$p].Clone()
    if ($IsMigration -and $migrationGates.ContainsKey($p)) {
        foreach ($k in $migrationGates[$p].Keys) { $checks[$k] = $migrationGates[$p][$k] }
    }
    $passed = 0; $failed = 0; $details = @()
    foreach ($file in $checks.Keys) {
        $result = Test-FileWithSections -FilePath (Join-Path $phaseDir $file) -RequiredSections $checks[$file]
        if (-not $result.Exists) { $failed++; $details += "    [MISSING] $file" }
        elseif ($result.MissingSections.Count -gt 0) { $failed++; $details += "    [INCOMPLETE] $file - missing: $($result.MissingSections -join ', ')" }
        else { $passed++ }
    }
    $total = $passed + $failed
    $icon = if ($failed -eq 0) { [char]0x2705 } else { [char]0x274C }
    $color = if ($failed -eq 0) { "Green" } else { "Red" }
    Write-Host "`n  $p $icon ($passed/$total)" -ForegroundColor $color
    foreach ($d in $details) { Write-Host $d -ForegroundColor Yellow }
    if ($failed -gt 0) { $allPassed = $false }
}

Write-Host "`n  $("=" * 40)" -ForegroundColor DarkGray
if ($allPassed) {
    Write-Host "  RESULT: ALL GATES PASSED" -ForegroundColor Green
} else {
    Write-Host "  RESULT: GATE(S) FAILED" -ForegroundColor Red
    exit 1
}

