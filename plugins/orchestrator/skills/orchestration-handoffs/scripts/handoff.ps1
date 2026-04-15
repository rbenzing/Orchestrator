<#
.SYNOPSIS
    Create a YAML task contract for the next agent in the workflow.
.DESCRIPTION
    Wraps new-contract.ps1 to generate a structured handoff between agents.
    Forward handoffs create Task or Validation contracts; feedback loops create
    Feedback contracts that include issue traces so agents never lose retry context.
    A human-readable summary is also persisted as a legacy artifact.
.PARAMETER From
    The agent completing its phase.
.PARAMETER To
    The agent receiving the handoff.
.PARAMETER ProjectName
    The project identifier (e.g. "user-auth").
.PARAMETER ContractId
    Override the auto-generated contract ID (default: auto-incremented TSK-NNN).
.PARAMETER Findings
    Key findings or decisions to include in the contract objective.
.PARAMETER IsFeedback
    Generate a Feedback contract instead of a forward handoff.
.PARAMETER Issues
    Issues for feedback contracts. Format: "Description - Severity"
.PARAMETER ModelTier
    LLM tier for the receiving agent: haiku | sonnet | opus. Default: sonnet.
.PARAMETER Effort
    Reasoning effort for the receiving agent: low | medium | high | max. Default: medium.
.EXAMPLE
    ${CLAUDE_PLUGIN_ROOT}\skills\orchestration-handoffs\scripts\handoff.ps1 -From "Researcher" -To "Architect" -ProjectName "user-auth" -Findings "OAuth 2.0 recommended"
.EXAMPLE
    ${CLAUDE_PLUGIN_ROOT}\skills\orchestration-handoffs\scripts\handoff.ps1 -From "Tester" -To "Developer" -ProjectName "user-auth" -IsFeedback -Issues "Login fails - Critical"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Orchestrator","Researcher","Architect","UI Designer","Planner","Developer","Code Reviewer","Tester")]
    [string]$From,
    [Parameter(Mandatory = $true)]
    [ValidateSet("Orchestrator","Researcher","Architect","UI Designer","Planner","Developer","Code Reviewer","Tester")]
    [string]$To,
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,
    [string]$ContractId = "",
    [string[]]$Findings = @(),
    [switch]$IsFeedback,
    [string[]]$Issues = @(),
    [ValidateSet("haiku","sonnet","opus")]
    [string]$ModelTier = "sonnet",
    [ValidateSet("low","medium","high","max")]
    [string]$Effort = "medium",
    [string]$ArtifactBase = ".claude/orchestrator/artifacts",
    [string]$ContractBase = ".claude/orchestrator/contracts",
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) { Write-Output "ERROR: unknown params: $($ExtraArgs -join ' '). Valid: -From -To -ProjectName -ContractId -IsFeedback -Issues -ModelTier -Effort -ArtifactBase -ContractBase"; exit 1 }

# Resolve relative base paths against the current working directory (target project root).
if (-not [System.IO.Path]::IsPathRooted($ArtifactBase)) {
    $ArtifactBase = Join-Path (Get-Location).Path $ArtifactBase
}
if (-not [System.IO.Path]::IsPathRooted($ContractBase)) {
    $ContractBase = Join-Path (Get-Location).Path $ContractBase
}

# --- Agent metadata maps ---
$agentHandle = @{
    "Orchestrator"="@orchestrator"; "Researcher"="@researcher"; "Architect"="@architect"
    "UI Designer"="@ui-designer"; "Planner"="@planner"; "Developer"="@developer"
    "Code Reviewer"="@code-reviewer"; "Tester"="@tester"
}

# Resolve tier-specific handle: append -haiku or -opus suffix for non-orchestrator agents
function Resolve-TieredHandle {
    param([string]$BaseHandle, [string]$Tier)
    if ($BaseHandle -eq "@orchestrator") { return $BaseHandle }
    switch ($Tier) {
        "haiku" { return "$BaseHandle-haiku" }
        "opus"  { return "$BaseHandle-opus"  }
        default { return $BaseHandle }   # sonnet = base agent, no suffix
    }
}
# Dynamic artifact discovery -- scan agent dir for all .yml files
$agentDirMap = @{
    "Researcher"="researcher"; "Architect"="architect"; "UI Designer"="ui-designer"
    "Planner"="planner"; "Developer"="developer"; "Code Reviewer"="code-reviewer"
    "Tester"="tester"; "Orchestrator"="orchestrator"
}
function Get-AgentArtifactList($AgentName) {
    $dir = $agentDirMap[$AgentName]
    if (-not $dir) { return @() }
    $artifactDir = Join-Path $ArtifactBase (Join-Path $ProjectName $dir)
    if (-not (Test-Path $artifactDir)) { return @() }
    $files = Get-ChildItem $artifactDir -Filter "*.yml" -ErrorAction SilentlyContinue
    if (-not $files) { return @() }
    return @($files | ForEach-Object { $_.FullName })
}

# --- Auto-generate ContractId if not supplied ---
if (-not $ContractId) {
    $contractDir = Join-Path $ContractBase $ProjectName
    $existing = 0
    if (Test-Path $contractDir) {
        $existing = (Get-ChildItem $contractDir -Filter "*.yml" | Measure-Object).Count
    }
    $next = $existing + 1
    $ContractId = "TSK-{0:D3}" -f $next
}

# --- Build contract parameters ---
$toHandle  = Resolve-TieredHandle -BaseHandle $agentHandle[$To] -Tier $ModelTier
$contractType = if ($IsFeedback) { "Feedback" } elseif ($To -eq "Tester") { "Validation" } else { "Task" }

# Build objective text
if ($IsFeedback) {
    $issueList = ($Issues | ForEach-Object { "  - $_" }) -join "`n"
    $objective = "$From phase returned issues. $To must address all issues and resubmit.`nIssues:`n$issueList"
    $ifPass    = "Return to $From for re-review"
    $ifFail    = "Escalate to Orchestrator after 3 attempts"
} else {
    $findingsList = if ($Findings.Count -gt 0) { ($Findings | ForEach-Object { "  - $_" }) -join "`n" } else { "  (none specified)" }
    $objective = "$From phase complete for $ProjectName. $To to proceed with next phase.`nFindings:`n$findingsList"
    $ifPass    = "Advance to next phase per Router"
    $ifFail    = "Return to Router with Feedback Contract"
}

# Required reads -- discover all artifacts from the sending agent
$reads = Get-AgentArtifactList $From

# --- Invoke new-contract.ps1 ---
$newContractScript = "${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\new-contract.ps1"
& $newContractScript `
    -ProjectName       $ProjectName `
    -ContractId        $ContractId `
    -Type              $contractType `
    -AssignedAgent     $toHandle `
    -ModelTier         $ModelTier `
    -Effort            $Effort `
    -Objective         $objective `
    -RequiredReads     $reads `
    -IfPass            $ifPass `
    -IfFail            $ifFail `
    -BasePath          $ContractBase

# Handoff data lives in the YAML contract -- no duplicate .md summary needed

Write-Output "handoff $contractType $From->$To $ContractId"
Write-Output $ContractId
