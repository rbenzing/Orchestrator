<#
.SYNOPSIS
    Run Angular build in a project directory.
.DESCRIPTION
    Safely changes to the target directory, verifies package.json exists,
    sets NODE_OPTIONS if needed, and runs ng build / npm run build with
    proper Windows PowerShell handling.
.PARAMETER ProjectPath
    Path to directory containing package.json. Absolute or relative.
.PARAMETER LegacyOpenSSL
    Set NODE_OPTIONS=--openssl-legacy-provider before building.
    Required for older Angular projects on Node.js 17+.
.PARAMETER Configuration
    Angular build configuration (e.g. "production", "development").
.PARAMETER ScriptName
    Name of the build script in package.json. Default: "build".
.PARAMETER SourceMap
    Enable source maps (--source-map).
.PARAMETER PassThruArgs
    Additional arguments passed directly to the build runner.
.EXAMPLE
    .augment\skills\angular-windows\scripts\run-build.ps1 -ProjectPath "ClientApp"
.EXAMPLE
    .augment\skills\angular-windows\scripts\run-build.ps1 -ProjectPath "." -LegacyOpenSSL -Configuration "production"
.EXAMPLE
    .augment\skills\angular-windows\scripts\run-build.ps1 -ProjectPath "ClientApp" -ScriptName "build:prod"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,
    [switch]$LegacyOpenSSL,
    [string]$Configuration,
    [string]$ScriptName = "build",
    [switch]$SourceMap,
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

# Check for build script
$pkg = Get-Content (Join-Path $resolved "package.json") -Raw | ConvertFrom-Json
$hasScript = $false
if ($pkg.scripts) {
    $hasScript = [bool]($pkg.scripts.PSObject.Properties | Where-Object { $_.Name -eq $ScriptName })
}
if (-not $hasScript) {
    Write-Error "No '$ScriptName' script found in $resolved\package.json. Available: $(($pkg.scripts.PSObject.Properties.Name | Sort-Object) -join ', ')"
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

# Save and set NODE_OPTIONS
$prevNodeOptions = $env:NODE_OPTIONS
if ($LegacyOpenSSL) {
    $env:NODE_OPTIONS = "--openssl-legacy-provider"
    Write-Host "  NODE_OPTIONS set: --openssl-legacy-provider" -ForegroundColor Yellow
}

# Build args
$buildArgs = @()
if ($Configuration) { $buildArgs += "--configuration=`"$Configuration`"" }
if ($SourceMap) { $buildArgs += "--source-map" }
if ($PassThruArgs) { $buildArgs += $PassThruArgs }

$argsStr = ($buildArgs -join " ")

Write-Host ""
Write-Host "  Building Angular project in: $resolved" -ForegroundColor Cyan
Write-Host "  Script: npm run $ScriptName" -ForegroundColor Gray
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
    if ($LegacyOpenSSL) {
        if ($prevNodeOptions) { $env:NODE_OPTIONS = $prevNodeOptions }
        else { Remove-Item Env:\NODE_OPTIONS -ErrorAction SilentlyContinue }
    }
    Pop-Location
}

