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
$stateRoot = Join-Path $Root ".claude\state"
if (-not $ProjectName) {
    Write-Host ""
    if (-not (Test-Path $stateRoot)) {
        Write-Host "  No .claude/state/ directory found. No projects have saved state." -ForegroundColor Yellow
        exit 1
    }
    $projects = Get-ChildItem -Path $stateRoot -Directory -ErrorAction SilentlyContinue
    $found = @()
    foreach ($dir in $projects) {
        $sf = Join-Path $dir.FullName "orchestrator-state.yml"
        if (Test-Path $sf) {
            $lastWrite = (Get-Item $sf).LastWriteTime.ToString("yyyy-MM-dd HH:mm")
            $found += [PSCustomObject]@{ Name = $dir.Name; LastSaved = $lastWrite; Path = $sf }
        }
    }
    if ($found.Count -eq 0) {
        Write-Host "  No state files found in .claude/state/." -ForegroundColor Yellow
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

$stateFile = Join-Path $stateRoot (Join-Path $ProjectName "orchestrator-state.yml")

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
    $artifactBase = Join-Path $Root ".claude\artifacts"
    $agents = @("researcher","architect","ui-designer","planner","developer","code-reviewer","tester")
    $foundPhases = @()
    foreach ($agent in $agents) {
        $agentDir = Join-Path $artifactBase (Join-Path $ProjectName $agent)
        if (Test-Path $agentDir) {
            $fileCount = (Get-ChildItem -Path $agentDir -File -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
            if ($fileCount -gt 0) { $foundPhases += "$agent ($fileCount files)" }
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

$stateContent = Get-Content -Path $stateFile -Encoding UTF8 -Raw
$stateContent -split "`n" | Write-Host

# --- Highlight Contract-Router fields ---
$cid = ([regex]::Match($stateContent, '(?m)^contract:[ \t]*"?([^"\r\n]+)"?')).Groups[1].Value.Trim()
$rp  = ([regex]::Match($stateContent, '(?m)^router_phase:[ \t]*"?([^"\r\n]+)"?')).Groups[1].Value.Trim()

if ($cid -or $rp) {
    Write-Host "  --- Contract-Router State ---" -ForegroundColor Cyan
    if ($cid) {
        Write-Host "  Active Contract : $cid" -ForegroundColor Yellow
        $contractFile = ".claude\contracts\$ProjectName\$cid.yml"
        $exists = Test-Path $contractFile
        Write-Host "  Contract file   : $contractFile  $(if ($exists) { '[EXISTS]' } else { '[NOT FOUND]' })" -ForegroundColor $(if ($exists) { 'Green' } else { 'Red' })
    }
    if ($rp) { Write-Host "  Router Phase    : $rp" -ForegroundColor White }
}

Write-Host ""
Write-Host "  $("-" * 50)" -ForegroundColor DarkGray
Write-Host "  State loaded successfully. Resume workflow from the position above." -ForegroundColor Cyan

