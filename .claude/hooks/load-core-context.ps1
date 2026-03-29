<#
.SYNOPSIS
    Loads core orchestration context at session start.

.DESCRIPTION
    Injects only the orchestrator core + routing logic.
    Avoids loading phases to prevent context bloat.
#>

$ErrorActionPreference = "Stop"

try {
    $basePath = "$env:CLAUDE_PROJECT_DIR/.claude/orchestration/core"

    $orchestrator = Get-Content "$basePath/orchestrator.md" -Raw
    $routing      = Get-Content "$basePath/routing.md" -Raw
    $policy       = Get-Content "$basePath/context-policy.md" -Raw

    $context = @"
$orchestrator

$routing

$policy
"@

    $output = @{
        hookSpecificOutput = @{
            hookEventName    = "SessionStart"
            additionalContext = $context
        }
    } | ConvertTo-Json -Depth 3

    Write-Output $output
    exit 0
}
catch {
    # Fail-open
    exit 0
}