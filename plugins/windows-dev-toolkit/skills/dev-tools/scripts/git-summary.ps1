<#
.SYNOPSIS
    Compact git status, branch, and recent history in one view.
.DESCRIPTION
    Shows current branch, ahead/behind, working tree status, and recent commits.
    Designed for quick orientation in a git repository.
.PARAMETER Path
    Repository root. Defaults to current directory.
.PARAMETER LogCount
    Number of recent commits to show. Default: 10.
.PARAMETER ShowStash
    Include stash list in output.
.EXAMPLE
    .claude\skills\dev-tools\scripts\git-summary.ps1
.EXAMPLE
    .claude\skills\dev-tools\scripts\git-summary.ps1 -LogCount 20 -ShowStash
#>
[CmdletBinding()]
param(
    [string]$Path = (Get-Location).Path,
    [int]$LogCount = 10,
    [switch]$ShowStash,
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

    Write-Host "=== Git Summary ===" -ForegroundColor Cyan
    Write-Host "  Repo: $Path"

    # Branch + tracking
    $branch = git branch --show-current 2>$null
    if (-not $branch) { $branch = "(detached HEAD)" }
    $tracking = git rev-parse --abbrev-ref "@{upstream}" 2>$null
    $trackInfo = if ($tracking) { " -> $tracking" } else { " (no upstream)" }
    Write-Host "  Branch: $branch$trackInfo"

    if ($tracking) {
        [int]$ahead  = (git rev-list --count "@{upstream}..HEAD"  2>$null)
        [int]$behind = (git rev-list --count "HEAD..@{upstream}" 2>$null)
        if ($ahead -gt 0 -or $behind -gt 0) {
            Write-Host "  Ahead: $ahead | Behind: $behind"
        } else { Write-Host "  Up to date" }
    }
    Write-Host ""

    # Working tree
    Write-Host "--- Status ---" -ForegroundColor Yellow
    $status = git status --porcelain 2>$null
    if ($status) {
        $staged = ($status | Where-Object { $_ -match '^[MADRC]' }).Count
        $modified = ($status | Where-Object { $_ -match '^.[MD]' }).Count
        $untracked = ($status | Where-Object { $_ -match '^\?\?' }).Count
        Write-Host "  Staged: $staged | Modified: $modified | Untracked: $untracked"
        $status | Select-Object -First 20 | ForEach-Object { Write-Host "  $_" }
        if ($status.Count -gt 20) { Write-Host "  ... and $($status.Count - 20) more" }
    } else { Write-Host "  Clean working tree" }
    Write-Host ""

    # Recent commits
    Write-Host "--- Commits ($LogCount) ---" -ForegroundColor Yellow
    $log = git log --oneline --decorate -n $LogCount 2>$null
    if ($log) { $log | ForEach-Object { Write-Host "  $_" } }
    else { Write-Host "  (no commits)" }
    Write-Host ""

    # Branches
    Write-Host "--- Branches ---" -ForegroundColor Yellow
    $branches = git branch -a --format="%(refname:short)" 2>$null
    $local = $branches | Where-Object { $_ -notmatch '^origin/' }
    $remote = $branches | Where-Object { $_ -match '^origin/' }
    Write-Host "  Local ($($local.Count)):"
    $local | ForEach-Object {
        $m = if ($_ -eq $branch) { " *" } else { "  " }
        Write-Host "  $m $_"
    }
    if ($remote) {
        Write-Host "  Remote ($($remote.Count)):"
        $remote | Select-Object -First 10 | ForEach-Object { Write-Host "    $_" }
        if ($remote.Count -gt 10) { Write-Host "    ... and $($remote.Count - 10) more" }
    }

    # Stash
    if ($ShowStash) {
        Write-Host ""
        Write-Host "--- Stash ---" -ForegroundColor Yellow
        $stash = git stash list 2>$null
        if ($stash) { $stash | ForEach-Object { Write-Host "  $_" } }
        else { Write-Host "  (none)" }
    }

    Write-Host "`n=== End ===" -ForegroundColor Cyan
} finally { Pop-Location }

