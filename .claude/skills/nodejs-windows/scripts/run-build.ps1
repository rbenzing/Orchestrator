<#
.SYNOPSIS
    Run npm build in a project directory.
.DESCRIPTION
    Safely changes to the target directory, verifies package.json exists and has
    a build script, then runs npm run build with optional arguments.
    Handles Windows/PowerShell pitfalls.
.PARAMETER ProjectPath
    Path to directory containing package.json. Absolute or relative.
.PARAMETER ScriptName
    Name of the build script in package.json. Default: "build".
    Use for projects with variants like "build:prod", "build:dev", etc.
.PARAMETER Profile
    Enable React build profiling (--profile). CRA/react-scripts only.
.PARAMETER SourceMap
    Generate source maps even for production (GENERATE_SOURCEMAP=true).
.PARAMETER NoBrowserslistUpdate
    Suppress browserslist "caniuse-lite is outdated" warnings.
.PARAMETER PassThruArgs
    Additional arguments passed directly to the build runner.
.EXAMPLE
    .claude\skills\nodejs-windows\scripts\run-build.ps1 -ProjectPath "ClientApp"
.EXAMPLE
    .claude\skills\nodejs-windows\scripts\run-build.ps1 -ProjectPath "src\app" -SourceMap
.EXAMPLE
    .claude\skills\nodejs-windows\scripts\run-build.ps1 -ProjectPath "." -ScriptName "build:prod"
.EXAMPLE
    .claude\skills\nodejs-windows\scripts\run-build.ps1 -ProjectPath "ClientApp" -PassThruArgs "--stats"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,
    [string]$ScriptName = "build",
    [switch]$Profile,
    [switch]$SourceMap,
    [switch]$NoBrowserslistUpdate,
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
if (-not (Test-Path (Join-Path $resolved "package.json"))) {
    Write-Error "No package.json in $resolved"; exit 1
}

# Check for build script in package.json
$pkg = Get-Content (Join-Path $resolved "package.json") -Raw | ConvertFrom-Json
$hasScript = $false
if ($pkg.scripts) {
    $hasScript = [bool]($pkg.scripts.PSObject.Properties | Where-Object { $_.Name -eq $ScriptName })
}
if (-not $hasScript) {
    Write-Error "No '$ScriptName' script found in $resolved\package.json. Available scripts: $(($pkg.scripts.PSObject.Properties.Name | Sort-Object) -join ', ')"
    exit 1
}

# Auto-install if needed
$nm = Join-Path $resolved "node_modules"
if (-not (Test-Path $nm)) {
    Write-Host "  node_modules missing - running npm install..." -ForegroundColor Yellow
    Push-Location $resolved
    try { npm install; if ($LASTEXITCODE -ne 0) { Write-Error "npm install failed"; exit $LASTEXITCODE } }
    finally { Pop-Location }
}

# Set environment variables for build
if ($SourceMap) { $env:GENERATE_SOURCEMAP = "true" }
if ($NoBrowserslistUpdate) { $env:BROWSERSLIST_IGNORE_OLD_DATA = "1" }

# Build args
$buildArgs = @()
if ($Profile) { $buildArgs += "--profile" }
if ($PassThruArgs) { $buildArgs += $PassThruArgs }

$argsStr = ($buildArgs -join " ")

Write-Host ""
Write-Host "  Building project in: $resolved" -ForegroundColor Cyan
Write-Host "  Script: npm run $ScriptName" -ForegroundColor Gray
if ($SourceMap) { Write-Host "  Source maps: enabled" -ForegroundColor Gray }
if ($argsStr) { Write-Host "  Args: $argsStr" -ForegroundColor Gray }
Write-Host ""

$sw = [System.Diagnostics.Stopwatch]::StartNew()

Push-Location $resolved
try {
    $npmArgs = @("run", $ScriptName)
    if ($buildArgs.Count -gt 0) { $npmArgs += "--"; $npmArgs += $buildArgs }
    Write-Host "  > npm $($npmArgs -join ' ')" -ForegroundColor DarkGray
    Write-Host ""
    & npm @npmArgs 2>&1
    $code = $LASTEXITCODE
    $sw.Stop()
    $elapsed = $sw.Elapsed.ToString("mm\:ss")
    Write-Host ""
    if ($code -eq 0) { Write-Host "  BUILD PASSED (exit 0, $elapsed)" -ForegroundColor Green }
    else { Write-Host "  BUILD FAILED (exit $code, $elapsed)" -ForegroundColor Red }
    exit $code
} finally {
    # Clean up env vars
    if ($SourceMap) { Remove-Item Env:\GENERATE_SOURCEMAP -ErrorAction SilentlyContinue }
    if ($NoBrowserslistUpdate) { Remove-Item Env:\BROWSERSLIST_IGNORE_OLD_DATA -ErrorAction SilentlyContinue }
    Pop-Location
}

