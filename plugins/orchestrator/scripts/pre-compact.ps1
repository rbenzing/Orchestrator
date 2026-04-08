<#
.SYNOPSIS
    PreCompact hook - injects orchestration state into the compaction context.
    Claude includes this in the summary so workflow position survives.
#>
$ErrorActionPreference = "SilentlyContinue"

try {
    $stateRoot = Join-Path (Get-Location).Path ".claude\orchestrator\state"
    if (-not (Test-Path $stateRoot)) { exit 0 }

    $stateFiles = Get-ChildItem -Path $stateRoot -Filter "orchestrator-state.yml" -Recurse -ErrorAction SilentlyContinue
    if (-not $stateFiles -or $stateFiles.Count -eq 0) { exit 0 }

    $blocks = @()
    foreach ($file in $stateFiles) {
        $project = $file.Directory.Name
        $yaml = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($yaml) {
            $blocks += "--- Project: $project ---`n$($yaml.Trim())"
        }
    }
    if ($blocks.Count -eq 0) { exit 0 }

    Write-Output ""
    Write-Output "=== ORCHESTRATION STATE SNAPSHOT (PreCompact) ==="
    Write-Output "CRITICAL: Preserve these fields in the compaction summary to enable workflow resume."
    Write-Output ""
    Write-Output ($blocks -join "`n`n")
    Write-Output ""
    Write-Output "=== END ORCHESTRATION STATE SNAPSHOT ==="
    exit 0
}
catch {
    exit 0
}
