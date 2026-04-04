<#
.SYNOPSIS
    Wraps test execution and slices verbose stack traces to save tokens.
.DESCRIPTION
    Runs a test command, captures output, then extracts only the failure
    summary + top N stack frames. This prevents 500-line stack dumps from
    flooding an agent's context during TDD retry loops.
    Outputs a compact error report to stdout and optionally to a file.
.PARAMETER Command
    The test command to run (e.g. "dotnet test", "npm test", "pytest").
.PARAMETER WorkDir
    Working directory for the command. Defaults to current directory.
.PARAMETER MaxLines
    Max lines to retain from each failure block. Default: 30.
.PARAMETER OutputFile
    Optional file path to write the compact report to.
.EXAMPLE
    .claude\skills\utility-tools\scripts\truncate-error-log.ps1 -Command "dotnet test"
.EXAMPLE
    .claude\skills\utility-tools\scripts\truncate-error-log.ps1 `
      -Command "npm test" -OutputFile ".claude\orchestrator\artifacts\project\testing\error-summary.md"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Command,
    [string]$WorkDir = (Get-Location).Path,
    [int]$MaxLines = 30,
    [string]$OutputFile = ""
)
$ErrorActionPreference = "SilentlyContinue"

Write-Host ""
Write-Host "  [truncate-error-log] Running: $Command" -ForegroundColor Yellow
Write-Host "  Working dir: $WorkDir" -ForegroundColor DarkGray
Write-Host ""

# Run the test command and capture all output
$rawOutput = & cmd /c "cd /d `"$WorkDir`" && $Command 2>&1"
$exitCode  = $LASTEXITCODE

$rawLines = $rawOutput -split '\r?\n'
$totalLines = $rawLines.Count

Write-Host "  Raw output: $totalLines lines  |  Exit code: $exitCode" -ForegroundColor DarkGray

# ── Patterns that signal a failure block start ────────────────────────────
$failPatterns = @(
    '(?i)(FAILED|ERROR|FAIL:|\[FAIL\]|Assert|Exception|NUnit\.Framework)',
    '(?i)(expected|actual|should|must|cannot|not found)',
    '(?i)(at \w+.*line \d+|File ".*", line \d+)'
)

# ── Extract compact failure report ────────────────────────────────────────
$compactLines = @()
$compactLines += "# Test Failure Summary"
$compactLines += "Command : $Command"
$compactLines += "ExitCode: $exitCode"
$compactLines += "Date    : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$compactLines += ""

if ($exitCode -eq 0) {
    $compactLines += "## Result: ALL TESTS PASSED"
    $passLines = $rawLines | Where-Object { $_ -match '(?i)(passed|ok|success|\d+ test)' }
    $compactLines += ($passLines | Select-Object -Last 5)
} else {
    $compactLines += "## Result: TESTS FAILED"
    $compactLines += ""

    # Find failure blocks
    $inBlock = $false
    $blockLines = 0
    $blockCount = 0

    foreach ($line in $rawLines) {
        $isFailLine = $failPatterns | Where-Object { $line -match $_ }
        if ($isFailLine -or $inBlock) {
            if (-not $inBlock) {
                $blockCount++
                $compactLines += "### Failure Block $blockCount"
                $inBlock = $true
                $blockLines = 0
            }
            if ($blockLines -lt $MaxLines) {
                $compactLines += $line
                $blockLines++
            } elseif ($blockLines -eq $MaxLines) {
                $compactLines += "  ... [truncated - $MaxLines line limit reached]"
                $blockLines++
                $inBlock = $false  # end this block
            }
        }
    }

    if ($blockCount -eq 0) {
        # No specific block found - take last N lines
        $compactLines += "### Last $MaxLines lines of output:"
        $compactLines += ($rawLines | Select-Object -Last $MaxLines)
    }
}

$compactLines += ""
$compactLines += "---"
$compactLines += "Original output: $totalLines lines (truncated to compact report above)"

# ── Output ────────────────────────────────────────────────────────────────
$report = $compactLines -join "`n"
Write-Host $report

if ($OutputFile) {
    $dir = Split-Path $OutputFile -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item $dir -ItemType Directory -Force | Out-Null }
    Set-Content $OutputFile -Value $report -Encoding UTF8
    Write-Host ""
    Write-Host "  Report saved: $OutputFile" -ForegroundColor Green
}

Write-Host ""
exit $exitCode

