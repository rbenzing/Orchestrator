<#
.SYNOPSIS
    Run a .NET project.
.DESCRIPTION
    Safely resolves the target directory, verifies a project exists,
    and runs dotnet run with proper Windows PowerShell handling.
.PARAMETER ProjectPath
    Path to directory containing a project file. Absolute or relative.
.PARAMETER Configuration
    Build configuration (e.g. "Debug", "Release"). Default: "Debug".
.PARAMETER LaunchProfile
    Launch profile name from launchSettings.json.
.PARAMETER NoBuild
    Skip building before running (--no-build).
.PARAMETER PassThruArgs
    Additional arguments passed directly to dotnet run.
.EXAMPLE
    .augment\skills\dotnet-windows\scripts\dotnet-run.ps1 -ProjectPath "src\MyApi"
.EXAMPLE
    .augment\skills\dotnet-windows\scripts\dotnet-run.ps1 -ProjectPath "src\MyApi" -LaunchProfile "Development"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,
    [string]$Configuration = "Debug",
    [string]$LaunchProfile,
    [switch]$NoBuild,
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

$projFiles = @(Get-ChildItem $resolved -File | Where-Object { $_.Extension -in '.csproj','.fsproj','.vbproj' })
if ($projFiles.Count -eq 0) {
    Write-Error "No .csproj, .fsproj, or .vbproj found in $resolved"; exit 1
}

$runArgs = @("run", "--configuration", $Configuration)
if ($LaunchProfile) { $runArgs += "--launch-profile"; $runArgs += "`"$LaunchProfile`"" }
if ($NoBuild) { $runArgs += "--no-build" }
if ($PassThruArgs) { $runArgs += "--"; $runArgs += $PassThruArgs }

Write-Host ""
Write-Host "  Running .NET project in: $resolved" -ForegroundColor Cyan
Write-Host "  Configuration: $Configuration" -ForegroundColor Gray
if ($LaunchProfile) { Write-Host "  Launch profile: $LaunchProfile" -ForegroundColor Gray }
Write-Host ""

Push-Location $resolved
try {
    Write-Host "  > dotnet $($runArgs -join ' ')" -ForegroundColor DarkGray
    Write-Host ""
    & dotnet @runArgs 2>&1
    $code = $LASTEXITCODE
    Write-Host ""
    if ($code -eq 0) { Write-Host "  RUN COMPLETED (exit 0)" -ForegroundColor Green }
    else { Write-Host "  RUN FAILED (exit $code)" -ForegroundColor Red }
    exit $code
} finally { Pop-Location }

