<#
.SYNOPSIS
    Run Node.js tests in a project directory.
.DESCRIPTION
    Safely changes to the target directory, verifies package.json exists,
    runs npm test with optional arguments. Handles Windows/PowerShell pitfalls.
.PARAMETER ProjectPath
    Path to directory containing package.json. Absolute or relative.
.PARAMETER TestPathPattern
    Regex for --testPathPattern (react-scripts/jest).
.PARAMETER TestNamePattern
    Pattern for --testNamePattern (jest -t).
.PARAMETER NoWatch
    Disable watch mode (--watchAll=false). Default: enabled.
.PARAMETER ForceExit
    Force Jest to exit after tests (--forceExit).
.PARAMETER Coverage
    Run with coverage (--coverage).
.PARAMETER PassThruArgs
    Additional arguments passed directly to the test runner.
.EXAMPLE
    .claude\skills\nodejs-windows\scripts\run-tests.ps1 -ProjectPath "ClientApp"
.EXAMPLE
    .claude\skills\nodejs-windows\scripts\run-tests.ps1 -ProjectPath "src\app" -TestPathPattern "components/charts" -Coverage
.EXAMPLE
    .claude\skills\nodejs-windows\scripts\run-tests.ps1 -ProjectPath "." -PassThruArgs "--maxWorkers=2","--bail"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,
    [string]$TestPathPattern,
    [string]$TestNamePattern,
    [switch]$NoWatch,
    [switch]$ForceExit,
    [switch]$Coverage,
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

# Build args
$testArgs = @()
if ($NoWatch) { $testArgs += "--watchAll=false" }
if ($ForceExit) { $testArgs += "--forceExit" }
if ($Coverage) { $testArgs += "--coverage" }
if ($TestPathPattern) { $testArgs += "--testPathPattern=`"$TestPathPattern`"" }
if ($TestNamePattern) { $testArgs += "--testNamePattern=`"$TestNamePattern`"" }
if ($PassThruArgs) { $testArgs += $PassThruArgs }

$argsStr = ($testArgs -join " ")

Write-Host ""
Write-Host "  Running tests in: $resolved" -ForegroundColor Cyan
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
    if ($code -eq 0) { Write-Host "  PASSED (exit 0)" -ForegroundColor Green }
    else { Write-Host "  FAILED (exit $code)" -ForegroundColor Red }
    exit $code
} finally { Pop-Location }

