<#
.SYNOPSIS
    Restore NuGet packages for a .NET project or solution.
.DESCRIPTION
    Safely resolves the target directory, verifies a project/solution exists,
    and runs dotnet restore with proper Windows PowerShell handling.
.PARAMETER ProjectPath
    Path to directory containing a project or solution file. Absolute or relative.
.PARAMETER Verbosity
    MSBuild verbosity: quiet, minimal, normal, detailed, diagnostic.
.PARAMETER PassThruArgs
    Additional arguments passed directly to dotnet restore.
.EXAMPLE
    .augment\skills\dotnet-windows\scripts\dotnet-restore.ps1 -ProjectPath "."
.EXAMPLE
    .augment\skills\dotnet-windows\scripts\dotnet-restore.ps1 -ProjectPath "src\MyApi" -Verbosity "minimal"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,
    [ValidateSet("quiet","minimal","normal","detailed","diagnostic")]
    [string]$Verbosity,
    [string[]]$PassThruArgs,
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
if ($ExtraArgs) {
    Write-Host "  WARNING: Stray arguments ignored: $($ExtraArgs -join ', ')" -ForegroundColor Yellow
}

if (-not (Test-Path $ProjectPath -PathType Container)) {
    Write-Error "Directory not found: $ProjectPath"; exit 1
}
$resolved = (Resolve-Path $ProjectPath).Path

$projFiles = @(Get-ChildItem $resolved -File | Where-Object { $_.Extension -in '.csproj','.fsproj','.vbproj','.sln' })
if ($projFiles.Count -eq 0) {
    Write-Error "No .csproj, .fsproj, .vbproj, or .sln found in $resolved"; exit 1
}

$restoreArgs = @("restore")
if ($Verbosity) { $restoreArgs += "--verbosity"; $restoreArgs += $Verbosity }
if ($PassThruArgs) { $restoreArgs += $PassThruArgs }

Write-Host ""
Write-Host "  Restoring NuGet packages in: $resolved" -ForegroundColor Cyan
Write-Host ""

Push-Location $resolved
try {
    Write-Host "  > dotnet $($restoreArgs -join ' ')" -ForegroundColor DarkGray
    Write-Host ""
    & dotnet @restoreArgs 2>&1
    $code = $LASTEXITCODE
    Write-Host ""
    if ($code -eq 0) { Write-Host "  RESTORE PASSED (exit 0)" -ForegroundColor Green }
    else { Write-Host "  RESTORE FAILED (exit $code)" -ForegroundColor Red }
    exit $code
} finally { Pop-Location }

