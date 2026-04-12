<#
.SYNOPSIS
    Run .NET tests in a project directory.
.DESCRIPTION
    Safely resolves the target directory, verifies a test project exists,
    and runs dotnet test with proper Windows PowerShell handling.
.PARAMETER ProjectPath
    Path to directory containing a test project. Absolute or relative.
.PARAMETER Filter
    Test filter expression for --filter (e.g. "FullyQualifiedName~Integration").
.PARAMETER NoBuild
    Skip building before testing (--no-build).
.PARAMETER NoRestore
    Skip NuGet restore (--no-restore).
.PARAMETER Verbosity
    MSBuild verbosity: quiet, minimal, normal, detailed, diagnostic.
.PARAMETER PassThruArgs
    Additional arguments passed directly to dotnet test.
.EXAMPLE
    .claude\skills\dotnet-test\scripts\dotnet-test.ps1 -ProjectPath "tests\MyApi.Tests"
.EXAMPLE
    .claude\skills\dotnet-test\scripts\dotnet-test.ps1 -ProjectPath "." -Filter "Category=Unit" -NoBuild
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,
    [string]$Filter,
    [switch]$NoBuild,
    [switch]$NoRestore,
    [ValidateSet("quiet","minimal","normal","detailed","diagnostic")]
    [string]$Verbosity,
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

$testArgs = @("test")
if ($Filter) { $testArgs += "--filter"; $testArgs += "`"$Filter`"" }
if ($NoBuild) { $testArgs += "--no-build" }
if ($NoRestore) { $testArgs += "--no-restore" }
if ($Verbosity) { $testArgs += "--verbosity"; $testArgs += $Verbosity }
if ($PassThruArgs) { $testArgs += $PassThruArgs }

$sw = [System.Diagnostics.Stopwatch]::StartNew()

Write-Host "Running .NET tests in: $resolved"
if ($Filter) { Write-Host "Filter: $Filter" }

Push-Location $resolved
try {
    Write-Host "> dotnet $($testArgs -join ' ')"
    & dotnet @testArgs 2>&1
    $code = $LASTEXITCODE
    $sw.Stop()
    $elapsed = $sw.Elapsed.ToString("mm\:ss")
    if ($code -eq 0) { Write-Host "TESTS PASSED (exit 0, $elapsed)" }
    else { Write-Host "TESTS FAILED (exit $code, $elapsed)" }
    exit $code
} finally { Pop-Location }