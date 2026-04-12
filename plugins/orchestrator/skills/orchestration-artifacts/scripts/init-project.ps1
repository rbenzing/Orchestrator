<#
.SYNOPSIS
    Initialize the artifact directory tree for a project.
.DESCRIPTION
    Creates the standard orchestration artifact directory structure for a named
    project. Artifacts are stored per-agent under ${CLAUDE_PLUGIN_ROOT}/artifacts/{project}/{agent}/.
    Includes directories for researcher, architect, ui-designer, planner,
    developer, code-reviewer, and tester agents.
.PARAMETER ProjectName
    Project identifier. Must start with a letter, may contain letters, numbers,
    dots, underscores, and hyphens (e.g. "user-auth", "my_app.v2").
.PARAMETER BasePath
    Root path for artifacts. Default: ${CLAUDE_PLUGIN_ROOT}/artifacts
.EXAMPLE
    ${CLAUDE_PLUGIN_ROOT}\skills\orchestration-artifacts\scripts\init-project.ps1 -ProjectName "user-auth"
.EXAMPLE
    ${CLAUDE_PLUGIN_ROOT}\skills\orchestration-artifacts\scripts\init-project.ps1 -ProjectName "dashboard.v2" -BasePath "${CLAUDE_PLUGIN_ROOT}/artifacts"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-zA-Z][a-zA-Z0-9._-]*$')]
    [string]$ProjectName,
    [string]$BasePath = "${CLAUDE_PLUGIN_ROOT}/artifacts",
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) { Write-Host "ERROR: unknown params: $($ExtraArgs -join ' '). Valid: -ProjectName -BasePath"; exit 1 }

$agents = @("researcher","architect","ui-designer","planner","developer","code-reviewer","tester")

$created = 0
foreach ($agent in $agents) {
    $agentDir = Join-Path $BasePath (Join-Path $ProjectName $agent)
    if (-not (Test-Path $agentDir)) {
        New-Item -Path $agentDir -ItemType Directory -Force | Out-Null
        $created++
    }
}

$stateDir = Join-Path "${CLAUDE_PLUGIN_ROOT}\state" $ProjectName
if (-not (Test-Path $stateDir)) {
    New-Item -Path $stateDir -ItemType Directory -Force | Out-Null
    $created++
}

Write-Host "init $ProjectName created=$created"
