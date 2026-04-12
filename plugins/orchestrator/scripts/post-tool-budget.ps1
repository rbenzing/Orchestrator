<#
.SYNOPSIS
    PostToolUse hook -- injects a token budget warning as additionalContext
    when session token usage passes 70% or 90% thresholds.
    Reads budget and usage from state file written by token-budget-guard.ps1.
    Only fires after view and codebase-retrieval tool calls.
#>
$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

$eventJson = $input | Out-String
if (-not $eventJson -or $eventJson.Trim().Length -eq 0) { exit 0 }

try {
    $hookData = $eventJson | ConvertFrom-Json
} catch { exit 0 }

# Only care about read tools
if ($hookData.tool_name -notin @("view", "codebase-retrieval")) { exit 0 }

# Budget state written by token-budget-guard.ps1
$sessionFile = ".claude\orchestrator\state\session-read-budget.json"
if (-not (Test-Path $sessionFile)) { exit 0 }

try {
    $budget = Get-Content $sessionFile -Raw | ConvertFrom-Json
} catch { exit 0 }

# Read cap from state (written by token-budget-guard.ps1) -- no hardcoded duplicate
$cap  = [int]$budget.token_budget
if ($cap -le 0) { exit 0 }
$used = [int]$budget.tokens_used
$pct  = [int](($used / $cap) * 100)

# Only warn at 70% and above
if ($pct -lt 70) { exit 0 }

$remaining = $cap - $used
$level     = if ($pct -ge 90) { "CRITICAL" } else { "WARNING" }

$advice = if ($pct -ge 90) {
    "Stop full-file reads immediately. Use extract-symbols.ps1 or summarize-artifact.ps1 for all remaining context needs."
} else {
    "Prefer view with view_range or search_query_regex. Avoid reading full files."
}

$context = "TOKEN BUDGET $level`: ~$used / $cap tokens used ($pct% -- ~$remaining remaining). $advice"

# PostToolUse hooks use top-level additionalContext per Claude Code hooks spec
@{
    additionalContext = $context
} | ConvertTo-Json -Depth 3 -Compress | Write-Output

exit 0