<#
.SYNOPSIS
    Run Go commands.
.DESCRIPTION
    Runs a Go subcommand in the target directory with proper
    Windows PowerShell handling. Verifies go.mod exists for most commands.
.PARAMETER Command
    Go subcommand to run.
.PARAMETER ProjectPath
    Working directory. Default: current directory.
.PARAMETER PassThruArgs
    Additional arguments passed to the go command.
.EXAMPLE
    .claude\skills\polyglot-tools\scripts\go-run.ps1 -Command "build" -ProjectPath "api"
.EXAMPLE
    .claude\skills\polyglot-tools\scripts\go-run.ps1 -Command "test" -PassThruArgs "./..."
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("build","test","run","mod","fmt","vet","get","generate","install","clean")]
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
if ($Command -ne "mod" -and -not (Test-Path (Join-Path $resolved "go.mod"))) {
    Write-Error "No go.mod in $resolved"; exit 1
}

$goArgs = @($Command)
if ($PassThruArgs) { $goArgs += $PassThruArgs }

Write-Host ""
Write-Host "  Running go $Command in: $resolved" -ForegroundColor Cyan
Write-Host ""

Push-Location $resolved
try {
    Write-Host "  > go $($goArgs -join ' ')" -ForegroundColor DarkGray
    Write-Host ""
    & go @goArgs 2>&1
    $code = $LASTEXITCODE
    Write-Host ""
    if ($code -eq 0) { Write-Host "  PASSED (exit 0)" -ForegroundColor Green }
    else { Write-Host "  FAILED (exit $code)" -ForegroundColor Red }
    exit $code
} finally { Pop-Location }

