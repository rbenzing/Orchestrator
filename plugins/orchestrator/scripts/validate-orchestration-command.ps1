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
$ProgressPreference = "SilentlyContinue"

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
        # No input -- nothing to validate, allow
        exit 0
    }

    $eventData = $eventJson | ConvertFrom-Json

    # Only act on PreToolUse
    if ($eventData.hook_event_name -ne "PreToolUse") { exit 0 }

    $toolName = $eventData.tool_name

    # Rule 0: Deny built-in Grep/Glob -- use skill scripts which are git-aware and exclude
    # build artifacts (bin, obj, node_modules, dist, vendor, etc.) that .claudeignore misses
    if ($toolName -eq "Grep") {
        Deny-Hook "Use .\${CLAUDE_PLUGIN_ROOT}\skills\grep\scripts\grep.ps1 instead of the Grep tool. It excludes build artifacts and binary files automatically."
    }
    if ($toolName -eq "Glob") {
        Deny-Hook "Use .\${CLAUDE_PLUGIN_ROOT}\skills\find-files\scripts\find-files.ps1 instead of the Glob tool. It excludes build artifacts and non-source directories automatically."
    }

    # Rule 0b: Intercept Bash commands that have skill equivalents -- redirect to skills
    if ($toolName -eq "Bash") {
        $cmd = $eventData.tool_input.command
        if ($cmd) {
            # File search / listing
            if ($cmd -match '^(find |ls |dir )') {
                Deny-Hook "Use .\${CLAUDE_PLUGIN_ROOT}\skills\find-files\scripts\find-files.ps1 instead of Bash find/ls. It excludes build artifacts automatically."
            }
            # File content reads
            if ($cmd -match '^(cat |head |tail )') {
                Deny-Hook "Use the Read tool to read files, or .\${CLAUDE_PLUGIN_ROOT}\skills\summarize-artifact\scripts\summarize-artifact.ps1 for large files."
            }
            # Git operations with skill equivalents
            if ($cmd -match '^git (diff|log|show|stash)') {
                Deny-Hook "Use .\${CLAUDE_PLUGIN_ROOT}\skills\git-diff\scripts\git-diff.ps1 or .\${CLAUDE_PLUGIN_ROOT}\skills\git-summary\scripts\git-summary.ps1 instead of raw git commands."
            }
            if ($cmd -match '^git (status|branch)') {
                Deny-Hook "Use .\${CLAUDE_PLUGIN_ROOT}\skills\git-summary\scripts\git-summary.ps1 instead of raw git commands."
            }
            # Build/test operations
            if ($cmd -match '^(npm run build|npm build|ng build)') {
                Deny-Hook "Use .\${CLAUDE_PLUGIN_ROOT}\skills\node-build\scripts\node-build.ps1 instead of raw npm/ng build commands."
            }
            if ($cmd -match '^(npm (run )?test|ng test)') {
                Deny-Hook "Use .\${CLAUDE_PLUGIN_ROOT}\skills\node-test\scripts\node-test.ps1 instead of raw npm/ng test commands."
            }
            if ($cmd -match '^(npm run lint|ng lint)') {
                Deny-Hook "Use .\${CLAUDE_PLUGIN_ROOT}\skills\node-lint\scripts\node-lint.ps1 instead of raw npm/ng lint commands."
            }
            if ($cmd -match '^ng serve') {
                Deny-Hook "Use .\${CLAUDE_PLUGIN_ROOT}\skills\ng-serve\scripts\ng-serve.ps1 instead of raw ng serve."
            }
            if ($cmd -match '^dotnet (build|test|restore|format)') {
                $op = $Matches[1]
                Deny-Hook "Use .\${CLAUDE_PLUGIN_ROOT}\skills\dotnet-${op}\scripts\dotnet-${op}.ps1 instead of raw dotnet $op commands."
            }
            if ($cmd -match '^(python |pip )') {
                Deny-Hook "Use .\${CLAUDE_PLUGIN_ROOT}\skills\python-run\scripts\python-run.ps1 or .\${CLAUDE_PLUGIN_ROOT}\skills\pip-install\scripts\pip-install.ps1 instead of raw python/pip commands."
            }
        }
    }

    if ($toolName -ne "launch-process") { exit 0 }

    $command = $eventData.tool_input.command
    if (-not $command) { exit 0 }

    # Rule 1: Orchestration scripts must include a -ProjectName parameter
    # Exception: load-state.ps1 supports discovery mode without -ProjectName
    if ($command -match "\${CLAUDE_PLUGIN_ROOT}[/\\]skills[/\\]orchestration") {
        if ($command -notmatch 'load-state\.ps1' -and $command -notmatch '-ProjectName\s+') {
            Deny-Hook "Orchestration scripts require a -ProjectName parameter"
        }
    }

    # Rule 2: check-gate.ps1 must include a -Phase parameter
    if ($command -match "\${CLAUDE_PLUGIN_ROOT}[/\\]skills[/\\]check-gate\.ps1") {
        if ($command -notmatch '-Phase\s+') {
            Deny-Hook "check-gate.ps1 requires a -Phase parameter"
        }
    }

    # Rule 3: save-state.ps1 must include -Phase and -NextAction parameters
    if ($command -match "\${CLAUDE_PLUGIN_ROOT}[/\\]skills[/\\]save-state\.ps1") {
        if ($command -notmatch '-Phase\s+' -or $command -notmatch '-NextAction\s+') {
            Deny-Hook "save-state.ps1 requires -Phase and -NextAction parameters"
        }
    }

    # Rule 4: Prevent writing to .claude/agents/ (read-only agent definitions)
    if ($command -match "(New-Item|Set-Content|Out-File|Add-Content|Copy-Item|Move-Item).*\${CLAUDE_PLUGIN_ROOT}[/\\]agents") {
        Deny-Hook "Agent definitions in .claude/agents/ are read-only and must not be modified during execution"
    }

    # Rule 5: Prevent deleting orchestration state files outside of scripts
    if ($command -match '(Remove-Item|del |rm ).*orchestrator-state') {
        if ($command -notmatch 'orchestration-state[/\\]scripts[/\\]') {
            Deny-Hook "Orchestration state files must only be managed through state scripts"
        }
    }

    # Rule 6: Block reading or manipulating banned cache/vendor directories to prevent context bloat
    $blacklist = @('node_modules', '\.cache', '\.pytest_cache', '__pycache__', 'coverage[/\\]', 'dist[/\\]', 
    'build[/\\]', 'bin[/\\]', 'obj[/\\]', 'vendor[/\\]', 'packages[/\\]', 'site-packages[/\\]')
    foreach ($item in $blacklist) {
        if ($command -match $item) {
            Deny-Hook "Access to blocked directory/file ($item) is prohibited to prevent context bloat and token waste."
        }
    }

    # All checks passed -- allow
    exit 0
}
catch {
    # On unexpected errors, allow execution (fail-open) to avoid blocking the agent
    try { [Console]::Error.WriteLine("Hook validation error: $_") } catch { }
    exit 0
}
