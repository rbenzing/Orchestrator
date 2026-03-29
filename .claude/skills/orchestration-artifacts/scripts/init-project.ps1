<#
.SYNOPSIS
    Initialize the artifact directory tree for a project.
.DESCRIPTION
    Creates the standard orchestration artifact directory structure for a named
    project. Includes research, architecture, ui-design, planning, development,
    reviews, and testing phase directories.
.PARAMETER ProjectName
    Project identifier. Must start with a letter, may contain letters, numbers,
    dots, underscores, and hyphens (e.g. "user-auth", "my_app.v2").
.PARAMETER BasePath
    Root path for artifacts. Default: orchestration/artifacts
.EXAMPLE
    .claude\skills\orchestration-artifacts\scripts\init-project.ps1 -ProjectName "user-auth"
.EXAMPLE
    .claude\skills\orchestration-artifacts\scripts\init-project.ps1 -ProjectName "dashboard.v2" -BasePath "artifacts"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-zA-Z][a-zA-Z0-9._-]*$')]
    [string]$ProjectName,
    [string]$BasePath = "orchestration/artifacts",
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
if ($ExtraArgs) {
    Write-Host "  WARNING: Stray arguments ignored: $($ExtraArgs -join ', ')" -ForegroundColor Yellow
    Write-Host "  Usage: .claude\skills\orchestration-artifacts\scripts\init-project.ps1 -ProjectName ""my-project""" -ForegroundColor Yellow
}

$phases = @(
    @{ Dir = "research";     Files = @("proposal.md","requirements.md","technical-constraints.md","specs") }
    @{ Dir = "architecture"; Files = @("architecture.md","decisions") }
    @{ Dir = "ui-design";    Files = @("ui-spec.md","design-system.md","accessibility.md","flows") }
    @{ Dir = "planning";     Files = @("design.md","implementation-spec.md","story-breakdown.md") }
    @{ Dir = "development";  Files = @("implementation-notes.md","build-logs.txt") }
    @{ Dir = "reviews";      Files = @("code-review-report.md") }
    @{ Dir = "testing";      Files = @("test-results.md","test-coverage.md") }
)

Write-Host "  Initializing artifacts for: $ProjectName" -ForegroundColor Cyan
Write-Host "  Base path: $BasePath" -ForegroundColor DarkGray
Write-Host ""

$created = 0
foreach ($phase in $phases) {
    $phaseDir = Join-Path $BasePath (Join-Path $phase.Dir $ProjectName)
    if (-not (Test-Path $phaseDir)) {
        New-Item -Path $phaseDir -ItemType Directory -Force | Out-Null
        $created++
        Write-Host "  [+] $phaseDir" -ForegroundColor Green
    } else {
        Write-Host "  [=] $phaseDir (exists)" -ForegroundColor DarkGray
    }

    foreach ($file in $phase.Files) {
        $filePath = Join-Path $phaseDir $file
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
$stateDir = Join-Path "orchestration" (Join-Path "state" $ProjectName)
if (-not (Test-Path $stateDir)) {
    New-Item -Path $stateDir -ItemType Directory -Force | Out-Null
    $created++
    Write-Host "  [+] $stateDir (workflow state)" -ForegroundColor Green
} else {
    Write-Host "  [=] $stateDir (exists)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "  Done. Created $created new items." -ForegroundColor Cyan

