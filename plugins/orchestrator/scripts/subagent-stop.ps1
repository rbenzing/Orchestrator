<#
.SYNOPSIS
    SubagentStop hook — signals subagent completion to the orchestrator.
    Reads the active contract to surface what was expected, reminding the
    orchestrator to check artifacts and update the contract status.
#>
$ErrorActionPreference = "SilentlyContinue"

try {
    $stateRoot = Join-Path (Get-Location).Path ".claude\state"
    if (-not (Test-Path $stateRoot)) { exit 0 }

    $stateFile = Get-ChildItem -Path $stateRoot -Filter "orchestrator-state.yml" -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $stateFile) { exit 0 }

    $yaml = Get-Content $stateFile.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $yaml) { exit 0 }

    $phase    = ([regex]::Match($yaml, '(?m)^phase:\s*(.+)$')).Groups[1].Value.Trim()
    if ($phase -eq 'complete') { exit 0 }

    $project  = $stateFile.Directory.Name
    $agent    = ([regex]::Match($yaml, '(?m)^agent:\s*(.+)$')).Groups[1].Value.Trim()
    $contract = ([regex]::Match($yaml, '(?m)^contract:\s*(.+)$')).Groups[1].Value.Trim()

    Write-Output ""
    Write-Output "=== SUBAGENT COMPLETED ==="
    Write-Output "Project : $project  |  Phase: $phase  |  Agent: $agent"
    if ($contract -and $contract -ne '""' -and $contract -ne '') {
        Write-Output "Contract: $contract"
        Write-Output ""
        Write-Output "ORCHESTRATOR ACTION REQUIRED:"
        Write-Output "  1. Review subagent output and artifacts in .claude\artifacts\$project\"
        Write-Output "  2. Update contract status: update-contract.ps1 -ProjectName ""$project"" -ContractId ""$contract"" -Status ""Closed"""
        Write-Output "  3. Save state and dispatch next contract per the routing table."
    }
    Write-Output "=== END SUBAGENT SIGNAL ==="
    exit 0
}
catch {
    exit 0
}
