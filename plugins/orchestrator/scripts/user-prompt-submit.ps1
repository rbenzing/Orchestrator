<#
.SYNOPSIS
    UserPromptSubmit hook - prepends a compact orchestration context line to each prompt.
    Eliminates ambient context loss between turns without reading full state files.
#>
$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

try {
    $stateRoot = Join-Path (Get-Location).Path ".claude\orchestrator\state"
    if (-not (Test-Path $stateRoot)) { exit 0 }

    # Find the most recently modified active state file
    $stateFile = Get-ChildItem -Path $stateRoot -Filter "orchestrator-state.yml" -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $stateFile) { exit 0 }

    $yaml = Get-Content $stateFile.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $yaml) { exit 0 }

    $phase = ([regex]::Match($yaml, '(?m)^phase:\s*(.+)$')).Groups[1].Value.Trim()

    # Skip injection for completed projects - no noise when done
    if ($phase -eq 'complete') { exit 0 }

    $project  = $stateFile.Directory.Name
    $agent    = ([regex]::Match($yaml, '(?m)^agent:\s*(.+)$')).Groups[1].Value.Trim()
    $contract = ([regex]::Match($yaml, '(?m)^contract:\s*(.+)$')).Groups[1].Value.Trim()
    $router   = ([regex]::Match($yaml, '(?m)^router_phase:\s*(.+)$')).Groups[1].Value.Trim()
    $next     = ([regex]::Match($yaml, '(?m)^next:\s*"?(.+?)"?$')).Groups[1].Value.Trim()

    $contextParts = @("PROJECT:$project", "PHASE:$phase", "AGENT:$agent")
    if ($contract -and $contract -ne '""' -and $contract -ne '') {
        $contextParts += "CONTRACT:$contract"
    }
    if ($router -and $router -ne '') {
        $contextParts += "ROUTER:$router"
    }

    $contextLine = "[ORCH | $($contextParts -join ' | ')]"
    if ($next -and $next -ne '""' -and $next -ne '') {
        $contextLine += "`n[NEXT: $next]"
    }

    Write-Output $contextLine
    exit 0
}
catch {
    exit 0
}
