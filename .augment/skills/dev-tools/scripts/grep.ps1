<#
.SYNOPSIS
    Search file contents for a pattern (like grep).
.DESCRIPTION
    Recursively searches project files for a regex pattern. Uses git ls-files
    when available for .gitignore support. Excludes node_modules, .git, bin, obj, etc.
.PARAMETER Pattern
    Regex pattern to search for (case-insensitive by default).
.PARAMETER Path
    Root directory to search. Defaults to current directory.
.PARAMETER Include
    File glob filter (e.g. "*.ts", "*.cs"). Default: all files.
.PARAMETER Context
    Lines of context before/after each match. Default: 0.
.PARAMETER CaseSensitive
    Enable case-sensitive matching.
.PARAMETER MaxResults
    Max matches to return. Default: 100.
.EXAMPLE
    .augment\skills\dev-tools\scripts\grep.ps1 -Pattern "TODO|FIXME"
.EXAMPLE
    .augment\skills\dev-tools\scripts\grep.ps1 -Pattern "class\s+\w+" -Include "*.cs" -Context 2
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Pattern,
    [string]$Path = (Get-Location).Path,
    [string]$Include = "*",
    [int]$Context = 0,
    [switch]$CaseSensitive,
    [int]$MaxResults = 100,
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
if ($ExtraArgs) {
    Write-Host "  WARNING: Stray arguments ignored: $($ExtraArgs -join ', ')" -ForegroundColor Yellow
    Write-Host "  Usage: .augment\skills\dev-tools\scripts\grep.ps1 -Pattern ""TODO"" -Include ""*.ts""" -ForegroundColor Yellow
}

$ExcludeDirs = @('.git','node_modules','bin','obj','dist','build','vendor',
                  '__pycache__','.vs','.idea','packages','TestResults','.next','.augment')
$BinaryExt = @('.exe','.dll','.pdb','.zip','.tar','.gz','.png','.jpg','.jpeg',
               '.gif','.ico','.woff','.woff2','.ttf','.mp3','.mp4','.pdf','.nupkg','.snk')

$regexOpts = if ($CaseSensitive) { [System.Text.RegularExpressions.RegexOptions]::None }
             else { [System.Text.RegularExpressions.RegexOptions]::IgnoreCase }

# Try git ls-files first
$files = @(); $useGit = $false
try {
    Push-Location $Path
    $gitFiles = git ls-files --cached --others --exclude-standard 2>$null
    if ($LASTEXITCODE -eq 0 -and $gitFiles) {
        $files = $gitFiles | Where-Object {
            ($Include -eq "*" -or (Split-Path $_ -Leaf) -like $Include) -and
            ([System.IO.Path]::GetExtension($_) -notin $BinaryExt)
        } | ForEach-Object { Join-Path $Path $_ }
        $useGit = $true
    }
} catch { } finally { Pop-Location }

# Fallback: manual enumeration
if (-not $useGit) {
    $files = Get-ChildItem -Path $Path -Recurse -File -Filter $Include -ErrorAction SilentlyContinue |
        Where-Object {
            $fp = $_.FullName; $skip = $false
            foreach ($d in $ExcludeDirs) { if ($fp -match "[\\/]$([regex]::Escape($d))[\\/]") { $skip = $true; break } }
            -not $skip -and ($_.Extension -notin $BinaryExt)
        } | Select-Object -ExpandProperty FullName
}

$matchCount = 0
foreach ($file in $files) {
    if ($matchCount -ge $MaxResults) { Write-Host "`n--- Stopped at $MaxResults matches ---"; break }
    if (-not (Test-Path $file)) { continue }
    try { $lines = [System.IO.File]::ReadAllLines($file) } catch { continue }
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ([regex]::IsMatch($lines[$i], $Pattern, $regexOpts)) {
            $matchCount++
            if ($matchCount -gt $MaxResults) { break }
            $rel = if ($file.StartsWith($Path)) { $file.Substring($Path.Length).TrimStart('\','/') } else { $file }
            $ln = $i + 1
            Write-Host "${rel}:${ln}: $($lines[$i].TrimEnd())" -ForegroundColor Cyan
            if ($Context -gt 0) {
                $s = [Math]::Max(0, $i - $Context); $e = [Math]::Min($lines.Count - 1, $i + $Context)
                for ($j = $s; $j -le $e; $j++) {
                    if ($j -ne $i) { Write-Host "  ${rel}:$($j+1): $($lines[$j].TrimEnd())" -ForegroundColor DarkGray }
                }
                Write-Host ""
            }
        }
    }
}
Write-Host "`nTotal matches: $matchCount" -ForegroundColor Green

