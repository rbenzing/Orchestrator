<#
.SYNOPSIS
    Show git changes - staged, unstaged, or between refs.
.DESCRIPTION
    Displays git diff output with sensible defaults. Can show staged changes,
    unstaged changes, or diff between two refs (branches, commits, tags).
.PARAMETER Staged
    Show only staged (cached) changes.
.PARAMETER Ref1
    First ref for comparison (e.g. "main", "HEAD~3", a commit hash).
.PARAMETER Ref2
    Second ref for comparison. Default: HEAD (current).
.PARAMETER Path
    Repository root. Defaults to current directory.
.PARAMETER FilePath
    Limit diff to a specific file or directory path.
.PARAMETER Stat
    Show diffstat summary instead of full diff.
.PARAMETER NameOnly
    Show only changed file names.
.EXAMPLE
    .claude\skills\dev-tools\scripts\git-diff.ps1
.EXAMPLE
    .claude\skills\dev-tools\scripts\git-diff.ps1 -Staged
.EXAMPLE
    .claude\skills\dev-tools\scripts\git-diff.ps1 -Ref1 "main" -Ref2 "feature/login"
.EXAMPLE
    .claude\skills\dev-tools\scripts\git-diff.ps1 -Ref1 "HEAD~5" -Stat
#>
[CmdletBinding()]
param(
    [switch]$Staged,
    [string]$Ref1,
    [string]$Ref2,
    [string]$Path = (Get-Location).Path,
    [string]$FilePath,
    [switch]$Stat,
    [switch]$NameOnly,
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
if ($ExtraArgs) {
    Write-Host "  WARNING: Stray arguments ignored: $($ExtraArgs -join ', ')" -ForegroundColor Yellow
}

Push-Location $Path
try {
    git rev-parse --git-dir 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Error "Not a git repository: $Path"; exit 1 }

    $args_ = @()
    if ($Stat) { $args_ += "--stat" }
    if ($NameOnly) { $args_ += "--name-only" }

    if ($Ref1 -and $Ref2) {
        $args_ += "$Ref1..$Ref2"
        Write-Host "  Diff: $Ref1..$Ref2" -ForegroundColor Cyan
    } elseif ($Ref1) {
        $args_ += "$Ref1..HEAD"
        Write-Host "  Diff: $Ref1..HEAD" -ForegroundColor Cyan
    } elseif ($Staged) {
        $args_ += "--cached"
        Write-Host "  Diff: staged changes" -ForegroundColor Cyan
    } else {
        Write-Host "  Diff: unstaged changes" -ForegroundColor Cyan
    }

    if ($FilePath) {
        $args_ += "--"
        $args_ += $FilePath
        Write-Host "  Path filter: $FilePath" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  > git diff $($args_ -join ' ')" -ForegroundColor DarkGray
    Write-Host ""
    & git diff @args_
} finally { Pop-Location }

