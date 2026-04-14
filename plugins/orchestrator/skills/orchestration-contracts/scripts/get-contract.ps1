<#
.SYNOPSIS
    Reads and displays the active contract for a given project and agent.
.DESCRIPTION
    Finds the most recent Open contract assigned to the specified agent
    under <cwd>/.claude/orchestrator/contracts/{ProjectName}/. Outputs the YAML
    content to stdout so the agent can parse its objective and required_reads.
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
    ${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\get-contract.ps1 `
      -ProjectName "user-auth" -AssignedAgent "@developer"
.EXAMPLE
    ${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\get-contract.ps1 `
      -ProjectName "user-auth" -ContractId "TSK-001" -Raw
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectName,
    [string]$ContractId = "",
    [string]$AssignedAgent = "",
    [switch]$Raw,
    [string]$BasePath = ".claude/orchestrator/contracts",
    [Parameter(ValueFromRemainingArguments)][object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) { Write-Output "ERROR: unknown params: $($ExtraArgs -join ' '). Valid: -ProjectName -ContractId -AssignedAgent -Raw -BasePath"; exit 1 }

# Resolve relative BasePath against the current working directory (target project root).
if (-not [System.IO.Path]::IsPathRooted($BasePath)) {
    $BasePath = Join-Path (Get-Location).Path $BasePath
}

$contractDir = Join-Path $BasePath $ProjectName
if (-not (Test-Path $contractDir)) {
    Write-Output "No contracts for $ProjectName"; exit 0
}

if ($ContractId) {
    $contractFile = Join-Path $contractDir "$ContractId.yml"
    if (-not (Test-Path $contractFile)) {
        Write-Output "ERROR: Contract not found: $contractFile"; exit 1
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
    Write-Output "No open contracts project=$ProjectName agent=$AssignedAgent"; exit 0
}

if ($Raw) { Write-Output $foundYaml; exit 0 }

# Output YAML directly -- agent parses it
Write-Output $foundYaml
Write-Output "contract=$($found.BaseName) file=$($found.FullName)"
