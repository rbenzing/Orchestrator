<#
.SYNOPSIS
    Generates a minimal unified Git diff of what a developer changed.
.DESCRIPTION
    The Code Reviewer reads this compact diff instead of full before/after
    file states, saving thousands of tokens per review cycle. Limits output
    to the specified max lines with a truncation notice if exceeded.
.PARAMETER BaseBranch
    The branch or commit to diff against. Default: "HEAD~1" (last commit).
.PARAMETER Files
    Optional list of specific files to diff. Diffs entire working tree if omitted.
.PARAMETER MaxLines
    Maximum lines of diff output. Default: 200.
.PARAMETER OutputFile
    Optional file to write the diff to (e.g. .claude/orchestrator/artifacts/.../diff.md).
.PARAMETER Staged
    If set, diff staged changes (git diff --cached) instead of working tree.
.EXAMPLE
    .claude\skills\utility-tools\scripts\get-compact-diff.ps1
.EXAMPLE
    .claude\skills\utility-tools\scripts\get-compact-diff.ps1 `
      -BaseBranch "main" -Files "src/auth/login.ts","tests/auth/login.test.ts" `
      -OutputFile ".claude\orchestrator\artifacts\project\reviews\diff.md"
#>
[CmdletBinding()]
param(
    [string]$BaseBranch = "HEAD~1",
    [string[]]$Files = @(),
    [int]$MaxLines = 200,
    [string]$OutputFile = "",
    [switch]$Staged
)
$ErrorActionPreference = "SilentlyContinue"

# Verify git is available
git --version 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "git is not available in PATH."
    exit 1
}

Write-Host ""
Write-Host "  [get-compact-diff] Generating compact diff..." -ForegroundColor Yellow

# Build git diff command
$gitArgs = @("diff")
if ($Staged) { $gitArgs += "--cached" }
$gitArgs += "--unified=3"
if (-not $Staged) { $gitArgs += $BaseBranch }
if ($Files.Count -gt 0) {
    $gitArgs += "--"
    $gitArgs += $Files
}

$rawDiff = & git @gitArgs 2>&1
$rawLines = ($rawDiff -split '\r?\n')
$totalLines = $rawLines.Count

Write-Host "  Raw diff: $totalLines lines" -ForegroundColor DarkGray

# ── Summarize stats ───────────────────────────────────────────────────────
$addedLines   = ($rawLines | Where-Object { $_ -match '^\+[^\+]' }).Count
$removedLines = ($rawLines | Where-Object { $_ -match '^-[^-]' }).Count
$changedFiles = ($rawLines | Where-Object { $_ -match '^diff --git' }).Count

$header = @(
    "# Compact Git Diff",
    "Base    : $BaseBranch",
    "Date    : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "Files   : $changedFiles changed",
    "Changes : +$addedLines / -$removedLines lines",
    ""
)

# ── Truncate if needed ────────────────────────────────────────────────────
if ($totalLines -le $MaxLines) {
    $diffBody = $rawLines
} else {
    $diffBody  = $rawLines | Select-Object -First $MaxLines
    $diffBody += ""
    $diffBody += "... [TRUNCATED: showing first $MaxLines of $totalLines diff lines]"
    $diffBody += "... To see more, increase -MaxLines or diff specific -Files."
    Write-Host "  [!] Diff truncated to $MaxLines lines (was $totalLines)." -ForegroundColor Yellow
}

$output = ($header + $diffBody) -join "`n"

Write-Host $output

if ($OutputFile) {
    $dir = Split-Path $OutputFile -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item $dir -ItemType Directory -Force | Out-Null }
    Set-Content $OutputFile -Value $output -Encoding UTF8
    Write-Host ""
    Write-Host "  Diff saved: $OutputFile" -ForegroundColor Green
}

Write-Host ""

