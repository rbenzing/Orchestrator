<#
.SYNOPSIS
    Run a Python script or module.
.DESCRIPTION
    Safely resolves the target directory and runs python with proper
    Windows PowerShell handling. Supports script files or -m module invocation.
.PARAMETER ScriptPath
    Path to a .py file to execute. Mutually exclusive with -Module.
.PARAMETER Module
    Python module to run via python -m (e.g. "pytest", "flask").
.PARAMETER ProjectPath
    Working directory. Default: current directory.
.PARAMETER PassThruArgs
    Additional arguments passed to the script or module.
.EXAMPLE
    .augment\skills\polyglot-tools\scripts\python-run.ps1 -ScriptPath "main.py"
.EXAMPLE
    .augment\skills\polyglot-tools\scripts\python-run.ps1 -Module "pytest" -PassThruArgs "-v","--tb=short"
#>
[CmdletBinding()]
param(
    [string]$ScriptPath,
    [string]$Module,
    [string]$ProjectPath = ".",
    [string[]]$PassThruArgs,
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
if ($ExtraArgs) {
    Write-Host "  WARNING: Stray arguments ignored: $($ExtraArgs -join ', ')" -ForegroundColor Yellow
}
if (-not $ScriptPath -and -not $Module) {
    Write-Error "Provide either -ScriptPath or -Module"; exit 1
}
if ($ScriptPath -and $Module) {
    Write-Error "Provide only one of -ScriptPath or -Module, not both"; exit 1
}
if (-not (Test-Path $ProjectPath -PathType Container)) {
    Write-Error "Directory not found: $ProjectPath"; exit 1
}
$resolved = (Resolve-Path $ProjectPath).Path

$pyArgs = @()
if ($Module) {
    $pyArgs += "-m"; $pyArgs += $Module
} else {
    $fullScript = Join-Path $resolved $ScriptPath
    if (-not (Test-Path $fullScript -PathType Leaf)) {
        Write-Error "Script not found: $fullScript"; exit 1
    }
    $pyArgs += $ScriptPath
}
if ($PassThruArgs) { $pyArgs += $PassThruArgs }

Write-Host ""
Write-Host "  Running Python in: $resolved" -ForegroundColor Cyan
Write-Host ""

Push-Location $resolved
try {
    Write-Host "  > python $($pyArgs -join ' ')" -ForegroundColor DarkGray
    Write-Host ""
    & python @pyArgs 2>&1
    $code = $LASTEXITCODE
    Write-Host ""
    if ($code -eq 0) { Write-Host "  PASSED (exit 0)" -ForegroundColor Green }
    else { Write-Host "  FAILED (exit $code)" -ForegroundColor Red }
    exit $code
} finally { Pop-Location }

