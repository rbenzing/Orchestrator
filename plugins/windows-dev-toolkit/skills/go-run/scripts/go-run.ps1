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
    .claude\skills\go-run\scripts\go-run.ps1 -Command "build" -ProjectPath "api"
.EXAMPLE
    .claude\skills\go-run\scripts\go-run.ps1 -Command "test" -PassThruArgs "./..."
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
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) {
    Write-Host "WARN: Stray arguments ignored: $($ExtraArgs -join ', ')"
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

Write-Host "Running go $Command in: $resolved"

Push-Location $resolved
try {
    Write-Host "> go $($goArgs -join ' ')"
    & go @goArgs 2>&1
    $code = $LASTEXITCODE
    if ($code -eq 0) { Write-Host "PASSED (exit 0)" }
    else { Write-Host "FAILED (exit $code)" }
    exit $code
} finally { Pop-Location }