<#
.SYNOPSIS
    Kill process by TCP port or PID with safety checks.
.DESCRIPTION
    Two modes: -Port finds processes on a TCP port, -ProcessId targets a PID.
    Dry-run by default - requires -Force to actually stop processes.
    Blocks killing critical Windows processes (svchost, csrss, lsass, etc.).
.PARAMETER Port
    TCP port to check. Use this OR -ProcessId.
.PARAMETER ProcessId
    PID to stop. Use this OR -Port.
.PARAMETER Force
    Actually kill. Without this, only reports what it finds.
.PARAMETER ProcessName
    Filter (Port mode only). Only kill processes matching this name.
.EXAMPLE
    .augment\skills\dev-tools\scripts\kill-port.ps1 -Port 3000
.EXAMPLE
    .augment\skills\dev-tools\scripts\kill-port.ps1 -Port 3000 -Force
.EXAMPLE
    .augment\skills\dev-tools\scripts\kill-port.ps1 -ProcessId 12345 -Force
#>
[CmdletBinding(DefaultParameterSetName = 'ByPort')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'ByPort')]
    [int]$Port,
    [Parameter(Mandatory = $true, ParameterSetName = 'ByPid')]
    [int]$ProcessId,
    [switch]$Force,
    [Parameter(ParameterSetName = 'ByPort')]
    [string]$ProcessName,
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
if ($ExtraArgs) {
    Write-Host "  WARNING: Stray arguments ignored: $($ExtraArgs -join ', ')" -ForegroundColor Yellow
}

$Protected = @('System','Idle','smss','csrss','wininit','winlogon','services','lsass','lsm',
    'svchost','dwm','explorer','spoolsv','SearchIndexer','SecurityHealthService','MsMpEng',
    'NisSrv','WmiPrvSE','dllhost','conhost','fontdrvhost','sihost','taskhostw',
    'RuntimeBroker','ShellExperienceHost','StartMenuExperienceHost','ctfmon',
    'Registry','Memory Compression','wuauserv','TrustedInstaller','WinDefend')

function Test-Protected([System.Diagnostics.Process]$P) {
    if ($P.Id -le 4) { return $true }
    if ($P.ProcessName -in $Protected) { return $true }
    if ($P.Path -and $P.Path -like "$env:SystemRoot\System32\*") {
        if ($P.ProcessName -notin @('node','dotnet','python','ruby','go','java','powershell','pwsh')) { return $true }
    }
    return $false
}

if ($PSCmdlet.ParameterSetName -eq 'ByPid') {
    Write-Host "  Looking up PID $ProcessId..." -ForegroundColor Cyan
    try { $proc = Get-Process -Id $ProcessId -ErrorAction Stop }
    catch { Write-Host "  No process with PID $ProcessId." -ForegroundColor Yellow; exit 1 }
    $mem = [math]::Round($proc.WorkingSet64 / 1MB, 1)
    Write-Host "  Found: $($proc.ProcessName) (PID $($proc.Id), ${mem}MB)"
    if (Test-Protected $proc) { Write-Host "  BLOCKED - critical process." -ForegroundColor Red; exit 1 }
    if (-not $Force) { Write-Host "  DRY RUN - add -Force to kill." -ForegroundColor Yellow; exit 0 }
    Stop-Process -Id $proc.Id -Force; Write-Host "  Stopped." -ForegroundColor Green; exit 0
}

# Port mode
Write-Host "  Checking port $Port..." -ForegroundColor Cyan
try { $conns = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue }
catch { Write-Host "  Port $Port is free." -ForegroundColor Green; exit 0 }
if (-not $conns) { Write-Host "  Port $Port is free." -ForegroundColor Green; exit 0 }

$pids = $conns | Select-Object -ExpandProperty OwningProcess -Unique
$procs = @()
foreach ($procId in $pids) {
    if ($procId -eq 0) { continue }
    try { $p = Get-Process -Id $procId -ErrorAction SilentlyContinue; if ($p) { $procs += $p } } catch {}
}
if ($procs.Count -eq 0) { Write-Host "  Port bound but process exited." -ForegroundColor Yellow; exit 0 }

if ($ProcessName) {
    $filtered = $procs | Where-Object { $_.ProcessName -like $ProcessName }
    if ($filtered.Count -eq 0) {
        Write-Host "  Port $Port in use but not by '$ProcessName'." -ForegroundColor Yellow; exit 0
    }
    $procs = @($filtered)
}

Write-Host "  Found $($procs.Count) process(es) on port ${Port}:" -ForegroundColor Yellow
foreach ($p in $procs) { Write-Host "    PID $($p.Id): $($p.ProcessName) ($([math]::Round($p.WorkingSet64/1MB,1))MB)" }

if (-not $Force) { Write-Host "`n  DRY RUN - add -Force to kill." -ForegroundColor Yellow; exit 0 }

$killed = 0
foreach ($p in $procs) {
    if (Test-Protected $p) { Write-Host "  SKIPPED - $($p.ProcessName) is protected." -ForegroundColor Red; continue }
    Stop-Process -Id $p.Id -Force; $killed++; Write-Host "  Stopped PID $($p.Id)." -ForegroundColor Green
}
Write-Host "`n  Done - stopped $killed process(es)." -ForegroundColor Green

