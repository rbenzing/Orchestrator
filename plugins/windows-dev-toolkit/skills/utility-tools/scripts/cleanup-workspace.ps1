<#
.SYNOPSIS
    Post-task hook: wipe temp caches and rotate large logs.
.DESCRIPTION
    Runs immediately after an agent closes a contract. Removes test caches,
    build artifacts, and truncates large log files so the next agent inherits
    a clean slate. This prevents context pollution and token bloat.
.PARAMETER Root
    Repository root. Defaults to current directory.
.PARAMETER DryRun
    List what would be removed without deleting anything.
.EXAMPLE
    .claude\skills\utility-tools\scripts\cleanup-workspace.ps1
.EXAMPLE
    .claude\skills\utility-tools\scripts\cleanup-workspace.ps1 -DryRun
#>
[CmdletBinding()]
param(
    [string]$Root = (Get-Location).Path,
    [switch]$DryRun
)
$ErrorActionPreference = "Stop"

# Directories to delete entirely
$purgeDirs = @(
    ".pytest_cache",
    "__pycache__",
    "coverage",
    ".nyc_output",
    "node_modules\.cache",
    ".angular\cache",
    "dist\test-results",
    ".next\cache"
)

# Log files larger than this (bytes) will be truncated to last 200 lines
$logMaxBytes   = 50 * 1024   # 50 KB
$logTailLines  = 200
$logPatterns   = @("*.log", "*.txt") # only in known log dirs

$totalRemoved = 0
$totalTruncated = 0

Write-Host ""
Write-Host "  [cleanup-workspace] Starting post-task cleanup..." -ForegroundColor Yellow

# --- 1. Purge known cache directories ---
foreach ($rel in $purgeDirs) {
    $full = Join-Path $Root $rel
    if (Test-Path $full) {
        if ($DryRun) {
            Write-Host "  [DRY] Would remove: $rel" -ForegroundColor DarkYellow
        } else {
            Remove-Item $full -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  [-] Removed: $rel" -ForegroundColor Green
            $totalRemoved++
        }
    }
}

# --- 2. Truncate oversized log files in known locations ---
$logDirs = @(
    (Join-Path $Root "logs"),
    (Join-Path $Root ".claude\orchestrator\state"),
    (Join-Path $Root ".claude\orchestrator\artifacts")
)

foreach ($logDir in $logDirs) {
    if (-not (Test-Path $logDir)) { continue }
    foreach ($pattern in $logPatterns) {
        Get-ChildItem $logDir -Filter $pattern -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.Length -gt $logMaxBytes) {
                if ($DryRun) {
                    Write-Host "  [DRY] Would truncate: $($_.FullName) ($([math]::Round($_.Length/1KB,1)) KB)" -ForegroundColor DarkYellow
                } else {
                    $tail = Get-Content $_.FullName -Tail $logTailLines
                    $header = "# [Truncated by cleanup-workspace.ps1 -- showing last $logTailLines lines]"
                    Set-Content $_.FullName -Value (@($header) + $tail) -Encoding UTF8
                    Write-Host "  [~] Truncated: $($_.Name) ($([math]::Round($_.Length/1KB,1)) KB -> tail $logTailLines)" -ForegroundColor Cyan
                    $totalTruncated++
                }
            }
        }
    }
}

Write-Host ""
if ($DryRun) {
    Write-Host "  [DRY RUN complete -- nothing was deleted]" -ForegroundColor DarkYellow
} else {
    Write-Host "  Cleanup complete. Removed: $totalRemoved dirs, Truncated: $totalTruncated logs." -ForegroundColor Green
}
Write-Host ""

