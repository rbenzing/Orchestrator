<#
.SYNOPSIS
    Load orchestrator workflow state from disk.
.DESCRIPTION
    Reads the persisted orchestration state file for a project. Used to recover
    workflow position after context compaction. Outputs the full state file
    contents so the orchestrator can resume from where it left off.

    If called WITHOUT -ProjectName, discovers all projects with saved state
    and lists them so the orchestrator can pick the right one.
.PARAMETER ProjectName
    Project identifier (e.g. "user-auth"). Optional — omit to discover all projects.
.PARAMETER Root
    Repository root. Defaults to current directory.
.EXAMPLE
    .claude\skills\orchestration-state\scripts\load-state.ps1 -ProjectName "user-auth"
.EXAMPLE
    .claude\skills\orchestration-state\scripts\load-state.ps1
#>
[CmdletBinding()]
param(
    [string]$ProjectName,
    [string]$Root = (Get-Location).Path,
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
if ($ExtraArgs) {
    Write-Host "  WARNING: Stray arguments ignored: $($ExtraArgs -join ', ')" -ForegroundColor Yellow
}

# --- Discovery mode: no ProjectName given ---
$stateRoot = Join-Path $Root (Join-Path "orchestration" "state")
if (-not $ProjectName) {
    Write-Host ""
    if (-not (Test-Path $stateRoot)) {
        Write-Host "  No orchestration/state/ directory found. No projects have saved state." -ForegroundColor Yellow
        exit 1
    }
    $projects = Get-ChildItem -Path $stateRoot -Directory -ErrorAction SilentlyContinue
    $found = @()
    foreach ($dir in $projects) {
        $sf = Join-Path $dir.FullName "orchestrator-state.md"
        if (Test-Path $sf) {
            $lastWrite = (Get-Item $sf).LastWriteTime.ToString("yyyy-MM-dd HH:mm")
            $found += [PSCustomObject]@{ Name = $dir.Name; LastSaved = $lastWrite; Path = $sf }
        }
    }
    if ($found.Count -eq 0) {
        Write-Host "  No state files found in orchestration/state/." -ForegroundColor Yellow
        exit 1
    }
    Write-Host "  Discovered $($found.Count) project(s) with saved state:" -ForegroundColor Cyan
    Write-Host ""
    foreach ($p in $found) {
        Write-Host "    - $($p.Name)  (last saved: $($p.LastSaved))" -ForegroundColor Green
    }
    Write-Host ""
    if ($found.Count -eq 1) {
        # Auto-load the only project
        $ProjectName = $found[0].Name
        Write-Host "  Auto-loading only project: $ProjectName" -ForegroundColor Cyan
    } else {
        Write-Host "  Re-run with: load-state.ps1 -ProjectName ""<name>""" -ForegroundColor Yellow
        exit 1
    }
}

$stateFile = Join-Path $stateRoot (Join-Path $ProjectName "orchestrator-state.md")

if (-not (Test-Path $stateFile)) {
    Write-Host ""
    Write-Host "  WARNING: No state file found for project '$ProjectName'" -ForegroundColor Yellow
    Write-Host "  Expected: $stateFile" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  This means either:" -ForegroundColor Yellow
    Write-Host "    1. The project has not been initialized yet" -ForegroundColor Yellow
    Write-Host "    2. State was never saved (save-state.ps1 was not called)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  To initialize, run:" -ForegroundColor Cyan
    Write-Host "    .claude\skills\orchestration-state\scripts\save-state.ps1 -ProjectName ""$ProjectName"" -Phase ""research"" -ActiveAgent ""Orchestrator"" -NextAction ""Begin project orchestration""" -ForegroundColor Cyan

    # Check if artifacts exist to give more context
    $artifactBase = Join-Path $Root (Join-Path "orchestration" "artifacts")
    $phases = @("research","architecture","ui-design","planning","development","reviews","testing")
    $foundPhases = @()
    foreach ($phase in $phases) {
        $phaseDir = Join-Path $artifactBase (Join-Path $phase $ProjectName)
        if (Test-Path $phaseDir) {
            $fileCount = (Get-ChildItem -Path $phaseDir -File -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
            if ($fileCount -gt 0) { $foundPhases += "$phase ($fileCount files)" }
        }
    }
    if ($foundPhases.Count -gt 0) {
        Write-Host ""
        Write-Host "  Artifacts found for this project:" -ForegroundColor Green
        foreach ($p in $foundPhases) { Write-Host "    - $p" -ForegroundColor Green }
        Write-Host ""
        Write-Host "  State file is missing but artifacts exist. Recommend saving current state." -ForegroundColor Yellow
    }
    exit 1
}

Write-Host ""
Write-Host "  Loading state for: $ProjectName" -ForegroundColor Cyan
Write-Host "  File: $stateFile" -ForegroundColor DarkGray
Write-Host "  $("-" * 50)" -ForegroundColor DarkGray
Write-Host ""
Get-Content -Path $stateFile -Encoding UTF8 | Write-Host
Write-Host ""
Write-Host "  $("-" * 50)" -ForegroundColor DarkGray
Write-Host "  State loaded successfully. Resume workflow from the position above." -ForegroundColor Cyan

