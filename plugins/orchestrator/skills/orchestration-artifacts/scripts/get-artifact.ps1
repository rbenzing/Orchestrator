<#
.SYNOPSIS
    Read an artifact by contract ID, or list all artifacts for an agent.
.PARAMETER ProjectName
    Project identifier.
.PARAMETER Agent
    Agent role.
.PARAMETER ContractId
    Contract ID. If omitted, lists all .yml files in the agent's artifact dir.
.PARAMETER Field
    Optional. Extract only this top-level YAML field (saves tokens).
.EXAMPLE
    get-artifact.ps1 -ProjectName "user-auth" -Agent "researcher" -ContractId "TSK-001"
.EXAMPLE
    get-artifact.ps1 -ProjectName "user-auth" -Agent "researcher" -ContractId "TSK-001" -Field "goal"
.EXAMPLE
    get-artifact.ps1 -ProjectName "user-auth" -Agent "developer"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectName,
    [Parameter(Mandatory)]
    [ValidateSet("researcher","architect","ui-designer","planner","developer","code-reviewer","tester")]
    [string]$Agent,
    [string]$ContractId = "",
    [string]$Field = "",
    [string]$BasePath = ".claude/orchestrator/artifacts",
    [Parameter(ValueFromRemainingArguments=$true)][object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) { Write-Output "ERROR: unknown params: $($ExtraArgs -join ' '). Valid: -ProjectName -Agent -ContractId -Field -BasePath"; exit 1 }

# Resolve relative BasePath against the current working directory (target project root).
if (-not [System.IO.Path]::IsPathRooted($BasePath)) {
    $BasePath = Join-Path (Get-Location).Path $BasePath
}

$artifactDir = Join-Path $BasePath (Join-Path $ProjectName $Agent)

# List mode -- no ContractId, show all artifacts in agent dir
if (-not $ContractId) {
    if (-not (Test-Path $artifactDir)) {
        Write-Output "  No artifacts for $Agent in $ProjectName" -ForegroundColor DarkGray
        exit 0
    }
    $files = Get-ChildItem $artifactDir -Filter "*.yml" -ErrorAction SilentlyContinue
    if ($files.Count -eq 0) {
        Write-Output "  No artifacts for $Agent in $ProjectName" -ForegroundColor DarkGray
    } else {
        foreach ($f in $files) { Write-Output $f.Name }
    }
    exit 0
}

# Single artifact mode
$artifactPath = Join-Path $artifactDir "$ContractId.yml"
if (-not (Test-Path $artifactPath)) {
    Write-Output "ERROR: Artifact not found: $artifactPath"; exit 1
}

if (-not $Field) {
    Get-Content $artifactPath -Raw | Write-Output
    exit 0
}

# Extract specific field -- handles scalar, list, and multiline block values
$lines = Get-Content $artifactPath
$inField = $false
$result = @()

foreach ($line in $lines) {
    if ($line -match "^${Field}:\s*(.*)$") {
        $inField = $true
        $val = $Matches[1].Trim()
        if ($val -and $val -ne "|" -and $val -ne ">" -and $val -ne "[]") {
            Write-Output ($val -replace '^"(.*)"$','$1')
            exit 0
        }
        if ($val -eq "[]") {
            Write-Output "[]"
            exit 0
        }
        continue
    }
    if ($inField) {
        if ($line -match '^\S' -and $line -match ':') { break }
        $result += $line
    }
}

if ($result.Count -gt 0) {
    Write-Output ($result -join "`n")
} else {
    Write-Output "(empty)"
}