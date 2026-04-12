<#
.SYNOPSIS
    Delete or reset the orchestrator state file for a project.
.DESCRIPTION
    Removes .claude/orchestrator/state/{ProjectName}/orchestrator-state.yml so the next
    orchestrator session starts clean. Use after a project is fully archived
    or when recovering from a corrupted state file.
    Pass -Reset to write a blank initial state instead of deleting.
.PARAMETER ProjectName
    Project identifier (e.g. "user-auth"). Required.
.PARAMETER Reset
    If set, write an empty initial state instead of deleting the file.
    Useful when you want load-state.ps1 to return a clean default rather
    than a "no state found" warning.
.EXAMPLE
    ${CLAUDE_PLUGIN_ROOT}\skills\orchestration-state\scripts\clear-state.ps1 -ProjectName "user-auth"
.EXAMPLE
    ${CLAUDE_PLUGIN_ROOT}\skills\orchestration-state\scripts\clear-state.ps1 -ProjectName "user-auth" -Reset
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectName,
    [switch]$Reset,
    [Parameter(ValueFromRemainingArguments)][object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) { Write-Output "ERROR: unknown params: $($ExtraArgs -join ' '). Valid: -ProjectName -Reset"; exit 1 }

$stateFile = Join-Path ".claude\orchestrator\state" (Join-Path $ProjectName "orchestrator-state.yml")

if (-not (Test-Path $stateFile)) { Write-Output "No state for $ProjectName"; exit 0 }

if ($Reset) {
    $blank = @"
project_name: $ProjectName
saved_at: "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
phase: research
agent: Orchestrator
active_contract_id: ""
router_phase: intake
next_action: "Fresh start -- no prior state."
story: ""
story_status: not-started
queue: []
completed: []
notes: "State reset by clear-state.ps1"
"@
    Set-Content -Path $stateFile -Value $blank -Encoding UTF8
    Write-Output "reset $ProjectName"
} else {
    Remove-Item -Path $stateFile -Force
    Write-Output "cleared $ProjectName"
}