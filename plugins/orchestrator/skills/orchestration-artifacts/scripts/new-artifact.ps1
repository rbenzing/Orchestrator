<#
.SYNOPSIS
    Create a new artifact from template for a specific agent and contract.
.PARAMETER ProjectName
    Project identifier.
.PARAMETER Agent
    Agent role: researcher|architect|ui-designer|planner|developer|code-reviewer|tester
.PARAMETER ContractId
    Contract ID (e.g. TSK-001). Used as filename: {agent}/{ContractId}.yml
.PARAMETER Force
    Overwrite existing artifact with fresh template.
.EXAMPLE
    new-artifact.ps1 -ProjectName "user-auth" -Agent "researcher" -ContractId "TSK-001"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectName,
    [Parameter(Mandatory)]
    [ValidateSet("researcher","architect","ui-designer","planner","developer","code-reviewer","tester")]
    [string]$Agent,
    [Parameter(Mandatory)][string]$ContractId,
    [string]$BasePath = "${CLAUDE_PLUGIN_ROOT}/artifacts",
    [switch]$Force,
    [Parameter(ValueFromRemainingArguments=$true)][object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) { Write-Output "ERROR: unknown params: $($ExtraArgs -join ' '). Valid: -ProjectName -Agent -ContractId -BasePath -Force"; exit 1 }

$templateMap = @{
    "researcher"    = "requirements.yml"
    "architect"     = "architecture.yml"
    "ui-designer"   = "ui-spec.yml"
    "planner"       = "stories.yml"
    "developer"     = "dev-log.yml"
    "code-reviewer" = "review.yml"
    "tester"        = "test-results.yml"
}

$templateName = $templateMap[$Agent]
$templateDir  = "${CLAUDE_PLUGIN_ROOT}\skills\orchestration-artifacts\templates"
$templatePath = Join-Path $templateDir $templateName

if (-not (Test-Path $templatePath)) {
    Write-Error "Template not found: $templatePath"
    exit 1
}

$artifactDir = Join-Path $BasePath (Join-Path $ProjectName $Agent)
if (-not (Test-Path $artifactDir)) {
    New-Item -Path $artifactDir -ItemType Directory -Force | Out-Null
}

$destPath = Join-Path $artifactDir "$ContractId.yml"
if ((Test-Path $destPath) -and -not $Force) {
    Write-Output "  [=] Artifact exists: $destPath (use -Force to overwrite)" -ForegroundColor Yellow
    Write-Output $destPath
    exit 0
}

$content = Get-Content $templatePath -Raw
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$content = $content -replace 'project: ""', "project: `"$ProjectName`""
$content = $content -replace 'updated_at: ""', "updated_at: `"$timestamp`""
# Stamp contract_id into the artifact if the template has the field
if ($content -match 'contract_id: ""') {
    $content = $content -replace 'contract_id: ""', "contract_id: `"$ContractId`""
}

Set-Content -Path $destPath -Value $content -Encoding UTF8
Write-Output "  [+] Artifact created: $destPath" -ForegroundColor Green
Write-Output $destPath