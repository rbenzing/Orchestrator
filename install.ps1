[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Target
)

$ErrorActionPreference = 'Stop'
$ScriptRoot = $PSScriptRoot
if (-not $ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition }

$Directories = @('.claude')

# --- Banner ---
Write-Host ""
Write-Host "  ====================================================" -ForegroundColor Cyan
Write-Host "    Claude Orchestrator Installer" -ForegroundColor Cyan
Write-Host "    Copies .claude/ directory" -ForegroundColor Cyan
Write-Host "  ====================================================" -ForegroundColor Cyan
Write-Host ""

# --- Validate source directories exist ---
foreach ($dir in $Directories) {
    $srcPath = Join-Path $ScriptRoot $dir
    if (-not (Test-Path $srcPath)) {
        Write-Host "  ERROR: Source directory '$dir' not found at $ScriptRoot" -ForegroundColor Red
        exit 1
    }
}

# --- Get target path ---
if (-not $Target) {
    Write-Host "  Enter the target project path:" -ForegroundColor Yellow
    Write-Host "  (the root of the project you want to install into)" -ForegroundColor DarkGray
    Write-Host ""
    $Target = Read-Host "  Path"
    Write-Host ""
}

$Target = $Target.Trim('"').Trim("'")

if (-not $Target) {
    Write-Host "  ERROR: No target path provided." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $Target -PathType Container)) {
    Write-Host "  ERROR: Target path does not exist or is not a directory:" -ForegroundColor Red
    Write-Host "         $Target" -ForegroundColor Red
    exit 1
}

$Target = (Resolve-Path $Target).Path

# --- Check for existing directories ---
$existing = @()
foreach ($dir in $Directories) {
    $destPath = Join-Path $Target $dir
    if (Test-Path $destPath) {
        $existing += $dir
    }
}

# --- Show what will be copied ---
Write-Host "  Source:  $ScriptRoot" -ForegroundColor Gray
Write-Host "  Target:  $Target" -ForegroundColor Gray
Write-Host ""

$totalFiles = 0
foreach ($dir in $Directories) {
    $srcPath = Join-Path $ScriptRoot $dir
    $files = Get-ChildItem -Path $srcPath -Recurse -File
    $count = $files.Count
    $totalFiles += $count
    $marker = ""
    if ($existing -contains $dir) { $marker = " (exists - will overwrite)" }
    Write-Host "  [DIR] $dir/ - $count files$marker" -ForegroundColor White
}
Write-Host ""
Write-Host "  Total: $totalFiles files will be copied." -ForegroundColor White
Write-Host ""

# --- Confirm ---
if ($existing.Count -gt 0) {
    Write-Host "  WARNING: The following directories already exist and will be OVERWRITTEN:" -ForegroundColor Yellow
    foreach ($dir in $existing) {
        Write-Host "     - $Target\$dir" -ForegroundColor Yellow
    }
    Write-Host ""
}

$confirm = Read-Host "  Proceed? (Y/n)"
if ($confirm -and $confirm -notin @('y', 'Y', 'yes', 'Yes', 'YES')) {
    Write-Host ""
    Write-Host "  Cancelled." -ForegroundColor DarkGray
    exit 0
}

# --- Copy ---
Write-Host ""
$copiedCount = 0
foreach ($dir in $Directories) {
    $srcPath = Join-Path $ScriptRoot $dir
    $destPath = Join-Path $Target $dir

    # Get all items to copy (files and empty directories)
    $items = Get-ChildItem -Path $srcPath -Recurse
    foreach ($item in $items) {
        $relativePath = $item.FullName.Substring($srcPath.Length)
        $destItem = Join-Path $destPath $relativePath

        if ($item.PSIsContainer) {
            if (-not (Test-Path $destItem)) {
                New-Item -Path $destItem -ItemType Directory -Force | Out-Null
            }
        }
        else {
            $destDir = Split-Path -Parent $destItem
            if (-not (Test-Path $destDir)) {
                New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            }
            Copy-Item -Path $item.FullName -Destination $destItem -Force
            $copiedCount++
            Write-Host "  + $dir$relativePath" -ForegroundColor DarkGreen
        }
    }
}

Write-Host ""
Write-Host "  ====================================================" -ForegroundColor Green
Write-Host "  Done! Copied $copiedCount files to $Target" -ForegroundColor Green
Write-Host "  ====================================================" -ForegroundColor Green
Write-Host ""

