<#
.SYNOPSIS
    Transitions a contract's status and appends an execution history entry.
.DESCRIPTION
    Updates the status field of a YAML contract file. When moving to Blocked
    or Feedback, increments attempt_count. Appends an execution_history entry
    with the error trace so agents never lose retry context.
.PARAMETER ProjectName
    Project identifier matching the directory under ${CLAUDE_PLUGIN_ROOT}/contracts/.
.PARAMETER ContractId
    ID of the contract to update (e.g. "TSK-001").
.PARAMETER Status
    New status: Open | Blocked | Review | Closed
.PARAMETER Notes
    Optional notes to append to execution_history (e.g. error message on failure).
.PARAMETER ErrorTrace
    Short error trace or check-gate failure message (included in history).
.PARAMETER FailedRef
    File path that caused the failure, for quick reference.
.EXAMPLE
    ${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\update-contract.ps1 `
      -ProjectName "user-auth" -ContractId "TSK-001" -Status "Closed"
.EXAMPLE
    ${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\update-contract.ps1 `
      -ProjectName "user-auth" -ContractId "TSK-001" -Status "Blocked" `
      -ErrorTrace "check-gate failed: 3/4 tests passed" -FailedRef "src/auth/login.ts"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectName,
    [Parameter(Mandatory)][string]$ContractId,
    [Parameter(Mandatory)][ValidateSet("Open","Blocked","Review","Closed")][string]$Status,
    [string]$Notes = "",
    [string]$ErrorTrace = "",
    [string]$FailedRef = "",
    [Parameter(ValueFromRemainingArguments)][object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) { Write-Output "ERROR: unknown params: $($ExtraArgs -join ' '). Valid: -ProjectName -ContractId -Status -Notes -ErrorTrace -FailedRef"; exit 1 }

$contractFile = Join-Path "${CLAUDE_PLUGIN_ROOT}\contracts" (Join-Path $ProjectName "$ContractId.yml")
if (-not (Test-Path $contractFile)) {
    Write-Error "Contract not found: $contractFile"
    exit 1
}

$content = Get-Content $contractFile -Raw
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Update status field
$content = $content -replace '(?m)^status: ".*"', "status: `"$Status`""

# Update updated_at
$content = $content -replace '(?m)^updated_at: ".*"', "updated_at: `"$timestamp`""

# Increment attempt_count when blocking/failing
if ($Status -in @("Blocked")) {
    $match = [regex]::Match($content, 'attempt_count:\s*(\d+)')
    if ($match.Success) {
        $current = [int]$match.Groups[1].Value
        $next = $current + 1
        $content = $content -replace 'attempt_count:\s*\d+', "attempt_count: $next"
    }
}

# Append execution history entry
if ($ErrorTrace -or $Notes) {
    # Find existing attempt count for the history entry label
    $attemptMatch = [regex]::Match($content, 'attempt_count:\s*(\d+)')
    $attemptNum = if ($attemptMatch.Success) { $attemptMatch.Groups[1].Value } else { "1" }
    $noteLine    = if ($Notes)      { "`n    notes: `"$Notes`""             } else { "" }
    $refLine     = if ($FailedRef) { "`n    failed_code_ref: `"$FailedRef`"" } else { "" }
    $histEntry = @"

  - attempt: $attemptNum
    timestamp: "$timestamp"
    status: "$Status"
    error_trace: "$ErrorTrace"$refLine$noteLine
"@
    # Replace the execution_history placeholder or append to existing list
    if ($content -match 'execution_history: \[\]') {
        $content = $content -replace 'execution_history: \[\]', "execution_history:$histEntry"
    } else {
        # Append after the last history entry
        $content = $content + "`n" + $histEntry
    }
}

Set-Content -Path $contractFile -Value $content -Encoding UTF8

Write-Output "$ContractId -> $Status$(if ($ErrorTrace) { " error=$ErrorTrace" })"
