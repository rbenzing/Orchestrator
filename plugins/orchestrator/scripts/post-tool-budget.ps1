<#
.SYNOPSIS
    PostToolUse hook -- injects a token budget warning as additionalContext
    when session token usage passes 70% or 90% thresholds, OR when a re-read
    is detected regardless of budget level.
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

$savings = 0
if ($budget.PSObject.Properties.Name -contains 'savings_tokens_estimated') {
    $savings = [int]$budget.savings_tokens_estimated
}

# Look up prior-read info for the file just read
$priorReadHint = $null
$targetPath = $hookData.tool_input.path
if ($targetPath) {
    $fullPath = $targetPath
    if (-not [System.IO.Path]::IsPathRooted($fullPath)) {
        $fullPath = Join-Path (Get-Location) $fullPath
    }
    $key = $fullPath.ToLowerInvariant()

    if ($budget.files_read -and $budget.files_read.PSObject.Properties.Name -contains $key) {
        $entry = $budget.files_read.$key
        $readCount = [int]$entry.read_count
        if ($readCount -ge 2) {
            $ranges = @()
            if ($entry.ranges) {
                $ranges = $entry.ranges | ForEach-Object {
                    if ($_ -and $_.Count -ge 2) { "$($_[0])-$($_[1])" }
                }
            }
            $rangeStr = ($ranges -join ", ")
            $tokensCharged = [int]$entry.tokens_charged
            $priorReadHint = "PRIOR READ: You have now read '$targetPath' $readCount times this session (ranges: $rangeStr, ~$tokensCharged tokens total). Reference your earlier read in-context instead of re-reading. For a different section use view_range with non-overlapping lines."
        }
    }
}

$budgetWarning = $null
if ($pct -ge 70) {
    $remaining = $cap - $used
    $level     = if ($pct -ge 90) { "CRITICAL" } else { "WARNING" }
    $advice = if ($pct -ge 90) {
        "Stop full-file reads immediately. Use extract-symbols.ps1 or summarize-artifact.ps1 for all remaining context needs."
    } else {
        "Prefer view with view_range or search_query_regex. Avoid reading full files."
    }
    $savingsNote = if ($savings -gt 0) { " (re-read detection saved ~$savings tokens so far)" } else { "" }
    $budgetWarning = "TOKEN BUDGET $level`: ~$used / $cap tokens used ($pct% -- ~$remaining remaining)$savingsNote. $advice"
}

# Nothing to report
if (-not $priorReadHint -and -not $budgetWarning) { exit 0 }

$parts = @()
if ($priorReadHint) { $parts += $priorReadHint }
if ($budgetWarning) { $parts += $budgetWarning }
$context = $parts -join "`n"

# PostToolUse hooks use top-level additionalContext per Claude Code hooks spec
@{
    additionalContext = $context
} | ConvertTo-Json -Depth 3 -Compress | Write-Output

exit 0
