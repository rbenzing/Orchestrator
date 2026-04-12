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
    .claude\skills\cleanup-workspace\scripts\cleanup-workspace.ps1
.EXAMPLE
    .claude\skills\cleanup-workspace\scripts\cleanup-workspace.ps1 -DryRun
#>
[CmdletBinding()]
param(
    [string]$Root = (Get-Location).Path,
    [switch]$DryRun,
    [Parameter(ValueFromRemainingArguments)][object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) { Write-Host "ERROR: unknown params: $($ExtraArgs -join ' '). Valid: -Root -DryRun"; exit 1 }

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

# --- 1. Purge known cache directories ---
foreach ($rel in $purgeDirs) {
    $full = Join-Path $Root $rel
    if (Test-Path $full) {
        if ($DryRun) { Write-Host "DRY rm $rel" }
        else {
            Remove-Item $full -Recurse -Force -ErrorAction SilentlyContinue
            $totalRemoved++
        }
    }
}

# --- 2. Truncate oversized log files ---
$logDirs = @((Join-Path $Root "logs"), (Join-Path $Root ".claude\state"), (Join-Path $Root ".claude\artifacts"))
foreach ($logDir in $logDirs) {
    if (-not (Test-Path $logDir)) { continue }
    foreach ($pattern in $logPatterns) {
        Get-ChildItem $logDir -Filter $pattern -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.Length -gt $logMaxBytes) {
                if ($DryRun) { Write-Host "DRY truncate $($_.Name) ($([math]::Round($_.Length/1KB,1))KB)" }
                else {
                    $tail = Get-Content $_.FullName -Tail $logTailLines
                    $header = "# [Truncated -- last $logTailLines lines]"
                    Set-Content $_.FullName -Value (@($header) + $tail) -Encoding UTF8
                    $totalTruncated++
                }
            }
        }
    }
}

# --- 3. Purge temp/ subfolders inside artifact directories ---
$artifactsRoot = Join-Path $Root ".claude\artifacts"
if (Test-Path $artifactsRoot) {
    Get-ChildItem $artifactsRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $tempDir = Join-Path $_.FullName "temp"
        if (Test-Path $tempDir) {
            if ($DryRun) { Write-Host "DRY rm $($_.Name)\temp" }
            else {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
                $totalRemoved++
            }
        }
    }
}

Write-Host "cleanup: removed=$totalRemoved truncated=$totalTruncated$(if ($DryRun) { ' (dry-run)' })"
