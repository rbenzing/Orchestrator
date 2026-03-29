<#
.SYNOPSIS
    Run Cargo (Rust) commands.
.DESCRIPTION
    Runs a Cargo subcommand in the target directory with proper
    Windows PowerShell handling. Verifies Cargo.toml exists.
.PARAMETER Command
    Cargo subcommand to run.
.PARAMETER ProjectPath
    Working directory. Default: current directory.
.PARAMETER PassThruArgs
    Additional arguments passed to the cargo command.
.EXAMPLE
    .augment\skills\polyglot-tools\scripts\cargo-run.ps1 -Command "build" -ProjectPath "rust-lib"
.EXAMPLE
    .augment\skills\polyglot-tools\scripts\cargo-run.ps1 -Command "test" -PassThruArgs "--release"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("build","test","run","check","clippy","fmt","doc","bench","clean")]
    [string]$Command,
    [string]$ProjectPath = ".",
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
if (-not (Test-Path (Join-Path $resolved "Cargo.toml"))) {
    Write-Error "No Cargo.toml in $resolved"; exit 1
}

$cargoArgs = @($Command)
if ($PassThruArgs) { $cargoArgs += $PassThruArgs }

Write-Host ""
Write-Host "  Running cargo $Command in: $resolved" -ForegroundColor Cyan
Write-Host ""

Push-Location $resolved
try {
    Write-Host "  > cargo $($cargoArgs -join ' ')" -ForegroundColor DarkGray
    Write-Host ""
    & cargo @cargoArgs 2>&1
    $code = $LASTEXITCODE
    Write-Host ""
    if ($code -eq 0) { Write-Host "  PASSED (exit 0)" -ForegroundColor Green }
    else { Write-Host "  FAILED (exit $code)" -ForegroundColor Red }
    exit $code
} finally { Pop-Location }

