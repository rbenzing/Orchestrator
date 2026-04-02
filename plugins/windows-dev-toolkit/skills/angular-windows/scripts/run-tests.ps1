<#
.SYNOPSIS
    Run Angular tests in a project directory.
.DESCRIPTION
    Safely changes to the target directory, verifies package.json exists,
    sets NODE_OPTIONS if needed, and runs ng test / npm test with proper
    Windows PowerShell handling. Supports ChromeHeadless and legacy OpenSSL.
.PARAMETER ProjectPath
    Path to directory containing package.json. Absolute or relative.
.PARAMETER LegacyOpenSSL
    Set NODE_OPTIONS=--openssl-legacy-provider before running tests.
    Required for older Angular projects on Node.js 17+.
.PARAMETER Headless
    Use ChromeHeadless browser (--browsers=ChromeHeadless).
.PARAMETER NoWatch
    Disable watch mode (--no-watch). Recommended for CI.
.PARAMETER Include
    Test file pattern to include (--include).
.PARAMETER CodeCoverage
    Enable code coverage (--code-coverage).
.PARAMETER PassThruArgs
    Additional arguments passed directly to the test runner.
.EXAMPLE
    .claude\skills\angular-windows\scripts\run-tests.ps1 -ProjectPath "ClientApp"
.EXAMPLE
    .claude\skills\angular-windows\scripts\run-tests.ps1 -ProjectPath "ClientApp" -LegacyOpenSSL -Headless -NoWatch
.EXAMPLE
    .claude\skills\angular-windows\scripts\run-tests.ps1 -ProjectPath "." -Include "src/app/components" -CodeCoverage
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,
    [switch]$LegacyOpenSSL,
    [switch]$Headless,
    [switch]$NoWatch,
    [string]$Include,
    [switch]$CodeCoverage,
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
$testArgs = @()
if ($NoWatch) { $testArgs += "--no-watch" }
if ($Headless) { $testArgs += "--browsers=ChromeHeadless" }
if ($CodeCoverage) { $testArgs += "--code-coverage" }
if ($Include) { $testArgs += "--include=`"$Include`"" }
if ($PassThruArgs) { $testArgs += $PassThruArgs }

$argsStr = ($testArgs -join " ")

Write-Host ""
Write-Host "  Running Angular tests in: $resolved" -ForegroundColor Cyan
if ($argsStr) { Write-Host "  Args: $argsStr" -ForegroundColor Gray }
Write-Host ""

Push-Location $resolved
try {
    $npmArgs = @("test")
    if ($testArgs.Count -gt 0) { $npmArgs += "--"; $npmArgs += $testArgs }
    Write-Host "  > npm $($npmArgs -join ' ')" -ForegroundColor DarkGray
    Write-Host ""
    & npm @npmArgs 2>&1
    $code = $LASTEXITCODE
    Write-Host ""
    if ($code -eq 0) { Write-Host "  TESTS PASSED (exit 0)" -ForegroundColor Green }
    else { Write-Host "  TESTS FAILED (exit $code)" -ForegroundColor Red }
    exit $code
} finally {
    # Restore NODE_OPTIONS
    if ($LegacyOpenSSL) {
        if ($prevNodeOptions) { $env:NODE_OPTIONS = $prevNodeOptions }
        else { Remove-Item Env:\NODE_OPTIONS -ErrorAction SilentlyContinue }
    }
    Pop-Location
}

