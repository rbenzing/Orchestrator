<#
.SYNOPSIS
    Validate quality gate for a project phase or YAML contract.
.DESCRIPTION
    Checks that required artifacts exist and contain expected section headers
    for a given phase. When -ContractID is supplied, also reads acceptance
    criteria directly from the YAML contract and verifies each deliverable
    exists on disk. On failure, records the error trace so agents never lose
    retry context across compaction events.
.PARAMETER ProjectName
    Project identifier (e.g. "user-auth").
.PARAMETER Phase
    Phase to validate: research, architecture, ui-design, planning,
    development, reviews, testing, or "all". Optional when -ContractID is used.
.PARAMETER ContractID
    YAML contract ID to validate against (e.g. "TSK-003"). When supplied,
    acceptance criteria and deliverables are read from the contract file.
.PARAMETER IsMigration
    Include migration-specific checks.
.PARAMETER Root
    Repository root. Defaults to current directory.
.EXAMPLE
    .claude\skills\orchestration-artifacts\scripts\check-gate.ps1 -ProjectName "user-auth" -Phase "research"
.EXAMPLE
    .claude\skills\orchestration-artifacts\scripts\check-gate.ps1 -ProjectName "billing" -Phase "all" -IsMigration
.EXAMPLE
    .claude\skills\orchestration-artifacts\scripts\check-gate.ps1 -ProjectName "user-auth" -ContractID "TSK-003"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,
    [ValidateSet("all","research","architecture","ui-design","planning","development","reviews","testing")]
    [string]$Phase = "",
    [string]$ContractID = "",
    [switch]$IsMigration,
    [string]$Root = (Get-Location).Path,
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
if ($ExtraArgs) {
    Write-Host "  WARNING: Stray arguments ignored: $($ExtraArgs -join ', ')" -ForegroundColor Yellow
}

# Validate: at least one of Phase or ContractID must be provided
if (-not $Phase -and -not $ContractID) {
    Write-Error "You must provide either -Phase or -ContractID (or both)."
    exit 1
}

$base = Join-Path $Root ".claude\orchestrator\artifacts"

# ============================================================
# CONTRACT-BASED GATE — reads criteria from YAML contract
# ============================================================
if ($ContractID) {
    $contractFile = Join-Path ".claude\orchestrator\contracts" (Join-Path $ProjectName "$ContractID.yml")
    if (-not (Test-Path $contractFile)) {
        Write-Error "Contract not found: $contractFile"
        exit 1
    }

    $yaml = Get-Content $contractFile -Raw
    Write-Host ""
    Write-Host "  Contract Gate: $ContractID ($ProjectName)" -ForegroundColor White
    Write-Host "  $("=" * 40)" -ForegroundColor DarkGray

    # Parse acceptance_criteria block  (lines under "acceptance_criteria:" that start with "  - ")
    $criteriaSection = $false
    $criteria = @()
    foreach ($line in ($yaml -split "`n")) {
        if ($line -match '^acceptance_criteria:') { $criteriaSection = $true; continue }
        if ($criteriaSection) {
            if ($line -match '^\s*-\s+"?(.+?)"?\s*$') { $criteria += $Matches[1].Trim() }
            elseif ($line -match '^\S' -and $line -notmatch '^\s*-') { $criteriaSection = $false }
        }
    }

    # Parse deliverables block
    $deliverablesSection = $false
    $deliverables = @()
    foreach ($line in ($yaml -split "`n")) {
        if ($line -match '^deliverables:') { $deliverablesSection = $true; continue }
        if ($deliverablesSection) {
            if ($line -match '^\s*-\s+"?(.+?)"?\s*$') { $deliverables += $Matches[1].Trim() }
            elseif ($line -match '^\S' -and $line -notmatch '^\s*-') { $deliverablesSection = $false }
        }
    }

    $contractPassed = $true
    $contractFailures = @()

    # Check deliverable files exist
    if ($deliverables.Count -gt 0) {
        Write-Host "`n  Deliverables:" -ForegroundColor White
        foreach ($d in $deliverables) {
            # Strip symbol hints like "src/file.ts:symbolName"
            $filePath = ($d -split ':')[0].Trim()
            if (Test-Path $filePath) {
                Write-Host "    [OK]      $filePath" -ForegroundColor Green
            } else {
                Write-Host "    [MISSING] $filePath" -ForegroundColor Red
                $contractFailures += "Deliverable missing: $filePath"
                $contractPassed = $false
            }
        }
    }

    # Report acceptance criteria (informational — agent self-certifies)
    if ($criteria.Count -gt 0) {
        Write-Host "`n  Acceptance Criteria (self-certified by agent):" -ForegroundColor White
        foreach ($c in $criteria) {
            Write-Host "    [ ] $c" -ForegroundColor DarkYellow
        }
    }

    Write-Host "`n  $("=" * 40)" -ForegroundColor DarkGray
    if ($contractPassed) {
        Write-Host "  RESULT: CONTRACT GATE PASSED" -ForegroundColor Green
    } else {
        Write-Host "  RESULT: CONTRACT GATE FAILED" -ForegroundColor Red
        $errorTrace = $contractFailures -join "; "
        # Record failure in contract via update-contract.ps1
        $updateScript = ".claude\skills\orchestration-contracts\scripts\update-contract.ps1"
        if (Test-Path $updateScript) {
            & $updateScript -ProjectName $ProjectName -ContractId $ContractID `
                -Status "Blocked" -ErrorTrace $errorTrace
        }
        exit 1
    }

    # If no Phase was also requested, we are done
    if (-not $Phase) { exit 0 }
    Write-Host ""
}

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

# Phase → agent directory mapping (.claude/orchestrator/artifacts/{project}/{agent}/)
$phaseToAgent = @{
    "research"     = "researcher"
    "architecture" = "architect"
    "ui-design"    = "ui-designer"
    "planning"     = "planner"
    "development"  = "developer"
    "reviews"      = "code-reviewer"
    "testing"      = "tester"
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
    $agentDir = $phaseToAgent[$p]
    $phaseDir = Join-Path $base (Join-Path $ProjectName $agentDir)
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

