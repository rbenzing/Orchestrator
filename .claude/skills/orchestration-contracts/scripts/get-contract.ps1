<#
.SYNOPSIS
    Reads and displays the active contract for a given project and agent.
.DESCRIPTION
    Finds the most recent Open contract assigned to the specified agent
    under .claude/contracts/{ProjectName}/. Outputs the YAML content
    to stdout so the agent can parse its objective and required_reads.
.PARAMETER ProjectName
    Project identifier.
.PARAMETER ContractId
    Specific contract ID to read (optional). If omitted, returns the first
    Open contract for the assigned agent.
.PARAMETER AssignedAgent
    Filter by agent name (e.g. "@developer"). Used when ContractId is omitted.
.PARAMETER Raw
    If set, output raw YAML. Otherwise prints a formatted summary.
.EXAMPLE
    .claude\skills\orchestration-contracts\scripts\get-contract.ps1 `
      -ProjectName "user-auth" -AssignedAgent "@developer"
.EXAMPLE
    .claude\skills\orchestration-contracts\scripts\get-contract.ps1 `
      -ProjectName "user-auth" -ContractId "TSK-001" -Raw
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectName,
    [string]$ContractId = "",
    [string]$AssignedAgent = "",
    [switch]$Raw
)
$ErrorActionPreference = "Stop"

$contractDir = Join-Path ".claude\contracts" $ProjectName
if (-not (Test-Path $contractDir)) {
    Write-Host "  [!] No contracts directory found for project: $ProjectName" -ForegroundColor Yellow
    exit 0
}

if ($ContractId) {
    $contractFile = Join-Path $contractDir "$ContractId.yml"
    if (-not (Test-Path $contractFile)) {
        Write-Error "Contract not found: $contractFile"
        exit 1
    }
    $files = @(Get-Item $contractFile)
} else {
    $files = Get-ChildItem $contractDir -Filter "*.yml" | Sort-Object Name
}

$found = $null
foreach ($f in $files) {
    $yaml = Get-Content $f.FullName -Raw
    $isOpen   = $yaml -match 'status:\s*"Open"'
    $isAgent  = (-not $AssignedAgent) -or ($yaml -match [regex]::Escape($AssignedAgent))
    if ($isOpen -and $isAgent) {
        $found = $f
        $foundYaml = $yaml
        break
    }
}

if (-not $found) {
    Write-Host ""
    Write-Host "  [=] No open contracts found for: ProjectName=$ProjectName Agent=$AssignedAgent" -ForegroundColor DarkGray
    Write-Host ""
    exit 0
}

if ($Raw) {
    Write-Output $foundYaml
    exit 0
}

# Pretty summary
Write-Host ""
Write-Host "  +-- Contract: $($found.BaseName) -----------------------------------------" -ForegroundColor Cyan
$foundYaml -split "`n" | ForEach-Object { Write-Host "  |  $_" -ForegroundColor White }
Write-Host "  +----------------------------------------------------------" -ForegroundColor Cyan
Write-Host ""

# Output file path for callers
Write-Output $found.FullName

