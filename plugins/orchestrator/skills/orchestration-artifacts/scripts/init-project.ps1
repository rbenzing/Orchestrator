<#
.SYNOPSIS
    Initialize the artifact directory tree for a project.
.DESCRIPTION
    Creates the standard orchestration artifact directory structure for a named
    project. Artifacts are stored per-agent under
    <cwd>/.claude/orchestrator/artifacts/{project}/{agent}/ where <cwd> is the
    target project's root directory (NOT the orchestrator plugin install dir).
    Includes directories for researcher, architect, ui-designer, planner,
    developer, code-reviewer, and tester agents.
.PARAMETER ProjectName
    Project identifier. Must start with a letter, may contain letters, numbers,
    dots, underscores, and hyphens (e.g. "user-auth", "my_app.v2").
.PARAMETER BasePath
    Root path for artifacts. Default: ".claude/orchestrator/artifacts" (resolved
    against the current working directory = target project root).
.EXAMPLE
    ${CLAUDE_PLUGIN_ROOT}\skills\orchestration-artifacts\scripts\init-project.ps1 -ProjectName "user-auth"
.EXAMPLE
    ${CLAUDE_PLUGIN_ROOT}\skills\orchestration-artifacts\scripts\init-project.ps1 -ProjectName "dashboard.v2" -BasePath "D:/work/myapp/.claude/orchestrator/artifacts"
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
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) { Write-Output "ERROR: unknown params: $($ExtraArgs -join ' '). Valid: -ProjectName -BasePath"; exit 1 }

# Resolve relative BasePath against the current working directory (target project root).
if (-not [System.IO.Path]::IsPathRooted($BasePath)) {
    $BasePath = Join-Path (Get-Location).Path $BasePath
}

# Sanity guard: refuse to write artifacts inside the orchestrator plugin install dir.
# Artifacts are per-project state; they must live in the TARGET project, not the plugin.
$normalized = $BasePath -replace '\\', '/'
if ($normalized -match '/plugins/orchestrator/') {
    Write-Output "ERROR: refusing to write artifacts under the orchestrator plugin dir ($BasePath)."
    Write-Output "Run /start from the target project's root directory, not from the Orchestrator repo."
    exit 1
}

$agents = @("researcher","architect","ui-designer","planner","developer","code-reviewer","tester")

$created = 0
foreach ($agent in $agents) {
    $agentDir = Join-Path $BasePath (Join-Path $ProjectName $agent)
    if (-not (Test-Path $agentDir)) {
        New-Item -Path $agentDir -ItemType Directory -Force | Out-Null
        $created++
    }
}

# State lives next to artifacts in the target project: .claude/orchestrator/state/{project}/
$stateBase = Join-Path (Split-Path $BasePath -Parent) "state"
$stateDir = Join-Path $stateBase $ProjectName
if (-not (Test-Path $stateDir)) {
    New-Item -Path $stateDir -ItemType Directory -Force | Out-Null
    $created++
}

Write-Output "init $ProjectName created=$created base=$BasePath"
