<#
.SYNOPSIS
    Move files or directories safely.
.DESCRIPTION
    Moves a source file or directory to a destination with safety guards:
    blocks moves into or out of protected directories (.git, .claude).
.PARAMETER Source
    Source file or directory path.
.PARAMETER Destination
    Destination path.
.PARAMETER Force
    Overwrite existing destination.
.EXAMPLE
    .claude\skills\move-item\scripts\move-item.ps1 -Source "old-name.ts" -Destination "new-name.ts"
.EXAMPLE
    .claude\skills\move-item\scripts\move-item.ps1 -Source "src\legacy" -Destination "src\deprecated"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Source,
    [Parameter(Mandatory = $true)]
    [string]$Destination,
    [switch]$Force,
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) {
    Write-Host "WARN: Stray arguments ignored: $($ExtraArgs -join ', ')"
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

$moveArgs = @{ Path = $Source; Destination = $Destination }
if ($Force) { $moveArgs.Force = $true }

Move-Item @moveArgs
Write-Host "MOVED: $Source -> $Destination"