<#
.SYNOPSIS
    PreToolUse hook for token budget tracking and context bloat prevention.
    Estimates tokens as chars / 5. Tracks cumulative token usage per session.
    Blocks when session budget or single-file limit exceeded.
#>

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Config -- all limits in estimated tokens (chars / 5)
$CHARS_PER_TOKEN     = 5
$MAX_SESSION_TOKENS  = 60000    # session budget
$MAX_SINGLE_TOKENS   = 10000   # block individual files over this (~50K chars)
$STATE_DIR = Join-Path (Join-Path $PSScriptRoot "..") "state"
$SESSION_FILE = Join-Path $STATE_DIR "session-read-budget.json"

# Banned path patterns -- reading these wastes tokens
$BANNED_PATTERNS = @(
    'node_modules[/\\]',
    '\.cache[/\\]',
    '\.pytest_cache[/\\]',
    '__pycache__[/\\]',
    'coverage[/\\]',
    'dist[/\\](?!.*\.ts)',
    '\.next[/\\]',
    '\.nuxt[/\\]',
    'vendor[/\\]',
    '\.git[/\\](?!config|HEAD)',
    'package-lock\.json$',
    'yarn\.lock$',
    'pnpm-lock\.yaml$',
    '\.min\.js$',
    '\.min\.css$',
    '\.map$',
    '\.chunk\.',
    'bundle\.js'
)

# Large generated files -- block outright
$LARGE_FILE_PATTERNS = @(
    '\.generated\.',
    '\.designer\.',
    '\.g\.cs$',
    'swagger\.json$',
    'openapi\.json$'
)

function Deny-Hook {
    param([string]$Reason)
    @{
        hookSpecificOutput = @{
            hookEventName           = "PreToolUse"
            permissionDecision      = "deny"
            permissionDecisionReason = $Reason
        }
    } | ConvertTo-Json -Depth 3 -Compress | Write-Output
    exit 0
}

function Get-SessionBudget {
    if (-not (Test-Path $STATE_DIR)) {
        New-Item -ItemType Directory -Path $STATE_DIR -Force | Out-Null
    }
    $fresh = @{
        tokens_used  = 0
        token_budget = $MAX_SESSION_TOKENS
        files_read   = @()
        started      = [DateTime]::UtcNow.ToString("o")
    }
    if (Test-Path $SESSION_FILE) {
        try {
            $data = Get-Content $SESSION_FILE -Raw | ConvertFrom-Json
            # RoundtripKind preserves the Z (UTC) suffix so the comparison is correct
            $ts = [DateTime]::Parse($data.started, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)
            if (([DateTime]::UtcNow - $ts).TotalHours -gt 2) { return $fresh }
            return $data
        } catch { return $fresh }
    }
    return $fresh
}

function Save-SessionBudget {
    param($Budget)
    if (-not (Test-Path $STATE_DIR)) {
        New-Item -ItemType Directory -Path $STATE_DIR -Force | Out-Null
    }
    $Budget | ConvertTo-Json -Depth 3 -Compress | Set-Content $SESSION_FILE -Force -Encoding utf8
}

function Get-EstimatedTokenCount {
    param([int]$CharCount)
    return [Math]::Max(1, [int]($CharCount / $CHARS_PER_TOKEN))
}

try {
    $eventJson = $input | Out-String
    if (-not $eventJson -or $eventJson.Trim().Length -eq 0) { exit 0 }
    $eventData = $eventJson | ConvertFrom-Json
    if ($eventData.hook_event_name -ne "PreToolUse") { exit 0 }

    $toolName = $eventData.tool_name
    $toolInput = $eventData.tool_input

    # Extract the path being accessed
    $targetPath = $null
    switch ($toolName) {
        "view" { $targetPath = $toolInput.path }
        "codebase-retrieval" { $targetPath = $toolInput.information_request }
        "launch-process" { $targetPath = $toolInput.command }
    }

    if (-not $targetPath) { exit 0 }

    # Check banned patterns
    foreach ($pattern in $BANNED_PATTERNS) {
        if ($targetPath -match $pattern) {
            Deny-Hook "Blocked: reading '$targetPath' matches banned pattern ($pattern). Use targeted scripts or codebase-retrieval instead."
        }
    }

    # For view tool -- check file size and budget using token estimation
    if ($toolName -eq "view" -and $targetPath) {
        $fullPath = $targetPath
        if (-not [System.IO.Path]::IsPathRooted($fullPath)) {
            $fullPath = Join-Path (Get-Location) $fullPath
        }

        if (Test-Path $fullPath -PathType Leaf) {
            $fileContent = [System.IO.File]::ReadAllText($fullPath)
            $fileChars   = $fileContent.Length
            $fileTokens  = Get-EstimatedTokenCount $fileChars

            # Block oversized single files
            if ($fileTokens -gt $MAX_SINGLE_TOKENS) {
                foreach ($pattern in $LARGE_FILE_PATTERNS) {
                    if ($targetPath -match $pattern) {
                        Deny-Hook "Blocked: '$targetPath' is a generated file (~$fileTokens tokens). Use extract-symbols.ps1 or summarize-artifact.ps1 instead."
                    }
                }
                if (-not $toolInput.view_range -and -not $toolInput.search_query_regex) {
                    Deny-Hook "Blocked: '$targetPath' is ~$fileTokens tokens (max $MAX_SINGLE_TOKENS). Use view_range or search_query_regex to read a specific section."
                }
            }

            # Estimate tokens for this specific read
            $readTokens = if ($toolInput.view_range) {
                # Explicit range -- count chars in the requested lines
                $lines = $fileContent -split "`n"
                $start = [Math]::Max(0, $toolInput.view_range[0] - 1)
                $end   = [Math]::Min($lines.Count - 1, $toolInput.view_range[1] - 1)
                $rangeChars = ($lines[$start..$end] -join "`n").Length
                Get-EstimatedTokenCount $rangeChars
            } elseif ($toolInput.search_query_regex) {
                # Regex search returns matches + context -- estimate 10% of file
                Get-EstimatedTokenCount ([int]($fileChars * 0.10))
            } else {
                $fileTokens
            }

            # Check cumulative budget
            $budget = Get-SessionBudget
            $used = [int]$budget.tokens_used
            if (($used + $readTokens) -gt $MAX_SESSION_TOKENS) {
                Deny-Hook "Session token budget exceeded: ~$used tokens used, reading ~$readTokens more would exceed $MAX_SESSION_TOKENS limit. Use summarize-artifact.ps1 or extract-symbols.ps1."
            }

            # Update budget tracking
            $budget.tokens_used = $used + $readTokens
            if ($budget.files_read -is [System.Array]) {
                $budget.files_read += $targetPath
            } else {
                $budget.files_read = @($targetPath)
            }
            Save-SessionBudget $budget
        }
    }

    # All checks passed
    exit 0
}
catch {
    # Fail-open to avoid blocking the agent
    Write-Error "Token budget hook error: $_" 2>&1 | Out-Null
    exit 0
}