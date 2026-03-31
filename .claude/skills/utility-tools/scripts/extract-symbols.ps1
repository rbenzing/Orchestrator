<#
.SYNOPSIS
    Extracts specific functions/classes from a source file by name.
.DESCRIPTION
    Prevents agents from loading entire 2,000-line files into context. Uses
    regex-based heuristics to locate a named symbol (function, class, method,
    interface, enum) and extract only its block, including the signature and
    closing brace. Works for TypeScript, C#, Python, JavaScript, and Go.
.PARAMETER FilePath
    Path to the source file.
.PARAMETER Symbols
    One or more symbol names to extract (e.g. "loginHandler", "AuthError").
.PARAMETER ContextLines
    Additional lines of context before/after each symbol block. Default: 2.
.EXAMPLE
    .claude\skills\utility-tools\scripts\extract-symbols.ps1 `
      -FilePath "src/auth/login.ts" -Symbols "loginHandler","AuthError"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$FilePath,
    [Parameter(Mandatory)][string[]]$Symbols,
    [int]$ContextLines = 2
)
$ErrorActionPreference = "Stop"

if (-not (Test-Path $FilePath)) {
    Write-Error "File not found: $FilePath"
    exit 1
}

$lines = Get-Content $FilePath
$totalLines = $lines.Count

Write-Host ""
Write-Host "  [extract-symbols] $FilePath  ($totalLines lines total)" -ForegroundColor Cyan

foreach ($symbol in $Symbols) {
    Write-Host ""
    Write-Host "  -- Symbol: $symbol --" -ForegroundColor Yellow

    # Find the line where the symbol is declared
    $startLine = -1
    for ($i = 0; $i -lt $totalLines; $i++) {
        # Match: function, class, interface, enum, method, def (Python), func (Go)
        if ($lines[$i] -match "(?i)(function|class|interface|enum|def|func|public|private|protected|static|async)\s+$([regex]::Escape($symbol))\b") {
            $startLine = $i
            break
        }
        # Also match arrow functions / const assignments: const loginHandler = ...
        if ($lines[$i] -match "(?i)(const|let|var)\s+$([regex]::Escape($symbol))\s*[:=]") {
            $startLine = $i
            break
        }
    }

    if ($startLine -eq -1) {
        Write-Host "  [!] Symbol '$symbol' not found in $FilePath" -ForegroundColor Red
        continue
    }

    # Find the end of the block by tracking brace depth (for C-style langs)
    $endLine = $startLine
    $braceDepth = 0
    $foundOpenBrace = $false

    for ($i = $startLine; $i -lt $totalLines; $i++) {
        $opens  = ([regex]::Matches($lines[$i], '\{')).Count
        $closes = ([regex]::Matches($lines[$i], '\}')).Count
        $braceDepth += $opens - $closes
        if ($opens -gt 0) { $foundOpenBrace = $true }
        if ($foundOpenBrace -and $braceDepth -le 0) { $endLine = $i; break }

        # Python: end on de-indent (next non-empty line at same or lower indent)
        if (-not $foundOpenBrace -and $i -gt $startLine) {
            $baseIndent = ($lines[$startLine] -match '^(\s*)') ? $Matches[1].Length : 0
            $lineIndent = ($lines[$i]        -match '^(\s*)') ? $Matches[1].Length : 0
            if ($lines[$i].Trim() -ne "" -and $lineIndent -le $baseIndent) {
                $endLine = $i - 1; break
            }
        }
        $endLine = $i
    }

    # Apply context padding
    $from = [Math]::Max(0, $startLine - $ContextLines)
    $to   = [Math]::Min($totalLines - 1, $endLine + $ContextLines)

    Write-Host "  Lines $($from+1)-$($to+1) of $totalLines:" -ForegroundColor DarkGray
    Write-Host ""
    for ($i = $from; $i -le $to; $i++) {
        Write-Host ("  {0,4}: {1}" -f ($i + 1), $lines[$i])
    }
    Write-Host ""
}

