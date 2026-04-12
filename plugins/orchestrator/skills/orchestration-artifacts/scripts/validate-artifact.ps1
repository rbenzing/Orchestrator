<#
.SYNOPSIS
    Validate artifact(s) have all required fields populated.
.PARAMETER ProjectName
    Project identifier.
.PARAMETER Agent
    Agent role.
.PARAMETER ContractId
    Validate one artifact. If omitted, validates ALL .yml in agent dir.
.EXAMPLE
    validate-artifact.ps1 -ProjectName "auth" -Agent "researcher" -ContractId "TSK-001"
.EXAMPLE
    validate-artifact.ps1 -ProjectName "auth" -Agent "developer"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectName,
    [Parameter(Mandatory)]
    [ValidateSet("researcher","architect","ui-designer","planner","developer","code-reviewer","tester")]
    [string]$Agent,
    [string]$ContractId = "",
    [Parameter(ValueFromRemainingArguments=$true)][object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) { Write-Output "ERROR: unknown params: $($ExtraArgs -join ' '). Valid: -ProjectName -Agent -ContractId"; exit 1 }

$requiredFields = @{
    "researcher"    = @("goal","functional_reqs","non_functional_reqs","constraints","tech_stack")
    "architect"     = @("overview","components","data_model","decisions","directory_structure")
    "ui-designer"   = @("design_system","screens","flows","accessibility")
    "planner"       = @("implementation_order","stories")
    "developer"     = @("current_story","build_status","files_changed")
    "code-reviewer" = @("verdict","files_reviewed","summary")
    "tester"        = @("verdict","test_run","acceptance_criteria","summary")
}

$artifactDir = Join-Path "${CLAUDE_PLUGIN_ROOT}\artifacts" (Join-Path $ProjectName $Agent)

# Build list of files to validate
if ($ContractId) {
    $filesToCheck = @(Join-Path $artifactDir "$ContractId.yml")
    if (-not (Test-Path $filesToCheck[0])) {
        Write-Output "FAIL artifact not found: $($filesToCheck[0])"; exit 1
    }
} else {
    if (-not (Test-Path $artifactDir)) {
        Write-Output "FAIL no dir: $artifactDir"; exit 1
    }
    $filesToCheck = @(Get-ChildItem $artifactDir -Filter "*.yml" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    if ($filesToCheck.Count -eq 0) {
        Write-Output "FAIL no artifacts in $artifactDir"; exit 1
    }
}

$fields = $requiredFields[$Agent]
$allPassed = $true

foreach ($artifactPath in $filesToCheck) {
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($artifactPath)
    $lines = Get-Content $artifactPath
    $missing = @()
    $populated = @()

    # Parse file into field -> block content map
    $fieldBlocks = @{}
    $currentField = ""
    foreach ($line in $lines) {
        if ($line -match '^([a-z_]+):') {
            $currentField = $Matches[1]
            $fieldBlocks[$currentField] = @()
            $inlineVal = ($line -replace "^[a-z_]+:\s*", "").Trim()
            if ($inlineVal) { $fieldBlocks[$currentField] += $inlineVal }
        } elseif ($currentField -and $line -match '^\s') {
            $fieldBlocks[$currentField] += $line
        }
    }

    foreach ($f in $fields) {
        if (-not $fieldBlocks.ContainsKey($f)) { $missing += $f; continue }
        $hasContent = $false
        foreach ($bline in $fieldBlocks[$f]) {
            $t = $bline.Trim()
            if (-not $t) { continue }
            if ($t -match '^\s*#') { continue }
            if ($t -in @('[]','""','~','null','draft','pending','|','>')) { continue }
            if ($t -match '^[a-z_]+:\s*(\[\]|""|~|null)\s*$') { continue }
            $hasContent = $true; break
        }
        if ($hasContent) { $populated += $f } else { $missing += $f }
    }

    $total = $fields.Count; $ok = $populated.Count
    if ($missing.Count -gt 0) {
        Write-Output "FAIL $fileName $ok/$total missing=$($missing -join ',')"
        $allPassed = $false
    } else {
        Write-Output "PASS $fileName $ok/$total"
    }
}

if (-not $allPassed) { exit 1 }