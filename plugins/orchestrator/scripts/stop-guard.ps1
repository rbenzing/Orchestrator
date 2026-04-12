<#
.SYNOPSIS
    Stop hook -- blocks agent end_turn when open contracts exist and state is unsaved.
    Never blocks user-interrupted stops or re-entrant stop checks.
    JSON output: top-level decision/reason per Claude Code hooks spec.
#>
$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

$eventJson = $input | Out-String
if (-not $eventJson -or $eventJson.Trim().Length -eq 0) { exit 0 }

try {
    $hookData = $eventJson | ConvertFrom-Json
} catch { exit 0 }

# Prevent infinite loop -- if this stop was triggered by a prior stop hook, allow it
if ($hookData.stop_hook_active -eq $true) { exit 0 }

# Never block user-initiated stops
if ($hookData.agent_stop_cause -eq "interrupted") { exit 0 }

# Scan all projects for open contracts
$openContracts = @()
$contractRoot  = ".claude\orchestrator\contracts"
if (Test-Path $contractRoot) {
    Get-ChildItem $contractRoot -Directory | ForEach-Object {
        Get-ChildItem $_.FullName -Filter "*.yml" | ForEach-Object {
            $yaml = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
            if ($yaml -match 'status:\s*[''"]?Open') {
                $m = [regex]::Match($yaml, "(?m)^id:\s*[`"']?([^`"'\r\n]+)")
                $openContracts += if ($m.Success) { $m.Groups[1].Value.Trim() } else { $_.Name }
            }
        }
    }
}

if ($openContracts.Count -eq 0) { exit 0 }

# Check if state was saved within the last 10 minutes
$recentlySaved = Get-ChildItem ".claude\orchestrator\state\*\orchestrator-state.yml" -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-10) }

if ($recentlySaved) { exit 0 }  # State current -- safe to stop

$list = ($openContracts | Select-Object -First 5) -join ", "
$more = if ($openContracts.Count -gt 5) { " (and $($openContracts.Count - 5) more)" } else { "" }

# Stop hooks use top-level decision/reason (not hookSpecificOutput)
@{
    decision = "block"
    reason   = "Open contracts detected: $list$more. Save state with save-state.ps1 before stopping, then close or hand off open contracts."
} | ConvertTo-Json -Depth 3 -Compress | Write-Output

exit 0