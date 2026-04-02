<#
.SYNOPSIS
    Produces a token-efficient summary of a large artifact file.
.DESCRIPTION
    Reads a Markdown artifact (architecture doc, story breakdown, spec, etc.) and
    emits a compact summary containing:
      - All headings (##, ###) with their hierarchy
      - Bullet / checkbox items (first 2 words used as labels)
      - Key: Value pairs from tables or YAML-style blocks
      - Code fence language labels (no body)
      - Total line count and reduction ratio
    This prevents agents from loading a 400-line architecture document into context
    when they only need the structure and decisions.
.PARAMETER Path
    Path to the artifact file to summarize.
.PARAMETER MaxLines
    Approximate maximum lines in the summary output. Default: 60.
.PARAMETER IncludeBody
    Include up to 3 lines of body text after each heading. Default: $false.
.EXAMPLE
    .claude\skills\utility-tools\scripts\summarize-artifact.ps1 `
      -Path ".claude\artifacts\user-auth\architect\architecture.md"
.EXAMPLE
    .claude\skills\utility-tools\scripts\summarize-artifact.ps1 `
      -Path ".claude\artifacts\user-auth\planner\story-breakdown.md" -MaxLines 80
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Path,
    [int]$MaxLines = 60,
    [switch]$IncludeBody
)
$ErrorActionPreference = "Stop"

if (-not (Test-Path $Path)) {
    Write-Error "File not found: $Path"
    exit 1
}

$lines      = Get-Content $Path
$totalLines = $lines.Count
$output     = [System.Collections.Generic.List[string]]::new()
$emitted    = 0
$lastWasBlank = $false

$output.Add("# ARTIFACT SUMMARY: $(Split-Path $Path -Leaf)")
$output.Add("# Source: $Path  ($totalLines lines)")
$output.Add("")

$inFence   = $false
$bodyBuf   = [System.Collections.Generic.List[string]]::new()
$bodyCount = 0

for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($emitted -ge $MaxLines) { break }
    $line = $lines[$i]

    # Track code fences — emit language label only
    if ($line -match '^```') {
        if ($inFence) { $inFence = $false }
        else {
            $inFence = $true
            $lang = ($line -replace '^```', '').Trim()
            if ($lang) { $output.Add("  [code: $lang]"); $emitted++ }
        }
        continue
    }
    if ($inFence) { continue }

    # Headings
    if ($line -match '^(#{1,4})\s+(.+)') {
        $level   = $Matches[1].Length
        $title   = $Matches[2].Trim()
        $indent  = "  " * ($level - 1)
        $output.Add("${indent}[$level] $title")
        $emitted++
        $bodyCount = 0
        $lastWasBlank = $false
        continue
    }

    # Checkboxes / bullets (first 8 words)
    if ($line -match '^\s*[-*]\s+\[[ xX]\]\s+(.+)' -or $line -match '^\s*[-*]\s+(.+)') {
        $text    = $Matches[1].Trim()
        $words   = ($text -split '\s+') | Select-Object -First 8
        $preview = $words -join ' '
        if ($text.Length -gt $preview.Length) { $preview += '...' }
        $output.Add("  • $preview")
        $emitted++
        continue
    }

    # Key: Value table rows or YAML-style pairs
    if ($line -match '^\|\s*\*\*(.+?)\*\*\s*\|' -or $line -match '^([A-Z][^:]{1,30}):\s+(.{5,80})$') {
        $output.Add("  $($line.Trim() | ForEach-Object { if ($_.Length -gt 80) { $_.Substring(0,80) + '...' } else { $_ } })")
        $emitted++
        continue
    }

    # Body lines after a heading (if IncludeBody)
    if ($IncludeBody -and $line.Trim() -ne '' -and $bodyCount -lt 3) {
        $preview = if ($line.Length -gt 100) { $line.Substring(0,100) + '...' } else { $line }
        $output.Add("    $($preview.Trim())")
        $emitted++
        $bodyCount++
        continue
    }
}

# Footer
$output.Add("")
$ratio = [math]::Round((1 - $emitted / [math]::Max(1,$totalLines)) * 100)
$output.Add("# Summary: $emitted lines shown / $totalLines total  (${ratio}% reduction)")

Write-Output ($output -join "`n")

