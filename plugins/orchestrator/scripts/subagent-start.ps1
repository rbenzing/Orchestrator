<#
.SYNOPSIS
    SubagentStart hook - injects orchestration context into subagent invocations.
    Subagents receive project/phase/contract context automatically, reducing
    the token cost of re-explaining context in every Agent tool prompt.
#>
$ErrorActionPreference = "SilentlyContinue"

try {
    $stateRoot = Join-Path (Get-Location).Path ".claude\orchestrator\state"
    if (-not (Test-Path $stateRoot)) { exit 0 }

    $stateFile = Get-ChildItem -Path $stateRoot -Filter "orchestrator-state.yml" -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $stateFile) { exit 0 }

    $yaml = Get-Content $stateFile.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $yaml) { exit 0 }

    $phase = ([regex]::Match($yaml, '(?m)^phase:\s*(.+)$')).Groups[1].Value.Trim()
    if ($phase -eq 'complete') { exit 0 }

    $project  = $stateFile.Directory.Name
    $agent    = ([regex]::Match($yaml, '(?m)^agent:\s*(.+)$')).Groups[1].Value.Trim()
    $contract = ([regex]::Match($yaml, '(?m)^contract:\s*(.+)$')).Groups[1].Value.Trim()
    $story    = ([regex]::Match($yaml, '(?m)^story:\s*"?(.+?)"?$')).Groups[1].Value.Trim()
    $next     = ([regex]::Match($yaml, '(?m)^next:\s*"?(.+?)"?$')).Groups[1].Value.Trim()

    Write-Output ""
    Write-Output "=== SUBAGENT CONTEXT (injected by orchestration hook) ==="
    Write-Output "You are a subagent operating within an orchestrated workflow."
    Write-Output "Project      : $project"
    Write-Output "Phase        : $phase"
    Write-Output "Dispatching  : $agent"
    if ($contract -and $contract -ne '""' -and $contract -ne '') {
        Write-Output "Contract     : $contract"
        Write-Output "Contract path: .claude\orchestrator\contracts\$project\$contract.yml"
    }
    if ($story -and $story -ne '""' -and $story -ne '') {
        Write-Output "Story        : $story"
    }
    Write-Output "Context      : $next"
    Write-Output ""
    Write-Output "Read your assigned contract before starting work."
    Write-Output "Write all output artifacts to .claude\orchestrator\artifacts\$project\<agent-role>\"
    Write-Output "=== END SUBAGENT CONTEXT ==="
    exit 0
}
catch {
    exit 0
}
