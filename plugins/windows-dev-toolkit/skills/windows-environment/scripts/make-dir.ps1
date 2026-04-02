<#
.SYNOPSIS
    Create one or more directories safely.
.DESCRIPTION
    Creates directories with safety guards: blocks paths outside the working
    tree and protected directories (.git, .claude). Supports creating
    multiple directories in one call.
.PARAMETER Path
    One or more directory paths to create. Absolute or relative.
.EXAMPLE
    .claude\skills\windows-environment\scripts\make-dir.ps1 -Path "src\components"
.EXAMPLE
    .claude\skills\windows-environment\scripts\make-dir.ps1 -Path "src\models","src\services","src\utils"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Path,
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
if ($ExtraArgs) {
    Write-Host "  WARNING: Stray arguments ignored: $($ExtraArgs -join ', ')" -ForegroundColor Yellow
}

# --- Safety: resolve the workspace boundary ---
$WorkDir = (Get-Location).Path.TrimEnd('\')
$BlockedNames = @('.git', '.claude')

function Test-SafePath {
    param([string]$TargetPath)
    if ([string]::IsNullOrWhiteSpace($TargetPath)) { return "Path is empty or whitespace." }
    if ($TargetPath -match '\.\.') { return "Parent traversal (..) is forbidden." }
    try {
        $resolved = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($WorkDir, $TargetPath))
    } catch { return "Cannot resolve path: $TargetPath" }
    $resolvedNorm = $resolved.TrimEnd('\')
    if (-not $resolvedNorm.StartsWith($WorkDir + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
        return "Path is outside the working directory."
    }
    $leaf = Split-Path $resolvedNorm -Leaf
    if ($leaf -in $BlockedNames) { return "Cannot create protected directory: $leaf" }
    return $null
}

$created = @()
$skipped = @()

foreach ($p in $Path) {
    $reason = Test-SafePath $p
    if ($reason) {
        Write-Host "  BLOCKED: $p -- $reason" -ForegroundColor Red
        $skipped += $p
        continue
    }
    if (Test-Path $p -PathType Container) {
        Write-Host "  EXISTS:  $p" -ForegroundColor Gray
        $skipped += $p
        continue
    }
    New-Item -ItemType Directory -Path $p -Force | Out-Null
    Write-Host "  CREATED: $p" -ForegroundColor Green
    $created += $p
}

Write-Host ""
Write-Host "  Summary: $($created.Count) created, $($skipped.Count) skipped" -ForegroundColor Cyan

