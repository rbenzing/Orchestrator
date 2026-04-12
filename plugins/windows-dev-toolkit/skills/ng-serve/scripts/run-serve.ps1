<#
.SYNOPSIS
    Run Angular dev server in a project directory.
.DESCRIPTION
    Safely changes to the target directory, verifies package.json exists,
    sets NODE_OPTIONS if needed, and runs ng serve / npm start with
    proper Windows PowerShell handling.
.PARAMETER ProjectPath
    Path to directory containing package.json. Absolute or relative.
.PARAMETER LegacyOpenSSL
    Set NODE_OPTIONS=--openssl-legacy-provider before serving.
    Required for older Angular projects on Node.js 17+.
.PARAMETER Port
    Port number for the dev server (--port).
.PARAMETER Open
    Open browser automatically (--open).
.PARAMETER Configuration
    Angular configuration (e.g. "development", "production").
.PARAMETER ScriptName
    Name of the serve script in package.json. Default: "start".
.PARAMETER PassThruArgs
    Additional arguments passed directly to the serve runner.
.EXAMPLE
    .claude\skills\ng-serve\scripts\run-serve.ps1 -ProjectPath "ClientApp"
.EXAMPLE
    .claude\skills\ng-serve\scripts\run-serve.ps1 -ProjectPath "." -LegacyOpenSSL -Port 4200 -Open
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,
    [switch]$LegacyOpenSSL,
    [string]$Port,
    [switch]$Open,
    [string]$Configuration,
    [string]$ScriptName = "start",
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
if (-not (Test-Path (Join-Path $resolved "package.json"))) {
    Write-Error "No package.json in $resolved"; exit 1
}

# Auto-install if needed
$nm = Join-Path $resolved "node_modules"
if (-not (Test-Path $nm)) {
    Write-Host "node_modules missing - running npm install..."
    Push-Location $resolved
    try { npm install; if ($LASTEXITCODE -ne 0) { Write-Error "npm install failed"; exit $LASTEXITCODE } }
    finally { Pop-Location }
}

# Save and set NODE_OPTIONS
$prevNodeOptions = $env:NODE_OPTIONS
if ($LegacyOpenSSL) {
    $env:NODE_OPTIONS = "--openssl-legacy-provider"
    Write-Host "NODE_OPTIONS set: --openssl-legacy-provider"
}

# Build args
$serveArgs = @()
if ($Port) { $serveArgs += "--port=`"$Port`"" }
if ($Open) { $serveArgs += "--open" }
if ($Configuration) { $serveArgs += "--configuration=`"$Configuration`"" }
if ($PassThruArgs) { $serveArgs += $PassThruArgs }

$argsStr = ($serveArgs -join " ")

Write-Host "Starting Angular dev server in: $resolved"
Write-Host "Script: npm run $ScriptName"
if ($Port) { Write-Host "Port: $Port" }
if ($argsStr) { Write-Host "Args: $argsStr" }

Push-Location $resolved
try {
    $npmArgs = @("run", $ScriptName)
    if ($serveArgs.Count -gt 0) { $npmArgs += "--"; $npmArgs += $serveArgs }
    Write-Host "> npm $($npmArgs -join ' ')"
    & npm @npmArgs 2>&1
    $code = $LASTEXITCODE
    if ($code -eq 0) { Write-Host "Server stopped (exit 0)" }
    else { Write-Host "Server stopped (exit $code)" }
    exit $code
} finally {
    if ($LegacyOpenSSL) {
        if ($prevNodeOptions) { $env:NODE_OPTIONS = $prevNodeOptions }
        else { Remove-Item Env:\NODE_OPTIONS -ErrorAction SilentlyContinue }
    }
    Pop-Location
}