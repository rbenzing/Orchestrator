<#
.SYNOPSIS
    PostCompact hook - surfaces orchestration state immediately after compaction.
    Claude reads this RESUME POINT to continue the workflow without manual intervention.
#>
$ErrorActionPreference = "SilentlyContinue"

try {
    $stateRoot = Join-Path (Get-Location).Path ".claude\state"
    if (-not (Test-Path $stateRoot)) { exit 0 }

    $stateFiles = Get-ChildItem -Path $stateRoot -Filter "orchestrator-state.yml" -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending

    if (-not $stateFiles -or $stateFiles.Count -eq 0) { exit 0 }

    Write-Output ""
    Write-Output "=== POST-COMPACTION RESUME POINT ==="
    Write-Output "Context was compacted. Resume orchestration from the state below."
    Write-Output ""

    foreach ($file in $stateFiles) {
        $project  = $file.Directory.Name
        $yaml     = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $yaml) { continue }

        # Extract key fields with regex
        $phase    = ([regex]::Match($yaml, '(?m)^phase:\s*(.+)$')).Groups[1].Value.Trim()
        $agent    = ([regex]::Match($yaml, '(?m)^agent:\s*(.+)$')).Groups[1].Value.Trim()
        $contract = ([regex]::Match($yaml, '(?m)^contract:\s*(.+)$')).Groups[1].Value.Trim()
        $router   = ([regex]::Match($yaml, '(?m)^router_phase:\s*(.+)$')).Groups[1].Value.Trim()
        $next     = ([regex]::Match($yaml, '(?m)^next:\s*"?(.+?)"?$')).Groups[1].Value.Trim()
        $story    = ([regex]::Match($yaml, '(?m)^story:\s*"?(.+?)"?$')).Groups[1].Value.Trim()
        $saved    = ([regex]::Match($yaml, '(?m)^saved:\s*"?(.+?)"?$')).Groups[1].Value.Trim()

        Write-Output "Project      : $project"
        Write-Output "Phase        : $phase"
        Write-Output "Active Agent : $agent"
        if ($contract -and $contract -ne '""' -and $contract -ne '') {
            Write-Output "Contract     : $contract"
        }
        if ($router -and $router -ne '') {
            Write-Output "Router Phase : $router"
        }
        if ($story -and $story -ne '""' -and $story -ne '') {
            Write-Output "Story        : $story"
        }
        Write-Output "Next Action  : $next"
        Write-Output "State Saved  : $saved"
        Write-Output ""
        Write-Output "INSTRUCTION: You are in Orchestrator mode. Execute NextAction above."
        Write-Output "Do NOT ask the user for confirmation - resume autonomously."
        Write-Output ""
    }

    Write-Output "=== END RESUME POINT ==="
    exit 0
}
catch {
    exit 0
}
