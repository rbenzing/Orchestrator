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
.EXAMPLE
    .claude\skills\orchestration-handoffs\scripts\handoff.ps1 -From "Researcher" -To "Architect" -ProjectName "user-auth" -Findings "OAuth 2.0 recommended"
.EXAMPLE
    .claude\skills\orchestration-handoffs\scripts\handoff.ps1 -From "Tester" -To "Developer" -ProjectName "user-auth" -IsFeedback -Issues "Login fails - Critical"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Orchestrator","Researcher","Architect","UI Designer","Planner","Developer","Developer Draft","Developer Verify","Code Reviewer","Tester","Tester Draft","Tester Verify","Planner Draft","Planner Verify")]
    [string]$From,
    [Parameter(Mandatory = $true)]
    [ValidateSet("Orchestrator","Researcher","Architect","UI Designer","Planner","Developer","Developer Draft","Developer Verify","Code Reviewer","Tester","Tester Draft","Tester Verify","Planner Draft","Planner Verify")]
    [string]$To,
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,
    [string]$ContractId = "",
    [string[]]$Findings = @(),
    [switch]$IsFeedback,
    [string[]]$Issues = @(),
    [ValidateSet("haiku","sonnet","opus")]
    [string]$ModelTier = "sonnet",
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
if ($ExtraArgs) {
    Write-Host "  WARNING: Stray arguments ignored: $($ExtraArgs -join ', ')" -ForegroundColor Yellow
}

# --- Agent metadata maps ---
$agentPhase = @{
    "Researcher"="research"; "Architect"="architecture"; "UI Designer"="ui-design"
    "Planner"="planning"; "Planner Draft"="planning"; "Planner Verify"="planning"
    "Developer"="development"; "Developer Draft"="development"; "Developer Verify"="development"
    "Code Reviewer"="reviews"
    "Tester"="testing"; "Tester Draft"="testing"; "Tester Verify"="testing"
}
$agentHandle = @{
    "Orchestrator"="@orchestrator"; "Researcher"="@researcher"; "Architect"="@architect"
    "UI Designer"="@ui-designer"
    "Planner"="@planner"; "Planner Draft"="@planner-draft"; "Planner Verify"="@planner-verify"
    "Developer"="@developer"; "Developer Draft"="@developer-draft"; "Developer Verify"="@developer-verify"
    "Code Reviewer"="@code-reviewer"
    "Tester"="@tester"; "Tester Draft"="@tester-draft"; "Tester Verify"="@tester-verify"
}
$agentArtifacts = @{
    "Researcher"=@(".claude/orchestrator/artifacts/$ProjectName/researcher/proposal.md",".claude/orchestrator/artifacts/$ProjectName/researcher/requirements.md")
    "Architect"=@(".claude/orchestrator/artifacts/$ProjectName/architect/architecture.md")
    "UI Designer"=@(".claude/orchestrator/artifacts/$ProjectName/ui-designer/ui-spec.md",".claude/orchestrator/artifacts/$ProjectName/ui-designer/design-system.md")
    "Planner"=@(".claude/orchestrator/artifacts/$ProjectName/planner/story-breakdown.md",".claude/orchestrator/artifacts/$ProjectName/planner/implementation-spec.md")
    "Planner Draft"=@(".claude/orchestrator/artifacts/$ProjectName/planner/story-breakdown.md",".claude/orchestrator/artifacts/$ProjectName/planner/implementation-spec.md")
    "Planner Verify"=@(".claude/orchestrator/artifacts/$ProjectName/planner/story-breakdown.md",".claude/orchestrator/artifacts/$ProjectName/planner/implementation-spec.md")
    "Developer"=@(".claude/orchestrator/artifacts/$ProjectName/developer/implementation-notes.md")
    "Developer Draft"=@(".claude/orchestrator/artifacts/$ProjectName/developer/implementation-notes.md")
    "Developer Verify"=@(".claude/orchestrator/artifacts/$ProjectName/developer/implementation-notes.md")
    "Code Reviewer"=@(".claude/orchestrator/artifacts/$ProjectName/code-reviewer/code-review-report.md")
    "Tester"=@(".claude/orchestrator/artifacts/$ProjectName/tester/test-results.md")
    "Tester Draft"=@(".claude/orchestrator/artifacts/$ProjectName/tester/test-results.md")
    "Tester Verify"=@(".claude/orchestrator/artifacts/$ProjectName/tester/test-results.md")
    "Orchestrator"=@()
}

# --- Auto-generate ContractId if not supplied ---
if (-not $ContractId) {
    $contractDir = Join-Path ".claude\orchestrator\contracts" $ProjectName
    $existing = 0
    if (Test-Path $contractDir) {
        $existing = (Get-ChildItem $contractDir -Filter "*.yml" | Measure-Object).Count
    }
    $next = $existing + 1
    $ContractId = "TSK-{0:D3}" -f $next
}

# --- Build contract parameters ---
$fromPhase = $agentPhase[$From]
$toHandle  = $agentHandle[$To]
$contractType = if ($IsFeedback) { "Feedback" } else { "Task" }

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

# Required reads for the receiving agent
$reads = $agentArtifacts[$From]

# --- Invoke new-contract.ps1 ---
$newContractScript = if ($env:CLAUDE_PLUGIN_ROOT) {
    Join-Path $env:CLAUDE_PLUGIN_ROOT "skills\orchestration-contracts\scripts\new-contract.ps1"
} else {
    Join-Path $PSScriptRoot "..\..\..\orchestration-contracts\scripts\new-contract.ps1"
}
$contractFile = & $newContractScript `
    -ProjectName       $ProjectName `
    -ContractId        $ContractId `
    -Type              $contractType `
    -AssignedAgent     $toHandle `
    -ModelTier         $ModelTier `
    -Objective         $objective `
    -RequiredReads     $reads `
    -IfPass            $ifPass `
    -IfFail            $ifFail

# --- Persist a human-readable handoff summary to the sender's artifact directory ---
$agentDir = @{
    "Researcher"="researcher"; "Architect"="architect"; "UI Designer"="ui-designer"
    "Planner"="planner"; "Planner Draft"="planner"; "Planner Verify"="planner"
    "Developer"="developer"; "Developer Draft"="developer"; "Developer Verify"="developer"
    "Code Reviewer"="code-reviewer"
    "Tester"="tester"; "Tester Draft"="tester"; "Tester Verify"="tester"
    "Orchestrator"="orchestrator"
}
$senderDir = if ($agentDir.ContainsKey($From)) { $agentDir[$From] } else { "orchestrator" }
$artifactDir = Join-Path (Get-Location).Path ".claude\orchestrator\artifacts\$ProjectName\$senderDir"
if (Test-Path $artifactDir) {
    $tag  = if ($IsFeedback) { "feedback" } else { "handoff" }
    $file = Join-Path $artifactDir "$tag-to-$($To -replace ' ','-').md"
    $summary = if ($IsFeedback) {
        "# Feedback to $To`n`nFrom: $From`nProject: $ProjectName`nContract: $ContractId`n`n## Issues`n" + ($Issues | ForEach-Object { "- $_" } | Out-String)
    } else {
        "# Handoff to $To`n`nFrom: $From`nProject: $ProjectName`nContract: $ContractId`n`n## Key Findings`n" + ($Findings | ForEach-Object { "- $_" } | Out-String)
    }
    $summary | Out-File -FilePath $file -Encoding utf8 -Force
    Write-Host "  Artifact persisted: $file" -ForegroundColor DarkGray
}

Write-Host ""
$color = if ($IsFeedback) { "Yellow" } else { "Cyan" }
Write-Host "  [$contractType] $From -> $To  |  Contract: $ContractId  |  Project: $ProjectName" -ForegroundColor $color
Write-Host "  Contract file: $contractFile" -ForegroundColor DarkGray
Write-Host ""

# Return contract ID for callers
Write-Output $ContractId

