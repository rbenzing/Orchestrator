<#
.SYNOPSIS
    Safely remove files or directories within the working directory only.
.DESCRIPTION
    Hardened file/directory removal that BLOCKS any path outside the current
    working directory. Dry-run by default - requires -Force to actually delete.
    Rejects dangerous patterns like root paths, system directories, and
    parent-traversal attempts.
.PARAMETER Path
    File or directory path(s) to remove. Relative paths resolved from current
    directory. Accepts a single path or comma-separated array.
.PARAMETER Recurse
    Required when removing non-empty directories.
.PARAMETER Force
    Actually delete. Without this, only reports what would be removed.
.PARAMETER Quiet
    Suppress per-item output. Only show summary.
.EXAMPLE
    .augment\skills\dev-tools\scripts\remove-files.ps1 -Path "temp.log"
.EXAMPLE
    .augment\skills\dev-tools\scripts\remove-files.ps1 -Path "dist","coverage" -Recurse -Force
.EXAMPLE
    .augment\skills\dev-tools\scripts\remove-files.ps1 -Path "src\old-module" -Recurse
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Path,
    [switch]$Recurse,
    [switch]$Force,
    [switch]$Quiet,
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
if ($ExtraArgs) {
    Write-Host "  WARNING: Stray arguments ignored: $($ExtraArgs -join ', ')" -ForegroundColor Yellow
}

# --- Safety: resolve the workspace boundary ---
$WorkDir = (Get-Location).Path.TrimEnd('\')

# Blocked path patterns - never allow these regardless of context
$BlockedPatterns = @(
    '^\s*$',
    '^[A-Za-z]:\\$',
    '^[A-Za-z]:\\Windows',
    '^[A-Za-z]:\\Program Files',
    '^[A-Za-z]:\\Program Files \(x86\)',
    '^[A-Za-z]:\\Users\\[^\\]+$',
    '^[A-Za-z]:\\ProgramData',
    '\\\.git$',
    '\\\.augment$'
)

$BlockedNames = @('.git', '.augment', 'node_modules')

function Test-SafePath {
    param([string]$TargetPath)

    # Block empty
    if ([string]::IsNullOrWhiteSpace($TargetPath)) {
        return "Path is empty or whitespace."
    }

    # Block parent traversal in the raw input
    if ($TargetPath -match '\.\.') {
        return "Parent traversal (..) is forbidden."
    }

    # Resolve to absolute
    try {
        $resolved = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($WorkDir, $TargetPath))
    } catch {
        return "Cannot resolve path: $TargetPath"
    }

    # Must be strictly inside the working directory (not equal to it)
    $resolvedNorm = $resolved.TrimEnd('\')
    if ($resolvedNorm -eq $WorkDir) {
        return "Cannot remove the working directory itself."
    }
    if (-not $resolvedNorm.StartsWith($WorkDir + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
        return "Path is outside the working directory."
    }

    # Check blocked patterns
    foreach ($pat in $BlockedPatterns) {
        if ($resolvedNorm -match $pat) {
            return "Path matches a protected pattern."
        }
    }

    # Check blocked leaf names
    $leaf = Split-Path $resolvedNorm -Leaf
    if ($leaf -in $BlockedNames) {
        return "Cannot remove protected directory: $leaf"
    }

    return $null  # safe
}

# --- Process each path ---
$totalRemoved = 0
$totalSkipped = 0
$totalErrors = 0

foreach ($p in $Path) {
    $reason = Test-SafePath $p
    if ($reason) {
        Write-Host "  BLOCKED: $p -- $reason" -ForegroundColor Red
        $totalErrors++
        continue
    }

    $resolved = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($WorkDir, $p))

    if (-not (Test-Path $resolved)) {
        Write-Host "  NOT FOUND: $p" -ForegroundColor Yellow
        $totalSkipped++
        continue
    }

    $item = Get-Item $resolved
    $isDir = $item.PSIsContainer

    if ($isDir -and -not $Recurse) {
        $children = @(Get-ChildItem $resolved -ErrorAction SilentlyContinue)
        if ($children.Count -gt 0) {
            Write-Host "  BLOCKED: $p is a non-empty directory. Add -Recurse to confirm." -ForegroundColor Red
            $totalErrors++
            continue
        }
    }

    if ($isDir) {
        $count = @(Get-ChildItem $resolved -Recurse -File -ErrorAction SilentlyContinue).Count
        $label = "directory ($count files)"
    } else {
        $size = [math]::Round($item.Length / 1KB, 1)
        $label = "file (${size}KB)"
    }

    if (-not $Force) {
        if (-not $Quiet) { Write-Host "  WOULD REMOVE: $p -- $label" -ForegroundColor Yellow }
        $totalRemoved++
        continue
    }

    try {
        Remove-Item $resolved -Recurse:$Recurse -Force -ErrorAction Stop
        if (-not $Quiet) { Write-Host "  REMOVED: $p -- $label" -ForegroundColor Green }
        $totalRemoved++
    } catch {
        Write-Host "  ERROR: $p -- $($_.Exception.Message)" -ForegroundColor Red
        $totalErrors++
    }
}

# Summary
$mode = if ($Force) { "REMOVED" } else { "DRY RUN" }
Write-Host ""
Write-Host "  $mode -- $totalRemoved item(s) processed, $totalSkipped skipped, $totalErrors error(s)" -ForegroundColor Cyan
if (-not $Force -and $totalRemoved -gt 0) {
    Write-Host "  Add -Force to actually delete." -ForegroundColor Yellow
}

