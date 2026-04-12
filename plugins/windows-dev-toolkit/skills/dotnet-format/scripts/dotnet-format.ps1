<#
.SYNOPSIS
    Format .NET code using dotnet format.
.DESCRIPTION
    Safely resolves the target directory, verifies a project/solution exists,
    and runs dotnet format with proper Windows PowerShell handling.
.PARAMETER ProjectPath
    Path to directory containing a project or solution file. Absolute or relative.
.PARAMETER VerifyNoChanges
    Check formatting without making changes (--verify-no-changes). Returns non-zero if changes needed.
.PARAMETER Severity
    Minimum severity to format: info, warn, error.
.PARAMETER Diagnostics
    Specific diagnostic IDs to format (e.g. "IDE0055","IDE0003").
.PARAMETER PassThruArgs
    Additional arguments passed directly to dotnet format.
.EXAMPLE
    .claude\skills\dotnet-format\scripts\dotnet-format.ps1 -ProjectPath "src\MyApi"
.EXAMPLE
    .claude\skills\dotnet-format\scripts\dotnet-format.ps1 -ProjectPath "." -VerifyNoChanges -Severity "warn"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,
    [switch]$VerifyNoChanges,
    [ValidateSet("info","warn","error")]
    [string]$Severity,
    [string[]]$Diagnostics,
    [string[]]$PassThruArgs,
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) {
    Write-Host "WARN: Stray arguments ignored: $($ExtraArgs -join ', ')"
}

if (-not (Test-Path $ProjectPath -PathType Container)) {
    Write-Error "Directory not found: $ProjectPath"; exit 1
}
$resolved = (Resolve-Path $ProjectPath).Path

$projFiles = @(Get-ChildItem $resolved -File | Where-Object { $_.Extension -in '.csproj','.fsproj','.vbproj','.sln' })
if ($projFiles.Count -eq 0) {
    Write-Error "No .csproj, .fsproj, .vbproj, or .sln found in $resolved"; exit 1
}

$formatArgs = @("format")
if ($VerifyNoChanges) { $formatArgs += "--verify-no-changes" }
if ($Severity) { $formatArgs += "--severity"; $formatArgs += $Severity }
if ($Diagnostics) { $formatArgs += "--diagnostics"; $formatArgs += ($Diagnostics -join " ") }
if ($PassThruArgs) { $formatArgs += $PassThruArgs }

$mode = if ($VerifyNoChanges) { "Verifying" } else { "Formatting" }

Write-Host "$mode .NET code in: $resolved"
if ($Severity) { Write-Host "Severity: $Severity" }

Push-Location $resolved
try {
    Write-Host "> dotnet $($formatArgs -join ' ')"
    & dotnet @formatArgs 2>&1
    $code = $LASTEXITCODE
    if ($code -eq 0) { Write-Host "FORMAT PASSED (exit 0)" }
    else { Write-Host "FORMAT FAILED (exit $code)" }
    exit $code
} finally { Pop-Location }