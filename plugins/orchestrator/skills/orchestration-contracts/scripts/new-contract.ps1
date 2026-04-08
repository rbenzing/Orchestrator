<#
.SYNOPSIS
    Creates a new YAML contract file for a task assignment.
.DESCRIPTION
    Generates a structured YAML contract under .claude/orchestrator/contracts/{ProjectName}/
    following the Contract-Router YAML schema.
.PARAMETER ProjectName
    Project identifier (e.g. "user-auth").
.PARAMETER ContractId
    Unique ID for this contract (e.g. "TSK-001").
.PARAMETER Type
    Contract type: Project | Story | Task | TDD-Red | TDD-Green | TDD-Refactor | Feedback | Validation
.PARAMETER AssignedAgent
    The agent this contract is assigned to (e.g. "@developer").
.PARAMETER ModelTier
    LLM tier: haiku | sonnet | opus. Default: sonnet.
.PARAMETER Objective
    1-2 sentence description of the contract goal.
.PARAMETER Deliverables
    Array of file paths or path:symbol pairs the agent must produce.
.PARAMETER AcceptanceCriteria
    Array of pass/fail criteria strings the check-gate reads.
.PARAMETER RequiredReads
    Array of file paths the agent must read before starting.
.PARAMETER Dependencies
    Array of contract IDs that must be Closed before this one can be dispatched.
.PARAMETER ParentContract
    ID of the parent contract (Project or Story level).
.PARAMETER IfPass
    Routing instruction if the contract passes: next agent or phase.
.PARAMETER IfFail
    Routing instruction if the contract fails.
.EXAMPLE
    .claude\skills\orchestration-contracts\scripts\new-contract.ps1 `
      -ProjectName "user-auth" -ContractId "TSK-001" -Type "Task" `
      -AssignedAgent "@developer" -Objective "Implement JWT login endpoint." `
      -Deliverables "src/auth/login.ts","tests/auth/login.test.ts" `
      -AcceptanceCriteria "All unit tests pass","check-gate passes"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectName,
    [Parameter(Mandatory)][string]$ContractId,
    [Parameter(Mandatory)][ValidateSet("Project","Story","Task","TDD-Red","TDD-Green","TDD-Refactor","Feedback","Validation")][string]$Type,
    [Parameter(Mandatory)][string]$AssignedAgent,
    [ValidateSet("haiku","sonnet","opus")][string]$ModelTier = "sonnet",
    [switch]$DraftEnabled,
    [string]$DraftModel = "claude-haiku-4-5-20251001",
    [Parameter(Mandatory)][string]$Objective,
    [string[]]$Deliverables = @(),
    [string[]]$AcceptanceCriteria = @(),
    [string[]]$RequiredReads = @(),
    [string[]]$Dependencies = @(),
    [string]$ParentContract = "",
    [string]$IfPass = "Return to Router",
    [string]$IfFail = "Return to Router with Feedback Contract"
)
$ErrorActionPreference = "Stop"

# Auto-enable draft for eligible types on first-attempt Sonnet contracts
$draftEligibleTypes = @("TDD-Red","TDD-Green","Task")
if (-not $DraftEnabled -and ($draftEligibleTypes -contains $Type) -and ($ModelTier -eq "sonnet")) {
    $DraftEnabled = $true
}
# Never draft on escalated or non-Sonnet contracts
if ($ModelTier -ne "sonnet") { $DraftEnabled = $false }

$draftEnabledStr = if ($DraftEnabled) { "true" } else { "false" }

$contractDir = Join-Path ".claude\orchestrator\contracts" $ProjectName
if (-not (Test-Path $contractDir)) {
    New-Item -Path $contractDir -ItemType Directory -Force | Out-Null
}

$contractFile = Join-Path $contractDir "$ContractId.yml"

# Build YAML list sections
function Format-YamlList {
    param([string[]]$Items, [string]$Indent = "  ")
    if (-not $Items -or $Items.Count -eq 0) { return "${Indent}[]" }
    return ($Items | ForEach-Object { "${Indent}- `"$($_.Trim())`"" }) -join "`n"
}

$depsYaml      = Format-YamlList $Dependencies
$readsYaml     = Format-YamlList $RequiredReads
$deliverablesYaml = Format-YamlList $Deliverables
$criteriaYaml  = Format-YamlList $AcceptanceCriteria
$parentLine    = if ($ParentContract) { $ParentContract } else { "~" }
$timestamp     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$yaml = @"
# Contract: $ContractId
# Generated: $timestamp
id: "$ContractId"
project: "$ProjectName"
parent_contract: $parentLine
type: "$Type"
assigned_agent: "$AssignedAgent"
model_tier: "$ModelTier"
status: "Open"
dependencies:
$depsYaml
attempt_count: 1
max_attempts: 3
created_at: "$timestamp"
updated_at: "$timestamp"

objective: |
  $Objective

required_reads:
$readsYaml

deliverables:
$deliverablesYaml

acceptance_criteria:
$criteriaYaml

execution_history: []

next_routing:
  if_pass: "$IfPass"
  if_fail: "$IfFail"

draft_enabled: $draftEnabledStr
draft_model: "$DraftModel"
draft_result: "pending"
draft_notes: ""
"@

Set-Content -Path $contractFile -Value $yaml -Encoding UTF8
Write-Host ""
Write-Host "  [+] Contract created: $contractFile" -ForegroundColor Green
$draftLabel = if ($DraftEnabled) { " | Draft+Verify: ON" } else { "" }
Write-Host "      Type: $Type | Agent: $AssignedAgent | Model: $ModelTier$draftLabel" -ForegroundColor White
Write-Host "      Status: Open" -ForegroundColor Cyan
Write-Host ""
# Output the file path so callers can capture it
Write-Output $contractFile

