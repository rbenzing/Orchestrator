<#
.SYNOPSIS
    SessionStart hook — discovers active orchestration projects at session start.
    Surfaces workflow state so Claude can resume without a manual load-state call.
#>
$ErrorActionPreference = "SilentlyContinue"

try {
    $stateRoot = Join-Path (Get-Location).Path ".claude\orchestrator\state"
    if (-not (Test-Path $stateRoot)) { exit 0 }

    $stateFiles = Get-ChildItem -Path $stateRoot -Filter "orchestrator-state.yml" -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending

    if (-not $stateFiles -or $stateFiles.Count -eq 0) { exit 0 }

    # Filter out completed projects
    $activeFiles = @()
    foreach ($file in $stateFiles) {
        $yaml = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($yaml -and $yaml -notmatch '(?m)^phase:\s*complete') {
            $activeFiles += $file
        }
    }

    if ($activeFiles.Count -eq 0) { exit 0 }

    Write-Output ""
    Write-Output "=== ORCHESTRATION: ACTIVE PROJECTS DETECTED ==="

    foreach ($file in $activeFiles) {
        $project  = $file.Directory.Name
        $yaml     = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $yaml) { continue }

        $phase    = ([regex]::Match($yaml, '(?m)^phase:\s*(.+)$')).Groups[1].Value.Trim()
        $agent    = ([regex]::Match($yaml, '(?m)^agent:\s*(.+)$')).Groups[1].Value.Trim()
        $contract = ([regex]::Match($yaml, '(?m)^contract:\s*(.+)$')).Groups[1].Value.Trim()
        $next     = ([regex]::Match($yaml, '(?m)^next:\s*"?(.+?)"?$')).Groups[1].Value.Trim()
        $saved    = ([regex]::Match($yaml, '(?m)^saved:\s*"?(.+?)"?$')).Groups[1].Value.Trim()

        Write-Output ""
        Write-Output "  Project : $project"
        Write-Output "  Phase   : $phase  |  Agent: $agent"
        if ($contract -and $contract -ne '""' -and $contract -ne '') {
            Write-Output "  Contract: $contract"
        }
        Write-Output "  Next    : $next"
        Write-Output "  Saved   : $saved"
    }

    Write-Output ""
    if ($activeFiles.Count -eq 1) {
        $p = $activeFiles[0].Directory.Name
        Write-Output "  Orchestrator: type 'orchestrator' to resume project '$p' autonomously."
    } else {
        Write-Output "  Orchestrator: type 'orchestrator' and specify which project to resume."
    }
    Write-Output "=== END ACTIVE PROJECTS ==="
    exit 0
}
catch {
    exit 0
}
