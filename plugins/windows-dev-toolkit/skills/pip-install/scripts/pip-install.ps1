<#
.SYNOPSIS
    Install Python packages with pip.
.DESCRIPTION
    Runs pip install with packages or a requirements file.
    Handles Windows PowerShell pitfalls.
.PARAMETER Packages
    Package names to install. Mutually exclusive with -RequirementsFile.
.PARAMETER RequirementsFile
    Path to requirements.txt. Mutually exclusive with -Packages.
.PARAMETER ProjectPath
    Working directory. Default: current directory.
.PARAMETER Upgrade
    Upgrade packages (--upgrade).
.PARAMETER PassThruArgs
    Additional arguments passed to pip install.
.EXAMPLE
    .claude\skills\pip-install\scripts\pip-install.ps1 -Packages "flask","requests"
.EXAMPLE
    .claude\skills\pip-install\scripts\pip-install.ps1 -RequirementsFile "requirements.txt"
#>
[CmdletBinding()]
param(
    [string[]]$Packages,
    [string]$RequirementsFile,
    [string]$ProjectPath = ".",
    [switch]$Upgrade,
    [string[]]$PassThruArgs,
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) {
    Write-Host "WARN: Stray arguments ignored: $($ExtraArgs -join ', ')"
}
if (-not $Packages -and -not $RequirementsFile) {
    Write-Error "Provide either -Packages or -RequirementsFile"; exit 1
}
if ($Packages -and $RequirementsFile) {
    Write-Error "Provide only one of -Packages or -RequirementsFile, not both"; exit 1
}
if (-not (Test-Path $ProjectPath -PathType Container)) {
    Write-Error "Directory not found: $ProjectPath"; exit 1
}
$resolved = (Resolve-Path $ProjectPath).Path

$pipArgs = @("install")
if ($Upgrade) { $pipArgs += "--upgrade" }
if ($RequirementsFile) {
    $reqPath = Join-Path $resolved $RequirementsFile
    if (-not (Test-Path $reqPath -PathType Leaf)) {
        Write-Error "Requirements file not found: $reqPath"; exit 1
    }
    $pipArgs += "-r"; $pipArgs += $RequirementsFile
} else {
    $pipArgs += $Packages
}
if ($PassThruArgs) { $pipArgs += $PassThruArgs }

Write-Host "Installing Python packages in: $resolved"

Push-Location $resolved
try {
    Write-Host "> pip $($pipArgs -join ' ')"
    & pip @pipArgs 2>&1
    $code = $LASTEXITCODE
    if ($code -eq 0) { Write-Host "INSTALL PASSED (exit 0)" }
    else { Write-Host "INSTALL FAILED (exit $code)" }
    exit $code
} finally { Pop-Location }