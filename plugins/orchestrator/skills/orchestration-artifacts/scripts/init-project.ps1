<#
.SYNOPSIS
    Initialize the artifact directory tree for a project.
.DESCRIPTION
    Creates the standard orchestration artifact directory structure for a named
    project. Artifacts are stored per-agent under .claude/orchestrator/artifacts/{project}/{agent}/.
    Includes directories for researcher, architect, ui-designer, planner,
    developer, code-reviewer, and tester agents.
.PARAMETER ProjectName
    Project identifier. Must start with a letter, may contain letters, numbers,
    dots, underscores, and hyphens (e.g. "user-auth", "my_app.v2").
.PARAMETER BasePath
    Root path for artifacts. Default: .claude/orchestrator/artifacts
.EXAMPLE
    .claude\skills\orchestration-artifacts\scripts\init-project.ps1 -ProjectName "user-auth"
.EXAMPLE
    .claude\skills\orchestration-artifacts\scripts\init-project.ps1 -ProjectName "dashboard.v2" -BasePath ".claude/orchestrator/artifacts"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-zA-Z][a-zA-Z0-9._-]*$')]
    [string]$ProjectName,
    [string]$BasePath = ".claude/orchestrator/artifacts",
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
if ($ExtraArgs) {
    Write-Host "  WARNING: Stray arguments ignored: $($ExtraArgs -join ', ')" -ForegroundColor Yellow
    Write-Host "  Usage: .claude\skills\orchestration-artifacts\scripts\init-project.ps1 -ProjectName ""my-project""" -ForegroundColor Yellow
}

# Agent directories — artifacts/{project}/{agent}/
$agents = @(
    @{ Dir = "researcher";     Files = @("proposal.md","requirements.md","technical-constraints.md","specs") }
    @{ Dir = "architect";      Files = @("architecture.md","decisions") }
    @{ Dir = "ui-designer";    Files = @("ui-spec.md","design-system.md","accessibility.md","flows") }
    @{ Dir = "planner";        Files = @("design.md","implementation-spec.md","story-breakdown.md") }
    @{ Dir = "developer";      Files = @("implementation-notes.md","build-logs.txt") }
    @{ Dir = "code-reviewer";  Files = @("code-review-report.md") }
    @{ Dir = "tester";         Files = @("test-results.md","test-coverage.md") }
)

Write-Host "  Initializing artifacts for: $ProjectName" -ForegroundColor Cyan
Write-Host "  Base path: $BasePath\$ProjectName\{agent}\" -ForegroundColor DarkGray
Write-Host ""

$created = 0
foreach ($agent in $agents) {
    $agentDir = Join-Path $BasePath (Join-Path $ProjectName $agent.Dir)
    if (-not (Test-Path $agentDir)) {
        New-Item -Path $agentDir -ItemType Directory -Force | Out-Null
        $created++
        Write-Host "  [+] $agentDir" -ForegroundColor Green
    } else {
        Write-Host "  [=] $agentDir (exists)" -ForegroundColor DarkGray
    }

    foreach ($file in $agent.Files) {
        $filePath = Join-Path $agentDir $file
        # If it looks like a directory (no extension), create as directory
        if ($file -notmatch '\.') {
            if (-not (Test-Path $filePath)) {
                New-Item -Path $filePath -ItemType Directory -Force | Out-Null
                Write-Host "      [+] $file/" -ForegroundColor Green
                $created++
            }
        } else {
            if (-not (Test-Path $filePath)) {
                New-Item -Path $filePath -ItemType File -Force | Out-Null
                Write-Host "      [+] $file" -ForegroundColor Green
                $created++
            }
        }
    }
}

# Create state directory
$stateDir = Join-Path ".claude\orchestrator\state" $ProjectName
if (-not (Test-Path $stateDir)) {
    New-Item -Path $stateDir -ItemType Directory -Force | Out-Null
    $created++
    Write-Host "  [+] $stateDir (workflow state)" -ForegroundColor Green
} else {
    Write-Host "  [=] $stateDir (exists)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "  Done. Created $created new items." -ForegroundColor Cyan

