<#
.SYNOPSIS
    Provides feedback after tool execution.

.DESCRIPTION
    Adds lightweight context hints if execution issues detected.
#>

$ErrorActionPreference = "Stop"

try {
    $eventJson = $input | Out-String

    if (-not $eventJson) { exit 0 }

    $eventData = $eventJson | ConvertFrom-Json

    if ($eventData.hook_event_name -ne "PostToolUse") {
        exit 0
    }

    $toolName = $eventData.tool_name
    $outputText = $eventData.tool_output

    if (-not $outputText) { exit 0 }

    # Simple heuristic: detect failure patterns
    if ($outputText -match "error|failed|exception") {

        $output = @{
            hookSpecificOutput = @{
                hookEventName     = "PostToolUse"
                additionalContext = "Previous tool execution failed. Re-evaluate inputs and retry with corrected parameters. toolName: $toolName, error: $outputText"
            }
        } | ConvertTo-Json -Depth 3

        Write-Output $output
    }

    exit 0
}
catch {
    exit 0
}