<#
.SYNOPSIS
    Injects a summarized version of orchestration state.

.DESCRIPTION
    Prevents full state file from bloating context window.
#>

$ErrorActionPreference = "Stop"

try {
    $statePath = ".claude/artifacts/$($state.projectName).json"

    if (-not (Test-Path $statePath)) {
        exit 0
    }

    $state = Get-Content $statePath | ConvertFrom-Json

    $summary = @{
        projectName     = $state.projectName
        currentPhase    = $state.currentPhase
        nextAction      = $state.nextAction
        openTasks       = ($state.tasks | Where-Object { $_.status -ne "complete" }).Count
        completedTasks  = ($state.tasks | Where-Object { $_.status -eq "complete" }).Count
    } | ConvertTo-Json -Depth 3

    $output = @{
        hookSpecificOutput = @{
            hookEventName     = "UserPromptSubmit"
            additionalContext = "# STATE SUMMARY`n$summary"
        }
    } | ConvertTo-Json -Depth 3

    Write-Output $output
    exit 0
}
catch {
    exit 0
}