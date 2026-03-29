<#
.SYNOPSIS
    Persist orchestrator workflow state to disk.
.DESCRIPTION
    Saves the current orchestration state (phase, agent, story progress, etc.)
    to a structured markdown file. This enables recovery after context compaction.
    Called at every phase transition and story status change.
.PARAMETER ProjectName
    Project identifier (e.g. "user-auth").
.PARAMETER Phase
    Current workflow phase: research, architecture, ui-design, planning, test-authoring, development, reviews, testing, complete.
.PARAMETER ActiveAgent
    The agent currently executing (e.g. "Developer", "Tester").
.PARAMETER CurrentStory
    The story ID or name currently being worked on (e.g. "Story #1: User Login").
.PARAMETER StoryStatus
    Status of current story: not-started, in-progress, authoring-tests, validating, review, testing, complete, blocked.
.PARAMETER StoryQueue
    Comma-separated list of remaining stories (e.g. "Story #2,Story #3,Story #4").
.PARAMETER CompletedStories
    Comma-separated list of completed stories.
.PARAMETER NextAction
    Description of the next action the orchestrator should take.
.PARAMETER Notes
    Optional freeform notes about current state.
.PARAMETER Mode
    Execution mode: cli or roleplay. Default: roleplay.
.EXAMPLE
    .augment\skills\orchestration-state\scripts\save-state.ps1 -ProjectName "user-auth" -Phase "development" -ActiveAgent "Developer" -CurrentStory "Story #1: User Login" -StoryStatus "in-progress" -NextAction "Developer implementing acceptance criteria for Story #1"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,
    [Parameter(Mandatory = $true)]
    [ValidateSet("research","architecture","ui-design","planning","test-authoring","development","reviews","testing","complete")]
    [string]$Phase,
    [Parameter(Mandatory = $true)]
    [ValidateSet("Orchestrator","Researcher","Architect","UI Designer","Planner","Developer","Code Reviewer","Tester")]
    [string]$ActiveAgent,
    [string]$CurrentStory = "",
    [ValidateSet("not-started","in-progress","authoring-tests","validating","review","testing","complete","blocked")]
    [string]$StoryStatus = "not-started",
    [string[]]$StoryQueue = @(),
    [string[]]$CompletedStories = @(),
    [Parameter(Mandatory = $true)]
    [string]$NextAction,
    [string]$Notes = "",
    [ValidateSet("cli","roleplay")]
    [string]$Mode = "roleplay",
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
if ($ExtraArgs) {
    Write-Host "  WARNING: Stray arguments ignored: $($ExtraArgs -join ', ')" -ForegroundColor Yellow
}

$stateDir = Join-Path "orchestration" (Join-Path "state" $ProjectName)
if (-not (Test-Path $stateDir)) {
    New-Item -Path $stateDir -ItemType Directory -Force | Out-Null
    Write-Host "  [+] Created state directory: $stateDir" -ForegroundColor Green
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$stateFile = Join-Path $stateDir "orchestrator-state.md"

# Build story queue section
$queueLines = ""
if ($StoryQueue.Count -gt 0) {
    $i = 1
    foreach ($s in $StoryQueue) {
        $queueLines += "| $i | $($s.Trim()) | pending |`n"
        $i++
    }
} else {
    $queueLines = "| - | (none) | - |`n"
}

# Build completed stories section
$completedLines = ""
if ($CompletedStories.Count -gt 0) {
    $i = 1
    foreach ($s in $CompletedStories) {
        $completedLines += "- [x] $($s.Trim())`n"
        $i++
    }
} else {
    $completedLines = "- (none yet)`n"
}

$content = @"
# Orchestrator State — $ProjectName

> **AUTO-GENERATED** — Do not edit manually. Updated by save-state.ps1.
> Read this file FIRST after context compaction to restore workflow position.

## Last Updated
$timestamp

## Execution Mode
$Mode

## Current Position
| Field | Value |
|-------|-------|
| **Phase** | $Phase |
| **Active Agent** | $ActiveAgent |
| **Current Story** | $CurrentStory |
| **Story Status** | $StoryStatus |

## Next Action
> $NextAction

## Story Queue
| # | Story | Status |
|---|-------|--------|
$queueLines
## Completed Stories
$completedLines
## Notes
$Notes

## Artifact Locations
- Research: ``/orchestration/artifacts/research/$ProjectName/``
- Architecture: ``/orchestration/artifacts/architecture/$ProjectName/``
- UI Design: ``/orchestration/artifacts/ui-design/$ProjectName/``
- Planning: ``/orchestration/artifacts/planning/$ProjectName/``
- Development: ``/orchestration/artifacts/development/$ProjectName/``
- Reviews: ``/orchestration/artifacts/reviews/$ProjectName/``
- Testing: ``/orchestration/artifacts/testing/$ProjectName/``
"@

Set-Content -Path $stateFile -Value $content -Encoding UTF8
Write-Host ""
Write-Host "  State saved: $stateFile" -ForegroundColor Cyan
Write-Host "  Phase: $Phase | Agent: $ActiveAgent | Story: $CurrentStory ($StoryStatus)" -ForegroundColor White
Write-Host "  Next: $NextAction" -ForegroundColor DarkGray

