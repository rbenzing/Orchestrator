<#
.SYNOPSIS
    Route the workflow to the next phase/agent based on project state.
.DESCRIPTION
    This script reads the current project state and updates the next phase
    and active agent according to orchestration rules, TDD feedback loops,
    and phase dependencies. Updates the state JSON for use by hooks and
    context-router.
#>

param(
    [string]$ProjectName = $(throw "ProjectName is required")
)

$ErrorActionPreference = "Stop"

$stateFile = ".claude/artifacts/$ProjectName.json"

if (-not (Test-Path $stateFile)) {
    Write-Error "State file not found: $stateFile"
    exit 1
}

# Load current state
$state = Get-Content $stateFile | ConvertFrom-Json

# Define phase → agent mapping
$phaseAgentMap = @{
    "discovery"        = "researcher"
    "planning"         = "architect"
    "test-authoring"   = "tester"
    "development"      = "developer"
    "code-review"      = "code-reviewer"
    "test-validation"  = "tester"
    "ui-design"        = "ui-designer"
    "deployment"       = "orchestrator"
}

# Define allowed phase order
$phaseOrder = @(
    "discovery",
    "planning",
    "test-authoring",
    "development",
    "code-review",
    "test-validation",
    "ui-design",
    "deployment"
)

$currentPhase = $state.phase
$currentAgent = $state.activeAgent

# TDD feedback loop for Tester, Developer, Code Reviewer
switch ($currentAgent) {

    "tester" {
        if ($currentPhase -eq "test-authoring") {
            $state.nextAgent = "developer"
            $state.phase = "development"
        }
        elseif ($currentPhase -eq "test-validation") {
            if ($state.testsPassed -eq $true) {
                $state.nextAgent = "orchestrator"
                $state.phase = "deployment"
            }
            else {
                $state.nextAgent = "developer"
                $state.phase = "development"
                $state.loop.iteration += 1
                $state.loop.status = "feedback"
            }
        }
    }

    "developer" {
        $state.nextAgent = "code-reviewer"
        $state.phase = "code-review"
    }

    "code-reviewer" {
        if ($state.reviewPassed -eq $true) {
            $state.nextAgent = "tester"
            $state.phase = "test-validation"
        }
        else {
            $state.nextAgent = "developer"
            $state.phase = "development"
            $state.loop.iteration += 1
        }
    }

    "researcher" {
        $state.nextAgent = "architect"
        $state.phase = "planning"
    }

    "architect" {
        $state.nextAgent = "tester"
        $state.phase = "test-authoring"
    }

    "ui-designer" {
        $state.nextAgent = "orchestrator"
        $state.phase = "deployment"
    }

    "orchestrator" {
        # End of workflow
        $state.nextAgent = $null
        $state.phase = "completed"
    }

    default {
        Write-Error "Unknown agent: $currentAgent"
        exit 1
    }
}

# Save updated state
$state | ConvertTo-Json -Depth 5 | Set-Content $stateFile

Write-Output "Routed to next phase: $($state.phase), active agent: $($state.nextAgent)"