<#
.SYNOPSIS
    Update a specific field in an artifact YAML file.
.PARAMETER ProjectName
    Project identifier.
.PARAMETER Agent
    Agent role.
.PARAMETER ContractId
    Contract ID (e.g. TSK-001). Resolves to {agent}/{ContractId}.yml
.PARAMETER Field
    Top-level YAML field name to update.
.PARAMETER Value
    New value. For lists, pass JSON array: '["item1","item2"]'
.PARAMETER Status
    Set artifact status. Default: active.
.EXAMPLE
    update-artifact.ps1 -ProjectName "auth" -Agent "researcher" -ContractId "TSK-001" -Field "goal" -Value "JWT auth"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectName,
    [Parameter(Mandatory)]
    [ValidateSet("researcher","architect","ui-designer","planner","developer","code-reviewer","tester")]
    [string]$Agent,
    [Parameter(Mandatory)][string]$ContractId,
    [Parameter(Mandatory)][string]$Field,
    [Parameter(Mandatory)][string]$Value,
    [string]$Status = "active",
    [Parameter(ValueFromRemainingArguments=$true)][object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) { Write-Output "ERROR: unknown params: $($ExtraArgs -join ' '). Valid: -ProjectName -Agent -ContractId -Field -Value -Status"; exit 1 }

$artifactPath = Join-Path "${CLAUDE_PLUGIN_ROOT}\artifacts" (Join-Path $ProjectName (Join-Path $Agent "$ContractId.yml"))
if (-not (Test-Path $artifactPath)) {
    Write-Error "Artifact not found: $artifactPath -- run new-artifact.ps1 first"
    exit 1
}

$lines = Get-Content $artifactPath
$output = @()
$inField = $false
$replaced = $false
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

foreach ($line in $lines) {
    # Auto-update timestamp
    if ($line -match '^updated_at:') {
        $output += "updated_at: `"$timestamp`""
        continue
    }
    # Auto-update status
    if ($line -match '^status:') {
        $output += "status: $Status"
        continue
    }
    # Found target field
    if ($line -match "^${Field}:\s*") {
        $inField = $true
        $replaced = $true
        # Determine if value is multiline YAML, JSON array, or scalar
        if ($Value -match '^\[') {
            # JSON array -- convert to YAML list
            try {
                $items = $Value | ConvertFrom-Json
                $output += "${Field}:"
                foreach ($item in $items) {
                    if ($item -is [string]) {
                        $output += "  - `"$item`""
                    } else {
                        # Nested object -- serialize each key
                        $output += "  - $(($item.PSObject.Properties | ForEach-Object { "$($_.Name): $($_.Value)" }) -join ' | ')"
                    }
                }
            } catch {
                # Not valid JSON, treat as raw value
                $output += "${Field}: $Value"
            }
        } elseif ($Value.Contains("`n")) {
            # Multi-line value -- use YAML literal block
            $output += "${Field}: |"
            foreach ($vline in ($Value -split "`n")) {
                $output += "  $vline"
            }
        } else {
            $output += "${Field}: `"$Value`""
        }
        continue
    }
    if ($inField) {
        # Skip old field content (indented lines, comments under field)
        if ($line -match '^\s' -or $line -match '^\s*#' -or $line.Trim() -eq '') {
            # Check if blank line between sections
            if ($line.Trim() -eq '' -and $output[-1].Trim() -ne '') {
                $inField = $false
                $output += $line
            }
            continue
        }
        $inField = $false
    }
    $output += $line
}

if (-not $replaced) {
    Write-Error "Field '$Field' not found in $artifactPath"
    exit 1
}

Set-Content -Path $artifactPath -Value ($output -join "`n") -Encoding UTF8
Write-Output "  [~] Updated $Field in $artifactPath" -ForegroundColor Cyan