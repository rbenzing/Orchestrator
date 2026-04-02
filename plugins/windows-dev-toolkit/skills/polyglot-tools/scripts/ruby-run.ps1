<#
.SYNOPSIS
    Run Ruby scripts or Bundler commands.
.DESCRIPTION
    Runs ruby with a script file or bundle with a subcommand.
    Handles Windows PowerShell pitfalls.
.PARAMETER ScriptPath
    Path to a .rb file to execute. Mutually exclusive with -BundleCommand.
.PARAMETER BundleCommand
    Bundler subcommand (e.g. "install", "exec", "update").
.PARAMETER ProjectPath
    Working directory. Default: current directory.
.PARAMETER PassThruArgs
    Additional arguments passed to ruby or bundle.
.EXAMPLE
    .claude\skills\polyglot-tools\scripts\ruby-run.ps1 -ScriptPath "app.rb"
.EXAMPLE
    .claude\skills\polyglot-tools\scripts\ruby-run.ps1 -BundleCommand "install" -ProjectPath "rails-app"
.EXAMPLE
    .claude\skills\polyglot-tools\scripts\ruby-run.ps1 -BundleCommand "exec" -PassThruArgs "rspec","--format","doc"
#>
[CmdletBinding()]
param(
    [string]$ScriptPath,
    [string]$BundleCommand,
    [string]$ProjectPath = ".",
    [string[]]$PassThruArgs,
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
if ($ExtraArgs) {
    Write-Host "  WARNING: Stray arguments ignored: $($ExtraArgs -join ', ')" -ForegroundColor Yellow
}
if (-not $ScriptPath -and -not $BundleCommand) {
    Write-Error "Provide either -ScriptPath or -BundleCommand"; exit 1
}
if ($ScriptPath -and $BundleCommand) {
    Write-Error "Provide only one of -ScriptPath or -BundleCommand, not both"; exit 1
}
if (-not (Test-Path $ProjectPath -PathType Container)) {
    Write-Error "Directory not found: $ProjectPath"; exit 1
}
$resolved = (Resolve-Path $ProjectPath).Path

if ($BundleCommand) {
    $exe = "bundle"
    $runArgs = @($BundleCommand)
    if ($BundleCommand -in @("install","update") -and (Test-Path (Join-Path $resolved "Gemfile") -PathType Leaf) -eq $false) {
        Write-Error "No Gemfile in $resolved"; exit 1
    }
} else {
    $exe = "ruby"
    $fullScript = Join-Path $resolved $ScriptPath
    if (-not (Test-Path $fullScript -PathType Leaf)) {
        Write-Error "Script not found: $fullScript"; exit 1
    }
    $runArgs = @($ScriptPath)
}
if ($PassThruArgs) { $runArgs += $PassThruArgs }

Write-Host ""
Write-Host "  Running $exe in: $resolved" -ForegroundColor Cyan
Write-Host ""

Push-Location $resolved
try {
    Write-Host "  > $exe $($runArgs -join ' ')" -ForegroundColor DarkGray
    Write-Host ""
    & $exe @runArgs 2>&1
    $code = $LASTEXITCODE
    Write-Host ""
    if ($code -eq 0) { Write-Host "  PASSED (exit 0)" -ForegroundColor Green }
    else { Write-Host "  FAILED (exit $code)" -ForegroundColor Red }
    exit $code
} finally { Pop-Location }

