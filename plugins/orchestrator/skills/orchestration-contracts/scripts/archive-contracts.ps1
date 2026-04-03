<#
.SYNOPSIS
    Archives Closed contracts to prevent file system and context bloat.
.DESCRIPTION
    Moves all Closed contracts for a project into an archive subfolder
    (.claude/orchestrator/contracts/{ProjectName}/archive/{date}/) so active contract
    directories stay small and readable.
.PARAMETER ProjectName
    Project identifier. Use "all" to archive across all projects.
.PARAMETER DryRun
    List what would be archived without moving anything.
.EXAMPLE
    .claude\skills\orchestration-contracts\scripts\archive-contracts.ps1 -ProjectName "user-auth"
.EXAMPLE
    .claude\skills\orchestration-contracts\scripts\archive-contracts.ps1 -ProjectName "all" -DryRun
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectName,
    [switch]$DryRun
)
$ErrorActionPreference = "Stop"

$baseDir = ".claude\orchestrator\contracts"
if (-not (Test-Path $baseDir)) {
    Write-Host "  [!] No contracts directory found." -ForegroundColor Yellow
    exit 0
}

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

    if ($closedFiles.Count -eq 0) {
        Write-Host "  [=] $proj -- no Closed contracts to archive." -ForegroundColor DarkGray
        continue
    }

    $archiveDir = Join-Path $projDir "archive\$dateLabel"
    if (-not $DryRun -and -not (Test-Path $archiveDir)) {
        New-Item -Path $archiveDir -ItemType Directory -Force | Out-Null
    }

    foreach ($f in $closedFiles) {
        $dest = Join-Path $archiveDir $f.Name
        if ($DryRun) {
            Write-Host "  [DRY] Would archive: $($f.FullName)  ->  $dest" -ForegroundColor DarkYellow
        } else {
            Move-Item -Path $f.FullName -Destination $dest -Force
            Write-Host "  [>] Archived: $($f.Name)  ->  archive\$dateLabel\" -ForegroundColor Green
            $totalMoved++
        }
    }
}

Write-Host ""
if ($DryRun) {
    Write-Host "  [DRY RUN complete -- no files moved]" -ForegroundColor DarkYellow
} else {
    Write-Host "  Archive complete. $totalMoved contract(s) moved." -ForegroundColor Cyan
}
Write-Host ""

