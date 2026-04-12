<#
.SYNOPSIS
    Build a .NET project or solution.
.DESCRIPTION
    Safely resolves the target directory, verifies a .csproj/.fsproj/.sln exists,
    and runs dotnet build with proper Windows PowerShell handling.
.PARAMETER ProjectPath
    Path to directory containing a project or solution file. Absolute or relative.
.PARAMETER Configuration
    Build configuration (e.g. "Debug", "Release"). Default: "Debug".
.PARAMETER Verbosity
    MSBuild verbosity: quiet, minimal, normal, detailed, diagnostic.
.PARAMETER NoRestore
    Skip NuGet restore (--no-restore).
.PARAMETER PassThruArgs
    Additional arguments passed directly to dotnet build.
.EXAMPLE
    .claude\skills\dotnet-build\scripts\dotnet-build.ps1 -ProjectPath "src\MyApi"
.EXAMPLE
    .claude\skills\dotnet-build\scripts\dotnet-build.ps1 -ProjectPath "." -Configuration "Release"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,
    [string]$Configuration = "Debug",
    [ValidateSet("quiet","minimal","normal","detailed","diagnostic")]
    [string]$Verbosity,
    [switch]$NoRestore,
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

# Verify project/solution exists
$projFiles = @(Get-ChildItem $resolved -File | Where-Object { $_.Extension -in '.csproj','.fsproj','.vbproj','.sln' })
if ($projFiles.Count -eq 0) {
    Write-Error "No .csproj, .fsproj, .vbproj, or .sln found in $resolved"; exit 1
}

$buildArgs = @("build", "--configuration", $Configuration)
if ($Verbosity) { $buildArgs += "--verbosity"; $buildArgs += $Verbosity }
if ($NoRestore) { $buildArgs += "--no-restore" }
if ($PassThruArgs) { $buildArgs += $PassThruArgs }

$sw = [System.Diagnostics.Stopwatch]::StartNew()

Write-Host "Building .NET project in: $resolved"
Write-Host "Configuration: $Configuration"

Push-Location $resolved
try {
    Write-Host "> dotnet $($buildArgs -join ' ')"
    & dotnet @buildArgs 2>&1
    $code = $LASTEXITCODE
    $sw.Stop()
    $elapsed = $sw.Elapsed.ToString("mm\:ss")
    if ($code -eq 0) { Write-Host "BUILD PASSED (exit 0, $elapsed)" }
    else { Write-Host "BUILD FAILED (exit $code, $elapsed)" }
    exit $code
} finally { Pop-Location }