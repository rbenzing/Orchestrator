<#
.SYNOPSIS
    Rename a file or directory in place.
.DESCRIPTION
    Renames a file or directory with safety guards: blocks renames
    in protected directories (.git, .claude).
.PARAMETER Path
    Path to the file or directory to rename.
.PARAMETER NewName
    New name (not a full path — just the filename or directory name).
.EXAMPLE
    .claude\skills\windows-environment\scripts\rename-item.ps1 -Path "src\utils.js" -NewName "helpers.js"
.EXAMPLE
    .claude\skills\windows-environment\scripts\rename-item.ps1 -Path "src\old-module" -NewName "new-module"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [string]$NewName,
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
    if ($leaf -in $BlockedNames) { return "Cannot target protected directory: $leaf" }
    return $null
}

$reason = Test-SafePath $Path
if ($reason) { Write-Error "BLOCKED: $reason"; exit 1 }

if ($NewName -match '[/\\]') {
    Write-Error "-NewName must be a simple name, not a path. Use move-item.ps1 to move files."; exit 1
}
if ($NewName -in $BlockedNames) {
    Write-Error "BLOCKED: Cannot rename to protected name '$NewName'"; exit 1
}

if (-not (Test-Path $Path)) {
    Write-Error "Path not found: $Path"; exit 1
}

Rename-Item -Path $Path -NewName $NewName
Write-Host ""
Write-Host "  RENAMED: $Path -> $NewName" -ForegroundColor Green

