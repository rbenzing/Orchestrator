<#
.SYNOPSIS
    Reads a YAML contract and generates a minimal sub-agent instruction string
    Contains only the objective, required_reads content, acceptance criteria,
    and deliverables -- no extra context
.PARAMETER ProjectName
    Project identifier
.PARAMETER ContractId
    Contract ID to generate prompt for
.PARAMETER IncludeFileContent
    If set, inline the content of required_reads files (compact summaries)
    Otherwise just list the paths for the agent to read
.EXAMPLE
    ${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\generate-subagent-prompt.ps1 `
      -ProjectName "user-auth" -ContractId "TSK-003"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectName,
    [Parameter(Mandatory)][string]$ContractId,
    [switch]$IncludeFileContent,
    [string]$BasePath = ".claude/orchestrator/contracts",
    [Parameter(ValueFromRemainingArguments)][object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) { Write-Output "ERROR: unknown params: $($ExtraArgs -join ' '). Valid: -ProjectName -ContractId -IncludeFileContent -BasePath"; exit 1 }

# Resolve relative BasePath against the current working directory (target project root).
if (-not [System.IO.Path]::IsPathRooted($BasePath)) {
    $BasePath = Join-Path (Get-Location).Path $BasePath
}

$contractFile = Join-Path $BasePath (Join-Path $ProjectName "$ContractId.yml")
if (-not (Test-Path $contractFile)) {
    Write-Output "ERROR: Contract not found: $contractFile"; exit 1
}

$yaml = Get-Content $contractFile -Raw

# Simple YAML field parser
function Get-Field {
    param([string]$Yaml, [string]$Field)
    $m = [regex]::Match($Yaml, "(?m)^$Field\s*:\s*[`"']?([^`"'\r\n]+)[`"']?")
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
    return ""
}

# Parse YAML list (lines starting with "  - ")
function Get-ListField {
    param([string]$Yaml, [string]$Field)
    $pattern = "(?ms)^${Field}:\s*\n((?:\s+-\s+.*\n?)*)"
    $m = [regex]::Match($Yaml, $pattern)
    if (-not $m.Success) { return @() }
    $items = @()
    foreach ($line in ($m.Groups[1].Value -split "`n")) {
        $line = $line.Trim()
        if ($line -match '^\-\s+"?(.+?)"?\s*$') {
            $items += $Matches[1]
        }
    }
    return $items
}

# Parse multiline field (field: |\n  content)
function Get-MultilineField {
    param([string]$Yaml, [string]$Field)
    $pattern = "(?ms)^${Field}:\s*\|\s*\n((?:\s{2}.*\n?)*)"
    $m = [regex]::Match($Yaml, $pattern)
    if ($m.Success) { return ($m.Groups[1].Value -replace "(?m)^\s{2}", "").Trim() }
    return (Get-Field $Yaml $Field)
}

$id = Get-Field $yaml "id"
$agent = Get-Field $yaml "assigned_agent"
$tier = Get-Field $yaml "model_tier"
$effort = Get-Field $yaml "effort"
$objective = Get-MultilineField $yaml "objective"
$reads = Get-ListField $yaml "required_reads"
$deliverables = Get-ListField $yaml "deliverables"
$criteria = Get-ListField $yaml "acceptance_criteria"

# Build minimal prompt
$prompt = @()
$prompt += "CONTRACT: $id | Agent: $agent | Model: $tier | Effort: $effort"
$prompt += ""
$prompt += "OBJECTIVE: $objective"
$prompt += ""

if ($deliverables.Count -gt 0) {
    $prompt += "DELIVERABLES:"
    foreach ($d in $deliverables) { $prompt += "- $d" }
    $prompt += ""
}

if ($criteria.Count -gt 0) {
    $prompt += "ACCEPTANCE CRITERIA:"
    foreach ($c in $criteria) { $prompt += "- $c" }
    $prompt += ""
}

if ($reads.Count -gt 0) {
    $prompt += "REQUIRED READS:"
    foreach ($r in $reads) {
        if ($IncludeFileContent -and (Test-Path $r)) {
            $content = Get-Content $r -Raw -ErrorAction SilentlyContinue
            if ($content) {
                # Truncate to first 100 lines to keep prompt compact
                $lines = $content -split "`n" | Select-Object -First 100
                $prompt += "--- $r ---"
                $prompt += ($lines -join "`n")
                if (($content -split "`n").Count -gt 100) {
                    $prompt += "... (truncated at 100 lines)"
                }
                $prompt += "--- end $r ---"
                $prompt += ""
            } else {
                $prompt += "- $r (file not found or empty)"
            }
        } else {
            $prompt += "- $r"
        }
    }
    $prompt += ""
}

$prompt += "WORKFLOW: Read required files -> Execute objective -> Validate all acceptance criteria -> Close contract -> Stop"

$result = $prompt -join "`n"
Write-Output $result