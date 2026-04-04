<#
.SYNOPSIS
    Claude PreToolUse hook for orchestration command validation.
    Validates that orchestration skill scripts are invoked with required parameters
    and conform to project safety constraints.

.DESCRIPTION
    This script is called by the Claude hooks system (PreToolUse event)
    before executing launch-process commands matching orchestration patterns.
    It reads JSON from stdin and returns:
      - Exit code 0 to allow execution
      - Exit code 0 with JSON on stdout containing permissionDecision "deny" to block execution
#>

$ErrorActionPreference = "Stop"

function Deny-Hook {
    param([string]$Reason)
    $output = @{
        hookSpecificOutput = @{
            hookEventName           = "PreToolUse"
            permissionDecision      = "deny"
            permissionDecisionReason = $Reason
        }
    } | ConvertTo-Json -Depth 3 -Compress
    Write-Output $output
    exit 0
}

try {
    # Read JSON event data from stdin (Claude hook contract)
    $eventJson = $input | Out-String
    if (-not $eventJson -or $eventJson.Trim().Length -eq 0) {
        # No input — nothing to validate, allow
        exit 0
    }

    $eventData = $eventJson | ConvertFrom-Json

    # Only act on PreToolUse for launch-process
    if ($eventData.hook_event_name -ne "PreToolUse") { exit 0 }
    if ($eventData.tool_name -ne "launch-process") { exit 0 }

    $command = $eventData.tool_input.command
    if (-not $command) { exit 0 }

    # Rule 1: Orchestration scripts must include a -ProjectName parameter
    # Matches both plugin invocations (${CLAUDE_PLUGIN_ROOT}\skills\orchestration-*) and legacy paths
    # Exception: load-state.ps1 supports discovery mode without -ProjectName
    if ($command -match '(?i)orchestration-[a-z]+[/\\]scripts[/\\]' -or
        $command -match '(?i)\.claude[/\\]skills[/\\]orchestration') {
        if ($command -notmatch 'load-state\.ps1' -and $command -notmatch '-ProjectName\s+') {
            Deny-Hook "Orchestration scripts require a -ProjectName parameter"
        }
    }

    # Rule 2: check-gate.ps1 must include a -Phase parameter
    if ($command -match 'check-gate\.ps1') {
        if ($command -notmatch '-Phase\s+') {
            Deny-Hook "check-gate.ps1 requires a -Phase parameter"
        }
    }

    # Rule 3: save-state.ps1 must include -Phase and -NextAction parameters
    if ($command -match 'save-state\.ps1') {
        if ($command -notmatch '-Phase\s+' -or $command -notmatch '-NextAction\s+') {
            Deny-Hook "save-state.ps1 requires -Phase and -NextAction parameters"
        }
    }

    # Rule 4: Prevent writing to .claude/agents/ (read-only agent definitions)
    if ($command -match '(New-Item|Set-Content|Out-File|Add-Content|Copy-Item|Move-Item).*\.claude[/\\]agents') {
        Deny-Hook "Agent definitions in .claude/agents/ are read-only and must not be modified during execution"
    }

    # Rule 5: Prevent deleting orchestration state files outside of scripts
    if ($command -match '(Remove-Item|del |rm ).*orchestrator-state') {
        if ($command -notmatch 'orchestration-state[/\\]scripts[/\\]') {
            Deny-Hook "Orchestration state files must only be managed through state scripts"
        }
    }

    # Rule 6: Block reading or manipulating banned cache/vendor directories to prevent context bloat
    $blacklist = @('node_modules', '\.cache', '\.pytest_cache', '__pycache__', 'coverage[/\\]')
    foreach ($item in $blacklist) {
        if ($command -match $item) {
            Deny-Hook "Access to blocked directory/file ($item) is prohibited to prevent context bloat and token waste."
        }
    }

    # All checks passed — allow
    exit 0
}
catch {
    # On unexpected errors, allow execution (fail-open) to avoid blocking the agent
    exit 0
}

