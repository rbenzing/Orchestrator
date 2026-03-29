<#
.SYNOPSIS
    Dynamically injects phase and gate context.

.DESCRIPTION
    Determines current phase from state and injects ONLY:
    - Active phase markdown
    - Corresponding gate file
#>

$ErrorActionPreference = "Stop"

try {
    $projectDir = $env:CLAUDE_PROJECT_DIR
    $statePath  = "$projectDir/.claude/artifacts/{project-name}.json"

    if (-not (Test-Path $statePath)) {
        exit 0
    }

    $state = Get-Content $statePath | ConvertFrom-Json
    $phase = $state.currentPhase

    if (-not $phase) {
        exit 0
    }

    $phaseFile = "$projectDir/.claude/orchestration/phases/$phase.md"
    $gateFile  = "$projectDir/.claude/orchestration/gates/$phase-gate.md"

    if (-not (Test-Path $phaseFile)) { exit 0 }

    $phaseContent = Get-Content $phaseFile -Raw
    $gateContent  = ""

    if (Test-Path $gateFile) {
        $gateContent = Get-Content $gateFile -Raw
    }

    $context = @"
# ACTIVE PHASE: $phase

$phaseContent

$gateContent
"@

    $output = @{
        hookSpecificOutput = @{
            hookEventName     = "UserPromptSubmit"
            additionalContext = $context
        }
    } | ConvertTo-Json -Depth 3

    Write-Output $output
    exit 0
}
catch {
    exit 0
}