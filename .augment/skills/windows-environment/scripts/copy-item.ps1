<#
.SYNOPSIS
    Copy files or directories safely.
.DESCRIPTION
    Copies a source file or directory to a destination with safety guards:
    blocks writes to protected directories (.git, .augment).
.PARAMETER Source
    Source file or directory path.
.PARAMETER Destination
    Destination path.
.PARAMETER Recurse
    Copy directories recursively.
.PARAMETER Force
    Overwrite existing files.
.EXAMPLE
    .augment\skills\windows-environment\scripts\copy-item.ps1 -Source "template.json" -Destination "config.json"
.EXAMPLE
    .augment\skills\windows-environment\scripts\copy-item.ps1 -Source "templates\base" -Destination "src\new-module" -Recurse
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Source,
    [Parameter(Mandatory = $true)]
    [string]$Destination,
    [switch]$Recurse,
    [switch]$Force,
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
if ($ExtraArgs) {
    Write-Host "  WARNING: Stray arguments ignored: $($ExtraArgs -join ', ')" -ForegroundColor Yellow
}

# --- Safety: resolve the workspace boundary ---
$WorkDir = (Get-Location).Path.TrimEnd('\')
$BlockedNames = @('.git', '.augment')

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
    if ($leaf -in $BlockedNames) { return "Cannot target protected directory: $leaf" }
    return $null
}

# Validate both source and destination
$srcReason = Test-SafePath $Source
if ($srcReason) { Write-Error "BLOCKED source: $srcReason"; exit 1 }
$dstReason = Test-SafePath $Destination
if ($dstReason) { Write-Error "BLOCKED destination: $dstReason"; exit 1 }

if (-not (Test-Path $Source)) {
    Write-Error "Source not found: $Source"; exit 1
}

$copyArgs = @{ Path = $Source; Destination = $Destination }
if ($Recurse) { $copyArgs.Recurse = $true }
if ($Force) { $copyArgs.Force = $true }

Copy-Item @copyArgs
Write-Host ""
Write-Host "  COPIED: $Source -> $Destination" -ForegroundColor Green
if ($Recurse) { Write-Host "  (recursive)" -ForegroundColor Gray }

