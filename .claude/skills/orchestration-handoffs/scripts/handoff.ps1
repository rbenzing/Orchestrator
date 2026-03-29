<#
.SYNOPSIS
    Generate a standardized handoff or feedback message between agents.
.DESCRIPTION
    Creates a formatted handoff message with auto-populated artifact paths.
    Supports forward handoffs and feedback loops (rejections/bug reports).
.PARAMETER From
    The agent completing its phase.
.PARAMETER To
    The agent receiving the handoff.
.PARAMETER ProjectName
    The project identifier (e.g. "user-auth").
.PARAMETER Findings
    Key findings or decisions to include. Comma-separated strings.
.PARAMETER IsFeedback
    Generate a feedback/rejection message instead of a forward handoff.
.PARAMETER Issues
    Issues for feedback messages. Format: "Description - Severity"
.EXAMPLE
    .claude\skills\orchestration-handoffs\scripts\handoff.ps1 -From "Researcher" -To "Architect" -ProjectName "user-auth" -Findings "OAuth 2.0 recommended"
.EXAMPLE
    .claude\skills\orchestration-handoffs\scripts\handoff.ps1 -From "Tester" -To "Developer" -ProjectName "user-auth" -IsFeedback -Issues "Login fails - Critical"
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
    [string[]]$Findings = @(),
    [switch]$IsFeedback,
    [string[]]$Issues = @(),
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
if ($ExtraArgs) {
    Write-Host "  WARNING: Stray arguments ignored: $($ExtraArgs -join ', ')" -ForegroundColor Yellow
}

$agentPhase = @{
    "Researcher"="research"; "Architect"="architecture"; "UI Designer"="ui-design"
    "Planner"="planning"; "Developer"="development"; "Code Reviewer"="reviews"; "Tester"="testing"
}
$agentArtifacts = @{
    "Researcher"=@("proposal.md","requirements.md","technical-constraints.md","specs/scenarios.md")
    "Architect"=@("architecture.md","decisions/")
    "UI Designer"=@("ui-spec.md","design-system.md","accessibility.md","flows/")
    "Planner"=@("design.md","implementation-spec.md","story-breakdown.md")
    "Developer"=@("implementation-notes.md","build-logs.txt")
    "Code Reviewer"=@("code-review-report.md")
    "Tester"=@("test-results.md","test-coverage.md")
}

$phase = $agentPhase[$From]
$label = ($phase -replace '-',' ').ToUpper()
$base = "/.claude/artifacts/$phase/$ProjectName"

if ($IsFeedback) {
    $msg = "FEEDBACK FOR $($To.ToUpper())`n`n$label STATUS: Changes Required`n`nISSUES:"
    $i = 1; foreach ($issue in $Issues) { $msg += "`n$i. $issue"; $i++ }
    $msg += "`n`nARTIFACTS:"
    foreach ($f in $agentArtifacts[$From]) { $msg += "`n- $base/$f" }
    $msg += "`n`nPLEASE ADDRESS:`n- All critical issues before re-submission`n- All major issues before re-submission`n- Minor notes do NOT block approval`n`nREADY FOR RE-REVIEW: After fixes applied"
} else {
    $msg = "HANDOFF TO $($To.ToUpper())`n`n$label COMPLETE: $ProjectName`n`nARTIFACTS:"
    foreach ($f in $agentArtifacts[$From]) { $msg += "`n- $base/$f" }
    $msg += "`n`nKEY FINDINGS / DECISIONS:"
    if ($Findings.Count -eq 0) { $msg += "`n- (none specified)" }
    else { foreach ($f in $Findings) { $msg += "`n- $f" } }
    $next = ($agentPhase[$To] -replace '-',' ').ToUpper()
    $msg += "`n`nREADY FOR ${next}: Yes"
}

# Persist to disk so the message survives context compaction
$artifactDir = Join-Path (Get-Location).Path ".claude/artifacts/$phase/$ProjectName"
if (Test-Path $artifactDir) {
    $tag = if ($IsFeedback) { "feedback" } else { "handoff" }
    $file = Join-Path $artifactDir "$tag-to-$($To -replace ' ','-').md"
    $msg | Out-File -FilePath $file -Encoding utf8 -Force
    Write-Host "  Persisted to: $file" -ForegroundColor DarkGray
}

Write-Host $msg
Write-Host "`n--- Handoff message generated ---" -ForegroundColor DarkGray

