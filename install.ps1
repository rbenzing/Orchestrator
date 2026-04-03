[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Target,
    [switch]$SetupOnly,      # Only scaffold local dirs; do not copy to a target project
    [switch]$Force,          # Overwrite existing .claudeignore
    [switch]$SkipPlugins,    # Skip plugin installation step
    [switch]$PluginsOnly     # Only install plugins + .claudeignore; skip .claude/ copy
)

$ErrorActionPreference = 'Stop'
$ScriptRoot = $PSScriptRoot
if (-not $ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition }

$Directories     = @('.claude')
$PluginNames     = @('orchestrator', 'windows-dev-toolkit')
$MarketplaceName = 'internal'
$MarketplacePath = Join-Path $ScriptRoot 'marketplace.json'

# --- Banner ---
Write-Host ""
Write-Host "  ====================================================" -ForegroundColor Cyan
Write-Host "    Claude Contract-Router Installer" -ForegroundColor Cyan
Write-Host "    Scaffolds .claude/, installs plugins, .claudeignore" -ForegroundColor Cyan
Write-Host "  ====================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# PHASE 1 - Local scaffold (always runs)
# Creates new Contract-Router directories and verifies .claudeignore
# ============================================================
Write-Host "  [Phase 1] Scaffolding local .claude/ directories..." -ForegroundColor Yellow

function Initialize-Dir {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
        Write-Host "    [+] Created: $Path" -ForegroundColor Green
    } else {
        Write-Host "    [=] Exists:  $Path" -ForegroundColor DarkGray
    }
}

Initialize-Dir (Join-Path $ScriptRoot ".claude\orchestrator\contracts")
Initialize-Dir (Join-Path $ScriptRoot ".claude\orchestrator\artifacts")
Initialize-Dir (Join-Path $ScriptRoot ".claude\orchestrator\state")

# Verify .claudeignore exists in the repo (it is a source file, not generated)
$claudeIgnoreSrc = Join-Path $ScriptRoot '.claudeignore'
if (Test-Path $claudeIgnoreSrc) {
    Write-Host "    [=] Present: .claudeignore" -ForegroundColor DarkGray
} else {
    Write-Host "    [!] WARNING: .claudeignore missing from repo root." -ForegroundColor Yellow
}

Write-Host ""
if ($SetupOnly) {
    Write-Host "  ====================================================" -ForegroundColor Green
    Write-Host "  Setup complete (local scaffold only)." -ForegroundColor Green
    Write-Host "  ====================================================" -ForegroundColor Green
    Write-Host ""
    exit 0
}

# --- Get and validate target path ---
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

# ============================================================
# PHASE 2 - Install plugins into target project
# Registers the internal marketplace and enables both plugins
# at project scope in .claude/settings.json
# ============================================================
if (-not $SkipPlugins) {
    Write-Host "  [Phase 2] Installing plugins into $Target..." -ForegroundColor Yellow
    Write-Host ""

    # Ensure target .claude/ directory exists
    $targetClaudeDir = Join-Path $Target '.claude'
    if (-not (Test-Path $targetClaudeDir)) {
        New-Item -Path $targetClaudeDir -ItemType Directory -Force | Out-Null
        Write-Host "    [+] Created: $targetClaudeDir" -ForegroundColor Green
    }

    # Read or create target settings.json
    $targetSettingsPath = Join-Path $targetClaudeDir 'settings.json'
    if (Test-Path $targetSettingsPath) {
        try {
            $settings = Get-Content $targetSettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {
            Write-Host "    [!] Could not parse existing settings.json — creating backup and replacing." -ForegroundColor Yellow
            Copy-Item $targetSettingsPath "$targetSettingsPath.bak" -Force
            $settings = [PSCustomObject]@{}
        }
    } else {
        $settings = [PSCustomObject]@{}
    }

    # Add or update marketplaces array
    $marketplaceEntry = [PSCustomObject]@{
        name = $MarketplaceName
        path = $MarketplacePath
    }

    if (-not ($settings.PSObject.Properties.Name -contains 'pluginMarketplaces')) {
        $settings | Add-Member -NotePropertyName 'pluginMarketplaces' -NotePropertyValue @($marketplaceEntry)
        Write-Host "    [+] Registered marketplace '$MarketplaceName' -> $MarketplacePath" -ForegroundColor Green
    } else {
        # Check if already registered
        $existing = $settings.pluginMarketplaces | Where-Object { $_.name -eq $MarketplaceName }
        if (-not $existing) {
            $settings.pluginMarketplaces += $marketplaceEntry
            Write-Host "    [+] Registered marketplace '$MarketplaceName' -> $MarketplacePath" -ForegroundColor Green
        } else {
            # Update path in case repo moved
            $existing.path = $MarketplacePath
            Write-Host "    [=] Updated marketplace '$MarketplaceName' path" -ForegroundColor DarkGray
        }
    }

    # Add or update enabledPlugins array
    $pluginRefs = $PluginNames | ForEach-Object { "${_}@${MarketplaceName}" }

    if (-not ($settings.PSObject.Properties.Name -contains 'enabledPlugins')) {
        $settings | Add-Member -NotePropertyName 'enabledPlugins' -NotePropertyValue $pluginRefs
    } else {
        foreach ($ref in $pluginRefs) {
            if ($settings.enabledPlugins -notcontains $ref) {
                $settings.enabledPlugins += $ref
            }
        }
    }

    foreach ($ref in $pluginRefs) {
        Write-Host "    [+] Enabled plugin: $ref" -ForegroundColor Green
    }

    # Add toolPermissions if not already present
    if (-not ($settings.PSObject.Properties.Name -contains 'toolPermissions')) {
        $toolPermissions = @(
            [PSCustomObject]@{ toolName = "view";                permission = [PSCustomObject]@{ type = "allow" } }
            [PSCustomObject]@{ toolName = "codebase-retrieval";  permission = [PSCustomObject]@{ type = "allow" } }
            [PSCustomObject]@{ toolName = "grep-search";         permission = [PSCustomObject]@{ type = "allow" } }
            [PSCustomObject]@{ toolName = "str-replace-editor";  permission = [PSCustomObject]@{ type = "allow" } }
            [PSCustomObject]@{ toolName = "save-file";           permission = [PSCustomObject]@{ type = "allow" } }
            [PSCustomObject]@{ toolName = "read-process";        permission = [PSCustomObject]@{ type = "allow" } }
            [PSCustomObject]@{ toolName = "list-processes";      permission = [PSCustomObject]@{ type = "allow" } }
            [PSCustomObject]@{ toolName = "write-process";       permission = [PSCustomObject]@{ type = "allow" } }
            [PSCustomObject]@{ toolName = "web-search";          permission = [PSCustomObject]@{ type = "allow" } }
            [PSCustomObject]@{ toolName = "web-fetch";           permission = [PSCustomObject]@{ type = "allow" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "\.claude[/\\]skills[/\\]"; permission = [PSCustomObject]@{ type = "allow" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "(cmd\s+/[ck]|powershell\s+-[Cc]ommand|powershell\.exe\s+-[Cc]ommand|pwsh\s+-[Cc]ommand|bash\s+-c|sh\s+-c)"; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "(dotnet build|dotnet test|dotnet run|dotnet restore|dotnet format)"; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "(python |pip |poetry |cargo |go |ruby |bundle )"; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "(mkdir|New-Item|Copy-Item|Move-Item|Rename-Item)"; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "(git status|git diff|git log|git branch|git show|git stash)"; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "(ls |dir |pwd|echo |cat |type |Get-Content|Get-ChildItem|Get-Location|Write-Output)"; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "(npm test|npm run|npx |yarn |pnpm |node |tsc |jest |vitest |prettier |eslint )"; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "(cd |Set-Location|Push-Location|Pop-Location)"; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "(Test-Path|Resolve-Path|Split-Path|Join-Path)"; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "Get-Process"; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "(Remove-Item |rm |ri |del )"; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "(Stop-Process|Get-NetTCPConnection)"; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "Select-String"; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = '(rm -rf /|Remove-Item.*-Recurse.*C:\\|Remove-Item.*-Recurse.*\$env:)'; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "(sudo|runas|Start-Process.*-Verb RunAs)"; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "(shutdown|restart|Restart-Computer|Stop-Computer|reboot)"; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "(chmod 777|icacls.*/grant.*Everyone)"; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "(curl.*\|.*sh|curl.*\|.*bash|iex.*\(.*Net\.WebClient|Invoke-Expression.*Download)"; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "(Set-ExecutionPolicy|reg add|reg delete|New-Service|Stop-Service|Remove-Service)"; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "(format |diskpart|fdisk|mkfs|dd if=)"; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "(net user|net localgroup|Add-LocalGroupMember|passwd)"; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "(git push|git merge|git rebase|git reset --hard|git clean -fd)"; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = "(npm publish|npm unpublish|dotnet nuget push|dotnet publish)"; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = '(env |\$env:|ConvertTo-SecureString|Get-Credential).*([Pp]assword|[Ss]ecret|[Tt]oken|[Kk]ey|[Cc]redential)'; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; shellInputRegex = '\$[a-zA-Z_][a-zA-Z0-9_]* *='; permission = [PSCustomObject]@{ type = "deny" } }
            [PSCustomObject]@{ toolName = "launch-process"; permission = [PSCustomObject]@{ type = "allow" } }
            [PSCustomObject]@{ toolName = "remove-files"; permission = [PSCustomObject]@{ type = "allow" } }
            [PSCustomObject]@{ toolName = "kill-process";  permission = [PSCustomObject]@{ type = "allow" } }
            [PSCustomObject]@{ toolName = "github-api";    permission = [PSCustomObject]@{ type = "allow" } }
            [PSCustomObject]@{ toolName = "linear";        permission = [PSCustomObject]@{ type = "allow" } }
            [PSCustomObject]@{ toolName = "notion";        permission = [PSCustomObject]@{ type = "allow" } }
        )
        $settings | Add-Member -NotePropertyName 'toolPermissions' -NotePropertyValue $toolPermissions
        Write-Host "    [+] Written toolPermissions security block" -ForegroundColor Green
    } else {
        Write-Host "    [=] toolPermissions already present — skipping" -ForegroundColor DarkGray
    }

    # Write updated settings.json
    $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $targetSettingsPath -Encoding UTF8
    Write-Host "    [+] Written: $targetSettingsPath" -ForegroundColor Green
    Write-Host ""

    # Attempt claude CLI install for each plugin (non-fatal if claude not in PATH)
    $claudeCmd = Get-Command 'claude' -ErrorAction SilentlyContinue
    if ($claudeCmd) {
        Write-Host "    [claude CLI] Installing plugins at project scope..." -ForegroundColor Cyan
        Push-Location $Target
        try {
            foreach ($name in $PluginNames) {
                Write-Host "      claude plugin install ${name}@${MarketplaceName} --scope project" -ForegroundColor DarkGray
                & claude plugin install "${name}@${MarketplaceName}" --scope project 2>&1 | ForEach-Object {
                    Write-Host "      $_" -ForegroundColor DarkGray
                }
            }
        } finally {
            Pop-Location
        }
    } else {
        Write-Host "    [!] 'claude' CLI not found in PATH. Plugin entries written to settings.json." -ForegroundColor Yellow
        Write-Host "        To complete install, restart Claude Code in $Target." -ForegroundColor Yellow
        Write-Host "        Claude Code will pick up the enabledPlugins from .claude/settings.json." -ForegroundColor Yellow
    }
}

# ============================================================
# PHASE 3 - Write .claudeignore to target project
# ============================================================
Write-Host "  [Phase 3] Writing .claudeignore to target project..." -ForegroundColor Yellow

$claudeIgnoreSrc = Join-Path $ScriptRoot '.claudeignore'
$claudeIgnoreDest = Join-Path $Target '.claudeignore'

if (Test-Path $claudeIgnoreSrc) {
    if (-not (Test-Path $claudeIgnoreDest) -or $Force) {
        Copy-Item -Path $claudeIgnoreSrc -Destination $claudeIgnoreDest -Force
        Write-Host "    [+] Written: $claudeIgnoreDest" -ForegroundColor Green
    } else {
        Write-Host "    [=] Exists (use -Force to overwrite): $claudeIgnoreDest" -ForegroundColor DarkGray
    }
} else {
    Write-Host "    [!] No .claudeignore found in $ScriptRoot — skipping." -ForegroundColor Yellow
}

Write-Host ""

if ($PluginsOnly) {
    Write-Host "  ====================================================" -ForegroundColor Green
    Write-Host "  Plugins + .claudeignore installed to $Target" -ForegroundColor Green
    Write-Host "  ====================================================" -ForegroundColor Green
    Write-Host ""
    exit 0
}

# ============================================================
# PHASE 4 - Copy .claude/ harness to target project
# ============================================================
Write-Host "  [Phase 4] Copying .claude/ harness to target project..." -ForegroundColor Yellow
Write-Host ""

# --- Validate source directories exist ---
foreach ($dir in $Directories) {
    $srcPath = Join-Path $ScriptRoot $dir
    if (-not (Test-Path $srcPath)) {
        Write-Host "  ERROR: Source directory '$dir' not found at $ScriptRoot" -ForegroundColor Red
        exit 1
    }
}

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
    $marker = if ($existing -contains $dir) { " (exists - will overwrite)" } else { "" }
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

    $items = Get-ChildItem -Path $srcPath -Recurse
    foreach ($item in $items) {
        $relativePath = $item.FullName.Substring($srcPath.Length)
        $destItem = Join-Path $destPath $relativePath

        if ($item.PSIsContainer) {
            if (-not (Test-Path $destItem)) {
                New-Item -Path $destItem -ItemType Directory -Force | Out-Null
            }
        } else {
            # Skip README.md files — they are repo documentation, not runtime files
            if ($item.Name -eq 'README.md') { continue }
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
Write-Host "  Next steps:" -ForegroundColor Cyan
Write-Host "    1. Open $Target in Claude Code" -ForegroundColor White
Write-Host "    2. Plugins will activate automatically from .claude/settings.json" -ForegroundColor White
Write-Host "    3. Type 'orchestrator' or run /orchestrator:start <project-name>" -ForegroundColor White
Write-Host ""
