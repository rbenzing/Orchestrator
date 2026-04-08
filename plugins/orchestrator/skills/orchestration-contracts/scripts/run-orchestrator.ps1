<#
.SYNOPSIS
    Master orchestration loop -- scans Open contracts and dispatches the next agent.
.DESCRIPTION
    Scans .claude/orchestrator/contracts/{ProjectName}/ for Open contracts whose dependencies
    are all Closed. Outputs a prioritized dispatch queue so the Orchestrator knows
    exactly which agent to invoke next. After dispatch, updates state and runs
    cleanup-workspace.ps1 as a post-task hook.
.PARAMETER ProjectName
    Project identifier. Use "all" to scan across all projects.
.PARAMETER Dispatch
    If set, update state to mark the first ready contract as active (RouterPhase=waiting).
.PARAMETER PostTask
    If set, run cleanup-workspace.ps1 and archive closed contracts after an agent completes.
.PARAMETER CompletedContractID
    The contract ID just completed by an agent (used with -PostTask).
.EXAMPLE
    # Check what's ready to dispatch
    .claude\skills\orchestration-contracts\scripts\run-orchestrator.ps1 -ProjectName "user-auth"

.EXAMPLE
    # Dispatch the next ready contract (marks it active in state)
    .claude\skills\orchestration-contracts\scripts\run-orchestrator.ps1 -ProjectName "user-auth" -Dispatch

.EXAMPLE
    # Post-task hook: cleanup and archive after agent finishes TSK-003
    .claude\skills\orchestration-contracts\scripts\run-orchestrator.ps1 -ProjectName "user-auth" -PostTask -CompletedContractID "TSK-003"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectName,
    [switch]$Dispatch,
    [switch]$PostTask,
    [string]$CompletedContractID = ""
)
$ErrorActionPreference = "Stop"

$baseDir = ".claude\orchestrator\contracts"

# Resolve sibling script paths via plugin root (with PSScriptRoot fallback)
$pluginRoot = if ($env:CLAUDE_PLUGIN_ROOT) { $env:CLAUDE_PLUGIN_ROOT } else {
    (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
}
$saveStateScript  = Join-Path $pluginRoot "skills\orchestration-state\scripts\save-state.ps1"
$archiveScript    = Join-Path $pluginRoot "skills\orchestration-contracts\scripts\archive-contracts.ps1"

# -- Helper: read YAML field (simple regex, no external module needed) -------
function Get-YamlField {
    param([string]$Yaml, [string]$Field)
    $m = [regex]::Match($Yaml, "(?m)^$Field\s*:\s*[`"']?([^`"'\r\n]+)[`"']?")
    if ($m.Success) {
        $val = $m.Groups[1].Value.Trim()
        # Block scalar indicator — read the first non-empty indented line instead
        if ($val -eq '|' -or $val -eq '>') {
            $bm = [regex]::Match($Yaml, "(?m)^$Field\s*:\s*[|>][^\r\n]*\r?\n([ \t]+)([^\r\n]+)")
            if ($bm.Success) { return $bm.Groups[2].Value.Trim() }
            return ""
        }
        return $val
    }
    return ""
}

function Get-YamlList {
    param([string]$Yaml, [string]$Field)
    $items = @()
    $inSection = $false
    foreach ($line in ($Yaml -split "`n")) {
        if ($line -match "^$Field\s*:") { $inSection = $true; continue }
        if ($inSection) {
            if ($line -match '^\s+-\s+"?([^"]+)"?') { $items += $Matches[1].Trim() }
            elseif ($line -match '^\S' -and $line -notmatch '^\s*-') { $inSection = $false }
        }
    }
    return $items
}

# -- Collect projects to scan ------------------------------------------------
if ($ProjectName -eq "all") {
    $projects = Get-ChildItem $baseDir -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
} else { $projects = @($ProjectName) }

$readyContracts  = @()
$blockedContracts = @()
$waitingContracts = @()

foreach ($proj in $projects) {
    $projDir = Join-Path $baseDir $proj
    if (-not (Test-Path $projDir)) { continue }

    $allFiles = Get-ChildItem $projDir -Filter "*.yml" -ErrorAction SilentlyContinue
    $closedIds = @()

    # First pass: collect closed IDs for dependency resolution
    foreach ($f in $allFiles) {
        $yaml = Get-Content $f.FullName -Raw
        if ((Get-YamlField $yaml "status") -eq "Closed") { $closedIds += $f.BaseName }
    }

    # Second pass: find actionable contracts
    foreach ($f in $allFiles) {
        $yaml   = Get-Content $f.FullName -Raw
        $status = Get-YamlField $yaml "status"
        if ($status -ne "Open" -and $status -ne "Blocked") { continue }

        $deps        = Get-YamlList $yaml "dependencies"
        $depsAreMet  = ($deps.Count -eq 0) -or ($deps | Where-Object { $_ -notin $closedIds }).Count -eq 0
        $agent       = Get-YamlField $yaml "assigned_agent"
        $tier        = Get-YamlField $yaml "model_tier"
        $attempt     = Get-YamlField $yaml "attempt_count"
        $maxAttempts = Get-YamlField $yaml "max_attempts"
        $objective   = (Get-YamlField $yaml "objective") -replace '\|',''

        $draftEnabled = Get-YamlField $yaml "draft_enabled"
        $draftResult  = Get-YamlField $yaml "draft_result"

        $entry = [PSCustomObject]@{
            Project      = $proj
            ID           = $f.BaseName
            Agent        = $agent
            Tier         = $tier
            Status       = $status
            DepsAreMet   = $depsAreMet
            Attempt      = $attempt
            MaxAttempts  = $maxAttempts
            Objective    = $objective.Trim()
            File         = $f.FullName
            DraftEnabled = $draftEnabled
            DraftResult  = $draftResult
        }

        if ($depsAreMet -and $status -eq "Open") { $readyContracts  += $entry }
        elseif ($status -eq "Blocked")            { $blockedContracts += $entry }
        else                                      { $waitingContracts += $entry }
    }
}

# -- Display queue -----------------------------------------------------------
Write-Host ""
Write-Host "  +-- Orchestrator Dispatch Queue --------------------------------+" -ForegroundColor Cyan
Write-Host "  |  Project(s): $ProjectName" -ForegroundColor White

if ($readyContracts.Count -eq 0 -and $blockedContracts.Count -eq 0 -and $waitingContracts.Count -eq 0) {
    Write-Host "  |  No active contracts found." -ForegroundColor DarkGray
    Write-Host "  +---------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""; exit 0
}

Write-Host "  +-- READY TO DISPATCH ($($readyContracts.Count)) ----------------------------------------+" -ForegroundColor Green
foreach ($c in $readyContracts) {
    $draftTag = if ($c.DraftEnabled -eq "true") { "  [Draft+Verify]" } else { "" }
    Write-Host "  |  [$($c.ID)]  $($c.Agent)  [$($c.Tier)]  Attempt $($c.Attempt)/$($c.MaxAttempts)$draftTag" -ForegroundColor Green
    $goal = if ($c.Objective.Length -gt 0) { $c.Objective.Substring(0, [Math]::Min(70, $c.Objective.Length)) } else { '(no objective)' }
    Write-Host "  |     Goal: $goal" -ForegroundColor DarkGray
}

if ($waitingContracts.Count -gt 0) {
    Write-Host "  +-- WAITING ON DEPENDENCIES ($($waitingContracts.Count)) --------------------------------+" -ForegroundColor Yellow
    foreach ($c in $waitingContracts) {
        Write-Host "  |  [$($c.ID)]  $($c.Agent)  -- blocked by unresolved deps" -ForegroundColor Yellow
    }
}

if ($blockedContracts.Count -gt 0) {
    Write-Host "  +-- BLOCKED / RETRY ($($blockedContracts.Count)) -------------------------------------------+" -ForegroundColor Red
    foreach ($c in $blockedContracts) {
        Write-Host "  |  [$($c.ID)]  $($c.Agent)  Attempt $($c.Attempt)/$($c.MaxAttempts)" -ForegroundColor Red
    }
}

Write-Host "  +---------------------------------------------------------------+" -ForegroundColor Cyan

# -- Draft stats: scan all closed contracts for draft results ----------------
$allClosedFiles = @()
foreach ($proj in $projects) {
    $projDir = Join-Path $baseDir $proj
    $archiveDir = Join-Path $projDir "archive"
    foreach ($searchDir in @($projDir, $archiveDir)) {
        if (Test-Path $searchDir) {
            $allClosedFiles += Get-ChildItem $searchDir -Filter "*.yml" -Recurse -ErrorAction SilentlyContinue
        }
    }
}
$totalDrafted = 0; $draftPassed = 0; $draftFixed = 0
foreach ($f in $allClosedFiles) {
    $yaml = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $yaml) { continue }
    $dr = Get-YamlField $yaml "draft_result"
    if ($dr -eq "pass")  { $totalDrafted++; $draftPassed++ }
    if ($dr -eq "fix")   { $totalDrafted++; $draftFixed++ }
}
if ($totalDrafted -gt 0) {
    $passPct = [math]::Round(($draftPassed / $totalDrafted) * 100)
    Write-Host "  Draft Stats: $totalDrafted drafted | $draftPassed passed ($passPct%) | $draftFixed fixed" -ForegroundColor DarkGray
}
Write-Host ""

# -- Dispatch: mark first ready contract as active in state ------------------
if ($Dispatch -and $readyContracts.Count -gt 0) {
    $next = $readyContracts[0]
    Write-Host "  [DISPATCH] Activating: $($next.ID) -> $($next.Agent)" -ForegroundColor Green

    # Map agent handle to save-state agent name
    $agentMap = @{
        "@orchestrator"="Orchestrator"; "@researcher"="Researcher"; "@architect"="Architect"
        "@ui-designer"="UI Designer";   "@planner"="Planner";       "@developer"="Developer"
        "@code-reviewer"="Code Reviewer";"@tester"="Tester"
    }
    $agentName = $agentMap[$next.Agent]
    if (-not $agentName) { $agentName = "Orchestrator" }

    # Determine phase from agent
    $phaseMap = @{
        "Researcher"="research";"Architect"="architecture";"UI Designer"="ui-design"
        "Planner"="planning";"Developer"="development";"Code Reviewer"="reviews";"Tester"="testing"
        "Orchestrator"="planning"
    }
    $phase = $phaseMap[$agentName]
    if (-not $phase) { $phase = "development" }

    if (Test-Path $saveStateScript) {
        & $saveStateScript `
            -ProjectName      $next.Project `
            -Phase            $phase `
            -ActiveAgent      $agentName `
            -ActiveContractID $next.ID `
            -RouterPhase      "waiting" `
            -NextAction       "Waiting for $agentName to complete contract $($next.ID)" `
            -Mode             "cli"
    }

    Write-Host ""
    Write-Host "  Next step: Invoke $($next.Agent) and instruct them to read:" -ForegroundColor White
    Write-Host "    $($next.File)" -ForegroundColor Cyan
    Write-Host ""
    # Return contract ID for caller scripts
    Write-Output $next.ID
}

# -- Post-Task Hook: cleanup + archive after agent completes -----------------
if ($PostTask) {
    if ($CompletedContractID) {
        if (Test-Path $archiveScript) {
            $proj = if ($ProjectName -eq "all") { "all" } else { $ProjectName }
            & $archiveScript -ProjectName $proj
        }

        # Update state: router is back in intake/dispatch
        if (Test-Path $saveStateScript) {
            & $saveStateScript `
                -ProjectName      $ProjectName `
                -Phase            "development" `
                -ActiveAgent      "Orchestrator" `
                -ActiveContractID "" `
                -RouterPhase      "dispatch" `
                -NextAction       "Contract $CompletedContractID closed. Router scanning for next Open contract."
        }
    }
    Write-Host "  [POST-TASK] Complete." -ForegroundColor Green
    Write-Host ""
}

