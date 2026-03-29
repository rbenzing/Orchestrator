<#
.SYNOPSIS
    Run ESLint / npm run lint in a project directory.
.DESCRIPTION
    Safely changes to the target directory, verifies package.json exists and has
    a lint script, then runs npm run lint with optional arguments.
    Handles Windows/PowerShell pitfalls.
.PARAMETER ProjectPath
    Path to directory containing package.json. Absolute or relative.
.PARAMETER Fix
    Apply auto-fixes (--fix).
.PARAMETER Quiet
    Suppress warnings, show only errors (--quiet).
.PARAMETER MaxWarnings
    Fail if warning count exceeds this number (--max-warnings N).
.PARAMETER Files
    Specific files or globs to lint instead of defaults.
    Example: "src/**/*.ts","src/**/*.tsx"
.PARAMETER Format
    Output format: stylish, json, compact, etc. (--format).
.PARAMETER PassThruArgs
    Additional arguments passed directly to the lint runner.
.EXAMPLE
    .augment\skills\nodejs-windows\scripts\run-lint.ps1 -ProjectPath "ClientApp"
.EXAMPLE
    .augment\skills\nodejs-windows\scripts\run-lint.ps1 -ProjectPath "src\app" -Fix
.EXAMPLE
    .augment\skills\nodejs-windows\scripts\run-lint.ps1 -ProjectPath "." -Quiet -MaxWarnings 0
.EXAMPLE
    .augment\skills\nodejs-windows\scripts\run-lint.ps1 -ProjectPath "ClientApp" -Files "src/**/*.ts" -Fix
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,
    [switch]$Fix,
    [switch]$Quiet,
    [string]$MaxWarnings,
    [string[]]$Files,
    [string]$Format,
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

# Check for lint script in package.json
$pkg = Get-Content (Join-Path $resolved "package.json") -Raw | ConvertFrom-Json
$hasLint = $false
if ($pkg.scripts) {
    $hasLint = [bool]($pkg.scripts.PSObject.Properties | Where-Object { $_.Name -eq "lint" })
}
if (-not $hasLint) {
    Write-Error "No 'lint' script found in $resolved\package.json. Available scripts: $(($pkg.scripts.PSObject.Properties.Name | Sort-Object) -join ', ')"
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

# Build args
$lintArgs = @()
if ($Fix) { $lintArgs += "--fix" }
if ($Quiet) { $lintArgs += "--quiet" }
if ($MaxWarnings -ne $null -and $MaxWarnings -ne "") { $lintArgs += "--max-warnings"; $lintArgs += "$MaxWarnings" }
if ($Format) { $lintArgs += "--format"; $lintArgs += "$Format" }
if ($Files) { $lintArgs += $Files }
if ($PassThruArgs) { $lintArgs += $PassThruArgs }

$argsStr = ($lintArgs -join " ")

Write-Host ""
Write-Host "  Running lint in: $resolved" -ForegroundColor Cyan
if ($argsStr) { Write-Host "  Args: $argsStr" -ForegroundColor Gray }
Write-Host ""

Push-Location $resolved
try {
    $npmArgs = @("run", "lint")
    if ($lintArgs.Count -gt 0) { $npmArgs += "--"; $npmArgs += $lintArgs }
    Write-Host "  > npm $($npmArgs -join ' ')" -ForegroundColor DarkGray
    Write-Host ""
    & npm @npmArgs 2>&1
    $code = $LASTEXITCODE
    Write-Host ""
    if ($code -eq 0) { Write-Host "  LINT PASSED (exit 0)" -ForegroundColor Green }
    else { Write-Host "  LINT FAILED (exit $code)" -ForegroundColor Red }
    exit $code
} finally { Pop-Location }

