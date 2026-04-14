<#
.SYNOPSIS
    Show artifact completion dashboard for a project.
.DESCRIPTION
    Displays a compact overview of which phases have artifacts present,
    how many are found vs expected, and overall project progress.
.PARAMETER ProjectName
    Project identifier (e.g. "user-auth").
.PARAMETER Root
    Repository root. Defaults to current directory.
.EXAMPLE
    ${CLAUDE_PLUGIN_ROOT}\skills\orchestration-artifacts\scripts\artifact-status.ps1 -ProjectName "user-auth"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,
    [string]$Root = (Get-Location).Path,
    [string]$BasePath = ".claude/orchestrator/artifacts",
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) { Write-Output "ERROR: unknown params: $($ExtraArgs -join ' '). Valid: -ProjectName -Root -BasePath"; exit 1 }

# Resolve relative BasePath against -Root (target project root).
if (-not [System.IO.Path]::IsPathRooted($BasePath)) {
    $base = Join-Path $Root $BasePath
} else {
    $base = $BasePath
}
$agents = @("researcher","architect","ui-designer","planner","developer","code-reviewer","tester")
$totalArtifacts = 0

foreach ($agent in $agents) {
    $agentDir = Join-Path $base (Join-Path $ProjectName $agent)
    if (-not (Test-Path $agentDir)) { continue }
    $files = Get-ChildItem $agentDir -Filter "*.yml" -ErrorAction SilentlyContinue
    $count = if ($files) { $files.Count } else { 0 }
    $totalArtifacts += $count
    if ($count -gt 0) {
        $names = ($files | ForEach-Object { $_.BaseName }) -join ","
        Write-Output "$agent $count ($names)"
    }
}

Write-Output "total=$totalArtifacts"
