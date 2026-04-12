<#
.SYNOPSIS
    Show directory tree structure with depth control.
.DESCRIPTION
    Displays a visual directory tree, file counts per directory, and detected
    frameworks. Excludes node_modules, .git, bin, obj, etc.
.PARAMETER Path
    Root directory to display. Defaults to current directory.
.PARAMETER Depth
    Maximum depth to traverse. Default: 3.
.PARAMETER ShowFiles
    Include files in the tree (not just directories).
.EXAMPLE
    .claude\skills\tree\scripts\tree.ps1
.EXAMPLE
    .claude\skills\tree\scripts\tree.ps1 -Path "src" -Depth 4 -ShowFiles
#>
[CmdletBinding()]
param(
    [string]$Path = (Get-Location).Path,
    [int]$Depth = 3,
    [switch]$ShowFiles,
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) {
    Write-Host "WARN: Stray arguments ignored: $($ExtraArgs -join ', ')"
}

$ExcludeDirs = @('.git','node_modules','bin','obj','dist','build','vendor',
                  '__pycache__','.vs','.idea','packages','TestResults','.next')

$resolvedPath = (Resolve-Path $Path -ErrorAction Stop).Path
Write-Host "$resolvedPath"

function Show-Tree {
    param([string]$Dir, [int]$Level, [int]$Max, [string]$Indent)
    if ($Level -gt $Max) { return }
    $dirs = Get-ChildItem -Path $Dir -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notin $ExcludeDirs } | Sort-Object Name
    foreach ($d in $dirs) {
        $fc = (Get-ChildItem -Path $d.FullName -File -ErrorAction SilentlyContinue).Count
        $suffix = if ($fc -gt 0) { " ($fc files)" } else { "" }
        Write-Host "${Indent}+-- $($d.Name)$suffix"
        if ($ShowFiles) {
            $files = Get-ChildItem -Path $d.FullName -File -ErrorAction SilentlyContinue | Sort-Object Name
            foreach ($f in $files) {
                $sz = if ($f.Length -gt 1024) { "{0:N0}KB" -f ($f.Length/1024) } else { "$($f.Length)B" }
                Write-Host "${Indent}|   - $($f.Name) ($sz)"
            }
        }
        Show-Tree -Dir $d.FullName -Level ($Level+1) -Max $Max -Indent "${Indent}|   "
    }
}

Show-Tree -Dir $resolvedPath -Level 1 -Max $Depth -Indent "  "

# Quick stats
$allFiles = Get-ChildItem -Path $resolvedPath -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        $fp = $_.FullName; $skip = $false
        foreach ($d in $ExcludeDirs) { if ($fp -match "[\\/]$([regex]::Escape($d))[\\/]") { $skip = $true; break } }
        -not $skip
    }
$topExt = $allFiles | Group-Object Extension | Sort-Object Count -Descending | Select-Object -First 8
Write-Host "Files: $($allFiles.Count) total"
foreach ($g in $topExt) {
    $ext = if ($g.Name) { $g.Name } else { "(none)" }
    Write-Host "  $ext : $($g.Count)"
}