<#
.SYNOPSIS
    Persist orchestrator workflow state to disk.
.PARAMETER ProjectName  Project identifier.
.PARAMETER Phase        research|architecture|ui-design|planning|test-authoring|development|reviews|testing|complete
.PARAMETER ActiveAgent  Agent currently executing.
.PARAMETER NextAction   Next action the orchestrator should take.
.PARAMETER ActiveContractID  Open contract ID (Contract-Router mode).
.PARAMETER RouterPhase  intake|dispatch|waiting|gate|complete
.PARAMETER CurrentStory Story being worked on.
.PARAMETER StoryStatus  not-started|in-progress|authoring-tests|validating|review|testing|complete|blocked
.PARAMETER StoryQueue   Remaining stories.
.PARAMETER CompletedStories Completed stories.
.PARAMETER Notes        Optional freeform notes.
.EXAMPLE
    save-state.ps1 -ProjectName "user-auth" -Phase "development" -ActiveAgent "Developer" -ActiveContractID "TSK-003" -RouterPhase "waiting" -NextAction "Waiting for Developer to close TSK-003"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectName,
    [Parameter(Mandatory)][ValidateSet("research","architecture","ui-design","planning","test-authoring","development","reviews","testing","complete")][string]$Phase,
    [Parameter(Mandatory)][ValidateSet("Orchestrator","Researcher","Architect","UI Designer","Planner","Developer","Code Reviewer","Tester")][string]$ActiveAgent,
    [Parameter(Mandatory)][string]$NextAction,
    [string]$ActiveContractID = "",
    [ValidateSet("","intake","dispatch","waiting","gate","complete")][string]$RouterPhase = "",
    [string]$CurrentStory = "",
    [ValidateSet("not-started","in-progress","authoring-tests","validating","review","testing","complete","blocked")][string]$StoryStatus = "not-started",
    [string[]]$StoryQueue = @(),
    [string[]]$CompletedStories = @(),
    [string]$Notes = "",
    [Parameter(ValueFromRemainingArguments)][object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
if ($ExtraArgs) { Write-Host "  WARNING: Stray arguments ignored: $($ExtraArgs -join ', ')" -ForegroundColor Yellow }

$stateDir = Join-Path ".claude\orchestrator\state" $ProjectName
if (-not (Test-Path $stateDir)) { New-Item -Path $stateDir -ItemType Directory -Force | Out-Null }

function Format-YamlList([string[]]$items) {
    if ($items.Count -eq 0) { return "[]" }
    return ("`n" + (($items | ForEach-Object { "  - `"$($_.Trim())`"" }) -join "`n"))
}

$stateFile = Join-Path $stateDir "orchestrator-state.yml"
$content = @"
project: $ProjectName
saved: "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
phase: $Phase
agent: $ActiveAgent
contract: $ActiveContractID
router_phase: $RouterPhase
next: "$NextAction"
story: "$CurrentStory"
story_status: $StoryStatus
queue: $(Format-YamlList $StoryQueue)
completed: $(Format-YamlList $CompletedStories)
notes: "$Notes"
"@

Set-Content -Path $stateFile -Value $content -Encoding UTF8
Write-Host "  State saved: $stateFile" -ForegroundColor Cyan
Write-Host "  $Phase | $ActiveAgent | $NextAction" -ForegroundColor DarkGray

