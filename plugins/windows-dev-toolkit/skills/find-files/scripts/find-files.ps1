<#
.SYNOPSIS
    Find files by name pattern (like Unix find).
.DESCRIPTION
    Recursively searches for files matching a wildcard or regex name pattern.
    Excludes node_modules, .git, bin, obj, and other non-source directories.
.PARAMETER Name
    Wildcard pattern for file names (e.g. "*.ts", "*.test.*", "App*").
.PARAMETER Path
    Root directory to search. Defaults to current directory.
.PARAMETER Regex
    Treat -Name as a regex instead of a wildcard.
.PARAMETER DirectoriesOnly
    Only return directories, not files.
.PARAMETER MaxResults
    Max results to return. Default: 200.
.EXAMPLE
    .claude\skills\find-files\scripts\find-files.ps1 -Name "*.test.ts"
.EXAMPLE
    .claude\skills\find-files\scripts\find-files.ps1 -Name "Controller" -Regex
.EXAMPLE
    .claude\skills\find-files\scripts\find-files.ps1 -Name "components" -DirectoriesOnly
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [string]$Path = (Get-Location).Path,
    [switch]$Regex,
    [switch]$DirectoriesOnly,
    [int]$MaxResults = 200,
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) {
    Write-Host "WARN: Stray arguments ignored: $($ExtraArgs -join ', ')"
    Write-Host "Usage: .claude\skills\find-files\scripts\find-files.ps1 -Name ""*.ts"" -Path ""src"""
}

$ExcludeDirs = @('.git','node_modules','bin','obj','dist','build','vendor',
                  '__pycache__','.vs','.idea','packages','TestResults','.next')

$count = 0
if ($DirectoriesOnly) {
    $items = Get-ChildItem -Path $Path -Recurse -Directory -ErrorAction SilentlyContinue
} else {
    $items = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue
}

$items | Where-Object {
    $fp = $_.FullName; $skip = $false
    foreach ($d in $ExcludeDirs) { if ($fp -match "[\\/]$([regex]::Escape($d))[\\/]") { $skip = $true; break } }
    if ($skip) { return $false }
    if ($Regex) { $_.Name -match $Name } else { $_.Name -like $Name }
} | ForEach-Object {
    if ($count -ge $MaxResults) { return }
    $count++
    $rel = $_.FullName
    if ($rel.StartsWith($Path)) { $rel = $rel.Substring($Path.Length).TrimStart('\','/') }
    $size = if (-not $DirectoriesOnly -and $_.Length -gt 1024) { " ({0:N0} KB)" -f ($_.Length / 1024) }
            elseif (-not $DirectoriesOnly) { " ($($_.Length) B)" } else { "" }
    Write-Host "$rel$size"
}

if ($count -ge $MaxResults) { Write-Host "`n--- Stopped at $MaxResults results ---" }
Write-Host "`nFound: $count"