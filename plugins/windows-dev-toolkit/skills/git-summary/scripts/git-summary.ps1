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
    .claude\skills\git-summary\scripts\git-summary.ps1
.EXAMPLE
    .claude\skills\git-summary\scripts\git-summary.ps1 -LogCount 20 -ShowStash
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
$ProgressPreference = "SilentlyContinue"
if ($ExtraArgs) {
    Write-Host "WARN: Stray arguments ignored: $($ExtraArgs -join ', ')"
}

Push-Location $Path
try {
    git rev-parse --git-dir 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Error "Not a git repository: $Path"; exit 1 }

    Write-Host "repo=$Path"

    # Branch + tracking
    $branch = git branch --show-current 2>$null
    if (-not $branch) { $branch = "(detached HEAD)" }
    $tracking = git rev-parse --abbrev-ref "@{upstream}" 2>$null
    $trackInfo = if ($tracking) { " -> $tracking" } else { " (no upstream)" }
    Write-Host "branch=$branch$trackInfo"

    if ($tracking) {
        $ahead = (git rev-list --count "@{upstream}..HEAD" 2>$null)
        $behind = (git rev-list --count "HEAD..@{upstream}" 2>$null)
        if ($ahead -gt 0 -or $behind -gt 0) {
            Write-Host "Ahead: $ahead | Behind: $behind"
        } else { Write-Host "Up to date" }
    }

    # Working tree
    $status = git status --porcelain 2>$null
    if ($status) {
        $staged = ($status | Where-Object { $_ -match '^[MADRC]' }).Count
        $modified = ($status | Where-Object { $_ -match '^.[MD]' }).Count
        $untracked = ($status | Where-Object { $_ -match '^\?\?' }).Count
        Write-Host "Staged: $staged | Modified: $modified | Untracked: $untracked"
        $status | Select-Object -First 20 | ForEach-Object { Write-Host "$_" }
        if ($status.Count -gt 20) { Write-Host "... and $($status.Count - 20) more" }
    } else { Write-Host "Clean working tree" }

    # Recent commits
    $log = git log --oneline --decorate -n $LogCount 2>$null
    if ($log) { $log | ForEach-Object { Write-Host "$_" } }
    else { Write-Host "(no commits)" }

    # Branches
    $branches = git branch -a --format="%(refname:short)" 2>$null
    $local = $branches | Where-Object { $_ -notmatch '^origin/' }
    $remote = $branches | Where-Object { $_ -match '^origin/' }
    Write-Host "Local ($($local.Count)):"
    $local | ForEach-Object {
        $m = if ($_ -eq $branch) { " *" } else { "  " }
        Write-Host "$m $_"
    }
    if ($remote) {
        Write-Host "Remote ($($remote.Count)):"
        $remote | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" }
        if ($remote.Count -gt 10) { Write-Host "  ... and $($remote.Count - 10) more" }
    }

    # Stash
    if ($ShowStash) {
        $stash = git stash list 2>$null
        if ($stash) { $stash | ForEach-Object { Write-Host "$_" } }
        else { Write-Host "(none)" }
    }

} finally { Pop-Location }