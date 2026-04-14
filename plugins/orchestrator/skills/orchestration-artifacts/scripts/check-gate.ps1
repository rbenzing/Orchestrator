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
.PARAMETER Root
    Repository root. Defaults to current directory.
.EXAMPLE
    ${CLAUDE_PLUGIN_ROOT}\skills\orchestration-artifacts\scripts\check-gate.ps1 -ProjectName "user-auth" -Phase "research"
.EXAMPLE
    ${CLAUDE_PLUGIN_ROOT}\skills\orchestration-artifacts\scripts\check-gate.ps1 -ProjectName "user-auth" -ContractID "TSK-003"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,
    [ValidateSet("all","research","architecture","ui-design","planning","development","reviews","testing")]
    [string]$Phase = "",
    [string]$ContractID = "",
    [string]$Root = (Get-Location).Path,
    [string]$ContractBase = ".claude/orchestrator/contracts",
    [string]$ArtifactBase = ".claude/orchestrator/artifacts",
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) { Write-Output "ERROR: unknown params: $($ExtraArgs -join ' '). Valid: -ProjectName -Phase -ContractID -Root -ContractBase -ArtifactBase"; exit 1 }

# Resolve relative base paths against the target project root.
if (-not [System.IO.Path]::IsPathRooted($ContractBase)) {
    $ContractBase = Join-Path $Root $ContractBase
}
if (-not [System.IO.Path]::IsPathRooted($ArtifactBase)) {
    $ArtifactBase = Join-Path $Root $ArtifactBase
}

# Validate: at least one of Phase or ContractID must be provided
if (-not $Phase -and -not $ContractID) {
    Write-Output "ERROR: You must provide either -Phase or -ContractID (or both)."; exit 1
}

# ============================================================
# CONTRACT-BASED GATE -- reads criteria from YAML contract
# ============================================================
if ($ContractID) {
    $contractFile = Join-Path $ContractBase (Join-Path $ProjectName "$ContractID.yml")
    if (-not (Test-Path $contractFile)) {
        Write-Output "ERROR: Contract not found: $contractFile"; exit 1
    }

    $yaml = Get-Content $contractFile -Raw

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
        foreach ($d in $deliverables) {
            $filePath = ($d -split ':')[0].Trim()
            if (Test-Path $filePath) {
                Write-Output "OK $filePath"
            } else {
                Write-Output "MISSING $filePath"
                $contractFailures += "Deliverable missing: $filePath"
                $contractPassed = $false
            }
        }
    }

    if ($criteria.Count -gt 0) {
        foreach ($c in $criteria) { Write-Output "CRITERIA: $c" }
    }

    if ($contractPassed) {
        Write-Output "GATE PASSED $ContractID"
    } else {
        Write-Output "GATE FAILED $ContractID"
        $errorTrace = $contractFailures -join "; "
        $updateScript = "${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\update-contract.ps1"
        if (Test-Path $updateScript) {
            & $updateScript -ProjectName $ProjectName -ContractId $ContractID `
                -Status "Blocked" -ErrorTrace $errorTrace -BasePath $ContractBase
        }
        exit 1
    }

    if (-not $Phase) { exit 0 }
}

# Detect the project's primary language/runner from config files in $Root
function Get-ProjectRunnerHint {
    param([string]$SearchRoot)
    if (Test-Path (Join-Path $SearchRoot "pyproject.toml")) { return "python: ${CLAUDE_PLUGIN_ROOT}\skills\python-run\scripts\python-run.ps1 -Module pytest" }
    if (Test-Path (Join-Path $SearchRoot "setup.py"))       { return "python: ${CLAUDE_PLUGIN_ROOT}\skills\python-run\scripts\python-run.ps1 -Module pytest" }
    if (Test-Path (Join-Path $SearchRoot "Cargo.toml"))     { return "rust:   ${CLAUDE_PLUGIN_ROOT}\skills\cargo-run\scripts\cargo-run.ps1 -Command test" }
    if (Test-Path (Join-Path $SearchRoot "go.mod"))         { return "go:     ${CLAUDE_PLUGIN_ROOT}\skills\go-run\scripts\go-run.ps1 -Command test" }
    if (Test-Path (Join-Path $SearchRoot "Gemfile"))        { return "ruby:   bundle exec rspec" }
    if (Test-Path (Join-Path $SearchRoot "package.json"))   { return "node:   ${CLAUDE_PLUGIN_ROOT}\skills\node-test\scripts\run-tests.ps1 -ProjectPath ." }
    if (Get-ChildItem $SearchRoot -Filter "*.csproj" -Recurse -Depth 3 -ErrorAction SilentlyContinue) {
        return "dotnet: ${CLAUDE_PLUGIN_ROOT}\skills\dotnet-test\scripts\dotnet-test.ps1 -ProjectPath ."
    }
    return $null
}

# Phase -> agent mapping
$phaseToAgent = @{
    "research"     = "researcher"
    "architecture" = "architect"
    "ui-design"    = "ui-designer"
    "planning"     = "planner"
    "development"  = "developer"
    "reviews"      = "code-reviewer"
    "testing"      = "tester"
}

$validateScript = "${CLAUDE_PLUGIN_ROOT}\skills\orchestration-artifacts\scripts\validate-artifact.ps1"
$phasesToCheck = if ($Phase -eq "all") { @("research","architecture","ui-design","planning","development","reviews","testing") } else { @($Phase) }
$allPassed = $true

foreach ($p in $phasesToCheck) {
    $agentDir = $phaseToAgent[$p]
    $validationPassed = $true
    try {
        & $validateScript -ProjectName $ProjectName -Agent $agentDir -BasePath $ArtifactBase 2>$null
        if ($LASTEXITCODE -ne 0) { $validationPassed = $false }
    } catch {
        $validationPassed = $false
    }

    if ($validationPassed) {
        Write-Output "PHASE $p OK"
    } else {
        Write-Output "PHASE $p FAIL"
        $allPassed = $false
        if ($p -in @("development","testing")) {
            $hint = Get-ProjectRunnerHint -SearchRoot $Root
            if ($hint) { Write-Output "HINT: $hint" }
        }
    }
}

if ($allPassed) { Write-Output "ALL GATES PASSED" }
else { Write-Output "GATE(S) FAILED"; exit 1 }
