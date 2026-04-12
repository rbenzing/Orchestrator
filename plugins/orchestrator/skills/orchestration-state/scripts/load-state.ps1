<#
.SYNOPSIS
    Load orchestrator workflow state from disk.
.DESCRIPTION
    Reads the persisted orchestration state file for a project. Used to recover
    workflow position after context compaction. Outputs the full state file
    contents so the orchestrator can resume from where it left off.

    If called WITHOUT -ProjectName, discovers all projects with saved state
    and lists them so the orchestrator can pick the right one.
.PARAMETER ProjectName
    Project identifier (e.g. "user-auth"). Optional -- omit to discover all projects.
.PARAMETER Root
    Repository root. Defaults to current directory.
.EXAMPLE
    ${CLAUDE_PLUGIN_ROOT}\skills\orchestration-state\scripts\load-state.ps1 -ProjectName "user-auth"
.EXAMPLE
    ${CLAUDE_PLUGIN_ROOT}\skills\orchestration-state\scripts\load-state.ps1
#>
[CmdletBinding()]
param(
    [string]$ProjectName,
    [string]$Root = (Get-Location).Path,
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) { Write-Host "ERROR: unknown params: $($ExtraArgs -join ' '). Valid: -ProjectName -Root"; exit 1 }

# --- Discovery mode: no ProjectName given ---
$stateRoot = Join-Path $Root "${CLAUDE_PLUGIN_ROOT}\state"
if (-not $ProjectName) {
    if (-not (Test-Path $stateRoot)) {
        Write-Host "No state directory found"; exit 1
    }
    $found = @()
    Get-ChildItem -Path $stateRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $sf = Join-Path $_.FullName "orchestrator-state.yml"
        if (Test-Path $sf) {
            $found += [PSCustomObject]@{ Name = $_.Name; Saved = (Get-Item $sf).LastWriteTime.ToString("yyyy-MM-dd HH:mm") }
        }
    }
    if ($found.Count -eq 0) { Write-Host "No state files found"; exit 1 }
    foreach ($p in $found) { Write-Host "$($p.Name) (saved: $($p.Saved))" }
    if ($found.Count -eq 1) {
        $ProjectName = $found[0].Name
        Write-Host "Auto-loading: $ProjectName"
    } else {
        Write-Host "Re-run with -ProjectName"; exit 1
    }
}

$stateFile = Join-Path $stateRoot (Join-Path $ProjectName "orchestrator-state.yml")

if (-not (Test-Path $stateFile)) {
    Write-Host "No state for '$ProjectName'. Run save-state.ps1 first."
    exit 1
}

# Output state content directly -- agent parses YAML
Get-Content -Path $stateFile -Encoding UTF8 -Raw | Write-Host

# Append contract-router summary
$stateContent = Get-Content -Path $stateFile -Encoding UTF8 -Raw
$cid = ([regex]::Match($stateContent, '(?m)^active_contract_id:\s*"?([^"\r\n]+)"?')).Groups[1].Value.Trim()
$rp  = ([regex]::Match($stateContent, '(?m)^router_phase:\s*"?([^"\r\n]+)"?')).Groups[1].Value.Trim()
if ($cid) {
    $contractFile = Join-Path "${CLAUDE_PLUGIN_ROOT}\contracts" (Join-Path $ProjectName "$cid.yml")
    $exists = if (Test-Path $contractFile) { "exists" } else { "missing" }
    Write-Host "contract=$cid ($exists) phase=$rp"
}
