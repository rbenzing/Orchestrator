<#
.SYNOPSIS
    Archives Closed contracts to prevent file system and context bloat.
.DESCRIPTION
    Moves all Closed contracts for a project into an archive subfolder
    (<cwd>/.claude/orchestrator/contracts/{ProjectName}/archive/{date}/) so
    active contract directories stay small and readable.
.PARAMETER ProjectName
    Project identifier. Use "all" to archive across all projects.
.PARAMETER DryRun
    List what would be archived without moving anything.
.EXAMPLE
    ${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\archive-contracts.ps1 -ProjectName "user-auth"
.EXAMPLE
    ${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\archive-contracts.ps1 -ProjectName "all" -DryRun
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectName,
    [switch]$DryRun,
    [string]$BasePath = ".claude/orchestrator/contracts",
    [Parameter(ValueFromRemainingArguments)][object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) { Write-Output "ERROR: unknown params: $($ExtraArgs -join ' '). Valid: -ProjectName -DryRun -BasePath"; exit 1 }

# Resolve relative BasePath against the current working directory (target project root).
if (-not [System.IO.Path]::IsPathRooted($BasePath)) {
    $BasePath = Join-Path (Get-Location).Path $BasePath
}

$baseDir = $BasePath
if (-not (Test-Path $baseDir)) { Write-Output "No contracts dir"; exit 0 }

# Determine which projects to process
if ($ProjectName -eq "all") {
    $projects = Get-ChildItem $baseDir -Directory | Select-Object -ExpandProperty Name
} else {
    $projects = @($ProjectName)
}

$dateLabel = Get-Date -Format "yyyy-MM-dd"
$totalMoved = 0

foreach ($proj in $projects) {
    $projDir = Join-Path $baseDir $proj
    if (-not (Test-Path $projDir)) { continue }

    $closedFiles = Get-ChildItem $projDir -Filter "*.yml" | Where-Object {
        $yaml = Get-Content $_.FullName -Raw
        $yaml -match 'status:\s*"Closed"'
    }

    if ($closedFiles.Count -eq 0) { continue }

    $archiveDir = Join-Path $projDir "archive\$dateLabel"
    if (-not $DryRun -and -not (Test-Path $archiveDir)) {
        New-Item -Path $archiveDir -ItemType Directory -Force | Out-Null
    }

    foreach ($f in $closedFiles) {
        $dest = Join-Path $archiveDir $f.Name
        if ($DryRun) { Write-Output "DRY $($f.Name) -> archive/$dateLabel" }
        else {
            Move-Item -Path $f.FullName -Destination $dest -Force
            $totalMoved++
        }
    }
}

Write-Output "archived=$totalMoved$(if ($DryRun) { ' (dry-run)' })"
