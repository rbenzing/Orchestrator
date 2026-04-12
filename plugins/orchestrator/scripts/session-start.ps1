<#
.SYNOPSIS
    SessionStart hook -- injects orchestrator recovery context when an active session exists.
    Stdout is injected by Claude as additionalContext for the agent.
    Silent exit (no output) on fresh sessions to save tokens.
#>
$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

# Look for any orchestrator state files
$stateFiles = Get-ChildItem ".claude\orchestrator\state\*\orchestrator-state.yml" -ErrorAction SilentlyContinue
if (-not $stateFiles) { exit 0 }

# Use the most recently saved state
$stateFile = $stateFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$yaml = Get-Content $stateFile.FullName -Raw -ErrorAction SilentlyContinue
if (-not $yaml) { exit 0 }

function Get-Field {
    param([string]$Yaml, [string]$Field)
    $m = [regex]::Match($Yaml, "(?m)^${Field}:\s*[`"']?([^`"'\r\n]+)[`"']?")
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
    return "unknown"
}

$project        = Get-Field $yaml "project_name"
$phase          = Get-Field $yaml "phase"
$routerPhase    = Get-Field $yaml "router_phase"
$activeContract = Get-Field $yaml "active_contract_id"
$nextAction     = Get-Field $yaml "next_action"
$savedAt        = Get-Field $yaml "saved_at"

# Count open contracts for this project
$openCount = 0
$openIds   = @()
$contractDir = ".claude\orchestrator\contracts\$project"
if (Test-Path $contractDir) {
    Get-ChildItem $contractDir -Filter "*.yml" | ForEach-Object {
        $c = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        if ($c -match 'status:\s*[''"]?Open') {
            $openCount++
            $id = Get-Field $c "id"
            $openIds += $id
        }
    }
}

# Build recovery context
$lines = @(
    "=== ORCHESTRATION SESSION RECOVERY ==="
    "Project      : $project"
    "Phase        : $phase ($routerPhase)"
    "Active       : $activeContract"
    "Open contracts ($openCount): $($openIds -join ', ')"
    "Next action  : $nextAction"
    "State saved  : $savedAt"
    ""
    "Run load-state.ps1 then continue from Next action above."
    "==="
)

$context = $lines -join "`n"

# SessionStart hooks use top-level additionalContext per Claude Code hooks spec
@{
    additionalContext = $context
} | ConvertTo-Json -Depth 3 -Compress | Write-Output

exit 0