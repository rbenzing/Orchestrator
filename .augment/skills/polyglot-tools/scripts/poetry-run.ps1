<#
.SYNOPSIS
    Run Poetry commands.
.DESCRIPTION
    Runs a Poetry subcommand in the target directory with proper
    Windows PowerShell handling.
.PARAMETER Command
    Poetry subcommand to run.
.PARAMETER ProjectPath
    Working directory. Default: current directory.
.PARAMETER PassThruArgs
    Additional arguments passed to the poetry command.
.EXAMPLE
    .augment\skills\polyglot-tools\scripts\poetry-run.ps1 -Command "install" -ProjectPath "backend"
.EXAMPLE
    .augment\skills\polyglot-tools\scripts\poetry-run.ps1 -Command "run" -PassThruArgs "pytest","-v"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("install","update","add","remove","run","build","lock","show")]
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

$poetryArgs = @($Command)
if ($PassThruArgs) { $poetryArgs += $PassThruArgs }

Write-Host ""
Write-Host "  Running poetry $Command in: $resolved" -ForegroundColor Cyan
Write-Host ""

Push-Location $resolved
try {
    Write-Host "  > poetry $($poetryArgs -join ' ')" -ForegroundColor DarkGray
    Write-Host ""
    & poetry @poetryArgs 2>&1
    $code = $LASTEXITCODE
    Write-Host ""
    if ($code -eq 0) { Write-Host "  PASSED (exit 0)" -ForegroundColor Green }
    else { Write-Host "  FAILED (exit $code)" -ForegroundColor Red }
    exit $code
} finally { Pop-Location }

