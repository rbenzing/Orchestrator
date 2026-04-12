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
    .claude\skills\cargo-run\scripts\cargo-run.ps1 -Command "build" -ProjectPath "rust-lib"
.EXAMPLE
    .claude\skills\cargo-run\scripts\cargo-run.ps1 -Command "test" -PassThruArgs "--release"
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
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) {
    Write-Host "WARN: Stray arguments ignored: $($ExtraArgs -join ', ')"
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

Write-Host "Running cargo $Command in: $resolved"

Push-Location $resolved
try {
    Write-Host "> cargo $($cargoArgs -join ' ')"
    & cargo @cargoArgs 2>&1
    $code = $LASTEXITCODE
    if ($code -eq 0) { Write-Host "PASSED (exit 0)" }
    else { Write-Host "FAILED (exit $code)" }
    exit $code
} finally { Pop-Location }