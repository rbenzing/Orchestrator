<#
.SYNOPSIS
    Speculative Draft + Verify harness for cost-optimized contract execution.
.DESCRIPTION
    Manages the draft artifact workspace for a contract running the Draft+Verify
    pattern. Provides path resolution, artifact promotion (draft → final), and
    result recording. Called by agents after both draft and verify phases complete.

    Flow:
      1. Agent (as draft_model/Haiku) writes artifacts to draft dir
      2. Agent (as draft_verify_model/Sonnet) reads draft, checks acceptance criteria
      3. Agent calls this script with -Result pass|fix and optional -FailedCriteria
      4. Script promotes artifacts (copy draft → final agent dir on pass, or records
         that verifier already wrote to final dir on fix), updates contract YAML.

.PARAMETER ProjectName
    Project identifier (e.g. "user-auth").
.PARAMETER ContractId
    Contract ID being processed (e.g. "TSK-003").
.PARAMETER AgentDir
    Agent artifact directory name (e.g. "developer", "tester", "planner").
.PARAMETER Result
    Outcome of the verify phase: "pass" (draft promoted as-is) or "fix" (verifier
    rewrote failing sections directly to the final agent dir).
.PARAMETER FailedCriteria
    Array of acceptance criteria strings that failed the draft check. Only used
    when Result="fix" — recorded in draft_notes for audit trail.
.PARAMETER Root
    Repository root. Defaults to current working directory.
.EXAMPLE
    # Draft passed — promote artifacts unchanged
    draft-verify.ps1 -ProjectName "user-auth" -ContractId "TSK-003" -AgentDir "developer" -Result "pass"
.EXAMPLE
    # Draft had issues — verifier fixed them, record which criteria failed
    draft-verify.ps1 -ProjectName "user-auth" -ContractId "TSK-003" -AgentDir "tester" -Result "fix" `
        -FailedCriteria "All edge cases covered","Error paths tested"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectName,
    [Parameter(Mandatory)][string]$ContractId,
    [Parameter(Mandatory)][string]$AgentDir,
    [Parameter(Mandatory)][ValidateSet("pass","fix")][string]$Result,
    [string[]]$FailedCriteria = @(),
    [string]$Root = (Get-Location).Path,
    [Parameter(ValueFromRemainingArguments)][object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
if ($ExtraArgs) { Write-Host "  WARNING: Stray arguments ignored: $($ExtraArgs -join ', ')" -ForegroundColor Yellow }

$artifactBase = Join-Path $Root ".claude\orchestrator\artifacts"
$draftDir     = Join-Path $artifactBase "draft\$ProjectName\$ContractId"
$finalDir     = Join-Path $artifactBase "$ProjectName\$AgentDir"
$contractFile = Join-Path $Root ".claude\orchestrator\contracts\$ProjectName\$ContractId.yml"

# -- Banner ------------------------------------------------------------------
Write-Host ""
Write-Host "  +-- Draft + Verify Harness ------------------------------------+" -ForegroundColor Magenta
Write-Host "  |  Contract : $ContractId" -ForegroundColor White
Write-Host "  |  Project  : $ProjectName" -ForegroundColor White
Write-Host "  |  Agent    : $AgentDir" -ForegroundColor White
Write-Host "  |  Result   : $Result" -ForegroundColor $(if ($Result -eq "pass") { "Green" } else { "Yellow" })

# -- Validate draft dir exists -----------------------------------------------
if (-not (Test-Path $draftDir)) {
    Write-Host "  |  ERROR: Draft dir not found: $draftDir" -ForegroundColor Red
    Write-Host "  |  Ensure the draft phase wrote artifacts there before calling this script." -ForegroundColor Red
    Write-Host "  +---------------------------------------------------------------+" -ForegroundColor Magenta
    exit 1
}

# -- On pass: promote draft artifacts to final agent dir ---------------------
if ($Result -eq "pass") {
    Write-Host "  |  Promoting draft artifacts to final dir..." -ForegroundColor Green

    if (-not (Test-Path $finalDir)) {
        New-Item -Path $finalDir -ItemType Directory -Force | Out-Null
    }

    $draftFiles = Get-ChildItem -Path $draftDir -File -Recurse -ErrorAction SilentlyContinue
    $promoted = 0
    foreach ($file in $draftFiles) {
        $relative  = $file.FullName.Substring($draftDir.Length).TrimStart('\','/')
        $targetPath = Join-Path $finalDir $relative
        $targetParent = Split-Path $targetPath -Parent
        if (-not (Test-Path $targetParent)) {
            New-Item -Path $targetParent -ItemType Directory -Force | Out-Null
        }
        Copy-Item -Path $file.FullName -Destination $targetPath -Force
        Write-Host "  |    [+] $relative" -ForegroundColor DarkGray
        $promoted++
    }
    Write-Host "  |  Promoted $promoted file(s) from draft to final." -ForegroundColor Green
    $costNote = "draft-passed (~30% cost vs full Sonnet run)"
} else {
    # fix: verifier already wrote corrected artifacts to final dir
    Write-Host "  |  Fix mode - verifier wrote corrected artifacts to final dir." -ForegroundColor Yellow
    if ($FailedCriteria.Count -gt 0) {
        Write-Host "  |  Failed criteria:" -ForegroundColor Yellow
        foreach ($c in $FailedCriteria) {
            Write-Host "  |    - $c" -ForegroundColor DarkGray
        }
    }
    $costNote = "draft-fixed (~110% cost vs full Sonnet run)"
}

# -- Update contract YAML with draft result ----------------------------------
if (-not (Test-Path $contractFile)) {
    Write-Host "  |  WARNING: Contract file not found, skipping YAML update: $contractFile" -ForegroundColor Yellow
} else {
    $yaml = Get-Content $contractFile -Raw -Encoding UTF8

    # Build draft_notes value
    $notesValue = if ($Result -eq "fix" -and $FailedCriteria.Count -gt 0) {
        "Verifier fixed: $($FailedCriteria -join '; ')"
    } elseif ($Result -eq "pass") {
        "Draft accepted by verifier without changes."
    } else {
        "Draft fixed by verifier."
    }

    # Update draft_result field
    if ($yaml -match '(?m)^draft_result:') {
        $yaml = $yaml -replace '(?m)^draft_result:\s*.*', "draft_result: $Result"
    } else {
        $yaml = $yaml.TrimEnd() + "`ndraft_result: $Result`n"
    }

    # Update draft_notes field
    if ($yaml -match '(?m)^draft_notes:') {
        $yaml = $yaml -replace '(?m)^draft_notes:\s*("([^"]|\\")*"|[^\r\n]*)', "draft_notes: `"$notesValue`""
    } else {
        $yaml = $yaml.TrimEnd() + "`ndraft_notes: `"$notesValue`"`n"
    }

    Set-Content -Path $contractFile -Value $yaml -Encoding UTF8
    Write-Host "  |  Contract updated: draft_result=$Result" -ForegroundColor Cyan
}

Write-Host "  |  Cost estimate: $costNote" -ForegroundColor DarkGray
Write-Host "  +---------------------------------------------------------------+" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Next: run check-gate.ps1 against final artifacts in:" -ForegroundColor White
Write-Host "    $finalDir" -ForegroundColor Cyan
Write-Host ""
