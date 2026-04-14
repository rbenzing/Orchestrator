<#
.SYNOPSIS
    PreToolUse hook for token budget tracking and context bloat prevention.
    Estimates tokens as chars / 5. Tracks cumulative token usage per session.
    Blocks when session budget or single-file limit exceeded.
    Detects redundant re-reads (same file, overlapping range, unchanged content)
    and warns via stderr -- never blocks, since re-reads may be legitimate.
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

function New-FreshBudget {
    return [pscustomobject]@{
        tokens_used              = 0
        token_budget             = $MAX_SESSION_TOKENS
        files_read               = @{}    # keyed by normalized abs path
        savings_tokens_estimated = 0
        started                  = [DateTime]::UtcNow.ToString("o")
    }
}

function ConvertTo-HashDict {
    # PSCustomObject (from ConvertFrom-Json) -> Hashtable, so we can mutate keys.
    param($Obj)
    $h = @{}
    if ($null -eq $Obj) { return $h }
    if ($Obj -is [hashtable]) { return $Obj }
    foreach ($p in $Obj.PSObject.Properties) {
        $h[$p.Name] = $p.Value
    }
    return $h
}

function Get-SessionBudget {
    if (-not (Test-Path $STATE_DIR)) {
        New-Item -ItemType Directory -Path $STATE_DIR -Force | Out-Null
    }
    if (-not (Test-Path $SESSION_FILE)) { return (New-FreshBudget) }
    try {
        $data = Get-Content $SESSION_FILE -Raw | ConvertFrom-Json
        $ts = [DateTime]::Parse($data.started, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)
        if (([DateTime]::UtcNow - $ts).TotalHours -gt 2) { return (New-FreshBudget) }

        # Migrate old schema: files_read used to be a flat array of paths.
        $filesRead = @{}
        if ($data.PSObject.Properties.Name -contains 'files_read' -and $null -ne $data.files_read) {
            if ($data.files_read -is [System.Array]) {
                foreach ($p in $data.files_read) {
                    if ($p -is [string]) {
                        $filesRead[$p.ToLowerInvariant()] = [pscustomobject]@{
                            path           = $p
                            content_hash   = ""
                            mtime          = ""
                            ranges         = @()
                            tokens_charged = 0
                            read_count     = 1
                            last_read      = $data.started
                        }
                    }
                }
            } else {
                $filesRead = ConvertTo-HashDict $data.files_read
            }
        }

        $savings = 0
        if ($data.PSObject.Properties.Name -contains 'savings_tokens_estimated') {
            $savings = [int]$data.savings_tokens_estimated
        }

        return [pscustomobject]@{
            tokens_used              = [int]$data.tokens_used
            token_budget             = [int]$data.token_budget
            files_read               = $filesRead
            savings_tokens_estimated = $savings
            started                  = $data.started
        }
    } catch { return (New-FreshBudget) }
}

function Save-SessionBudget {
    param($Budget)
    if (-not (Test-Path $STATE_DIR)) {
        New-Item -ItemType Directory -Path $STATE_DIR -Force | Out-Null
    }
    $Budget | ConvertTo-Json -Depth 5 -Compress | Set-Content $SESSION_FILE -Force -Encoding utf8
}

function Get-EstimatedTokenCount {
    param([int]$CharCount)
    return [Math]::Max(1, [int]($CharCount / $CHARS_PER_TOKEN))
}

function Get-FileFingerprint {
    # Cheap fingerprint: SHA256 of first 4KB + file length. Good enough to detect
    # edits without hashing full large files.
    param([string]$Path)
    try {
        $fi = Get-Item $Path -ErrorAction Stop
        $fs = [System.IO.File]::OpenRead($Path)
        try {
            $buf = New-Object byte[] 4096
            $read = $fs.Read($buf, 0, $buf.Length)
            if ($read -lt $buf.Length) {
                $trimmed = New-Object byte[] $read
                [Array]::Copy($buf, $trimmed, $read)
                $buf = $trimmed
            }
        } finally { $fs.Dispose() }
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try {
            $hash = [BitConverter]::ToString($sha.ComputeHash($buf)).Replace("-", "").Substring(0, 16)
        } finally { $sha.Dispose() }
        return [pscustomobject]@{
            hash  = "$hash-$($fi.Length)"
            mtime = $fi.LastWriteTimeUtc.ToString("o")
        }
    } catch {
        return [pscustomobject]@{ hash = ""; mtime = "" }
    }
}

function Test-RangeOverlap {
    # Return $true if [aStart,aEnd] overlaps any prior range in $ranges (array of [s,e] pairs).
    param($Ranges, [int]$AStart, [int]$AEnd)
    if (-not $Ranges) { return $false }
    foreach ($r in $Ranges) {
        if ($null -eq $r -or $r.Count -lt 2) { continue }
        $bs = [int]$r[0]; $be = [int]$r[1]
        if ($AStart -le $be -and $AEnd -ge $bs) { return $true }
    }
    return $false
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

            # Determine the range being requested (for re-read detection)
            $requestStart = 1
            $requestEnd   = 0
            $totalLines   = ($fileContent -split "`n").Count
            if ($toolInput.view_range) {
                $requestStart = [int]$toolInput.view_range[0]
                $requestEnd   = [int]$toolInput.view_range[1]
            } else {
                $requestEnd = $totalLines
            }

            # Estimate tokens for this specific read
            $readTokens = if ($toolInput.view_range) {
                $lines = $fileContent -split "`n"
                $s = [Math]::Max(0, $requestStart - 1)
                $e = [Math]::Min($lines.Count - 1, $requestEnd - 1)
                $rangeChars = ($lines[$s..$e] -join "`n").Length
                Get-EstimatedTokenCount $rangeChars
            } elseif ($toolInput.search_query_regex) {
                Get-EstimatedTokenCount ([int]($fileChars * 0.10))
            } else {
                $fileTokens
            }

            # Load session budget
            $budget = Get-SessionBudget
            $used = [int]$budget.tokens_used

            # Re-read detection -- key by normalized abs path
            $key = $fullPath.ToLowerInvariant()
            $fingerprint = Get-FileFingerprint $fullPath
            $prior = $null
            if ($budget.files_read -is [hashtable] -and $budget.files_read.ContainsKey($key)) {
                $prior = $budget.files_read[$key]
            }

            $isRedundantReRead = $false
            if ($null -ne $prior) {
                $priorHash = ""
                if ($prior.PSObject.Properties.Name -contains 'content_hash') { $priorHash = [string]$prior.content_hash }
                $sameContent = ($priorHash -eq $fingerprint.hash -and $priorHash -ne "")

                if ($sameContent) {
                    $priorRanges = @()
                    if ($prior.PSObject.Properties.Name -contains 'ranges' -and $prior.ranges) {
                        $priorRanges = @($prior.ranges)
                    }
                    $overlaps = Test-RangeOverlap $priorRanges $requestStart $requestEnd
                    if ($overlaps) { $isRedundantReRead = $true }
                }
                # If hash differs, the file was edited since -- cache is stale, clear prior ranges.
                if (-not $sameContent) {
                    $prior = $null
                }
            }

            if ($isRedundantReRead) {
                # Do not block -- emit a warning to stderr so the agent sees it.
                # Use [Console]::Error.WriteLine to bypass $ErrorActionPreference=Stop.
                # Update savings counter: the token cost of this read was preventable.
                $budget.savings_tokens_estimated = [int]$budget.savings_tokens_estimated + [int]$readTokens
                $priorRangeStr = ($prior.ranges | ForEach-Object { "$($_[0])-$($_[1])" }) -join ","
                [Console]::Error.WriteLine("RE-READ WARNING: '$targetPath' lines $requestStart-$requestEnd already read this session (prior: $priorRangeStr). Reference your earlier read instead of re-reading. Estimated savings if avoided: ~$readTokens tokens.")
            }

            # Check cumulative budget
            if (($used + $readTokens) -gt $MAX_SESSION_TOKENS) {
                Deny-Hook "Session token budget exceeded: ~$used tokens used, reading ~$readTokens more would exceed $MAX_SESSION_TOKENS limit. Use summarize-artifact.ps1 or extract-symbols.ps1."
            }

            # Update budget tracking
            $budget.tokens_used = $used + $readTokens

            # Ensure files_read is a hashtable
            if (-not ($budget.files_read -is [hashtable])) {
                $budget.files_read = ConvertTo-HashDict $budget.files_read
            }

            if ($null -eq $prior) {
                $budget.files_read[$key] = [pscustomobject]@{
                    path           = $targetPath
                    content_hash   = $fingerprint.hash
                    mtime          = $fingerprint.mtime
                    ranges         = @(,@($requestStart, $requestEnd))
                    tokens_charged = $readTokens
                    read_count     = 1
                    last_read      = [DateTime]::UtcNow.ToString("o")
                }
            } else {
                $existingRanges = @()
                if ($prior.PSObject.Properties.Name -contains 'ranges' -and $prior.ranges) {
                    $existingRanges = @($prior.ranges)
                }
                $existingRanges += ,@($requestStart, $requestEnd)
                $budget.files_read[$key] = [pscustomobject]@{
                    path           = $targetPath
                    content_hash   = $fingerprint.hash
                    mtime          = $fingerprint.mtime
                    ranges         = $existingRanges
                    tokens_charged = [int]$prior.tokens_charged + [int]$readTokens
                    read_count     = [int]$prior.read_count + 1
                    last_read      = [DateTime]::UtcNow.ToString("o")
                }
            }

            Save-SessionBudget $budget
        }
    }

    # All checks passed
    exit 0
}
catch {
    # Fail-open to avoid blocking the agent
    try { [Console]::Error.WriteLine("Token budget hook error: $_") } catch { }
    exit 0
}
