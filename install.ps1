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
            Write-Host "    [!] Could not parse existing settings.json - creating backup and replacing." -ForegroundColor Yellow
            Copy-Item $targetSettingsPath "$targetSettingsPath.bak" -Force
            $settings = [PSCustomObject]@{}
        }
    } else {
        $settings = [PSCustomObject]@{}
    }

    # Add or update extraKnownMarketplaces (directory source — relative to target project root)
    $mktSource  = [PSCustomObject]@{ source = 'directory'; path = '.claude/plugins' }
    $mktEntry   = [PSCustomObject]@{ source = $mktSource }
    if (-not ($settings.PSObject.Properties.Name -contains 'extraKnownMarketplaces')) {
        $mkts = [PSCustomObject]@{}
        $mkts | Add-Member -NotePropertyName $MarketplaceName -NotePropertyValue $mktEntry
        $settings | Add-Member -NotePropertyName 'extraKnownMarketplaces' -NotePropertyValue $mkts
        Write-Host "    [+] Registered marketplace '$MarketplaceName' -> .claude/plugins" -ForegroundColor Green
    } else {
        if (-not ($settings.extraKnownMarketplaces.PSObject.Properties.Name -contains $MarketplaceName)) {
            $settings.extraKnownMarketplaces | Add-Member -NotePropertyName $MarketplaceName -NotePropertyValue $mktEntry
            Write-Host "    [+] Registered marketplace '$MarketplaceName' -> .claude/plugins" -ForegroundColor Green
        } else {
            $settings.extraKnownMarketplaces.$MarketplaceName = $mktEntry
            Write-Host "    [=] Updated marketplace '$MarketplaceName' path" -ForegroundColor DarkGray
        }
    }

    # Add or update enabledPlugins ("name@marketplace": true)
    if (-not ($settings.PSObject.Properties.Name -contains 'enabledPlugins')) {
        $enabled = [PSCustomObject]@{}
        foreach ($name in $PluginNames) {
            $enabled | Add-Member -NotePropertyName "$name@$MarketplaceName" -NotePropertyValue $true
        }
        $settings | Add-Member -NotePropertyName 'enabledPlugins' -NotePropertyValue $enabled
    } else {
        foreach ($name in $PluginNames) {
            $key = "$name@$MarketplaceName"
            if (-not ($settings.enabledPlugins.PSObject.Properties.Name -contains $key)) {
                $settings.enabledPlugins | Add-Member -NotePropertyName $key -NotePropertyValue $true
            }
        }
    }

    foreach ($name in $PluginNames) {
        Write-Host "    [+] Enabled plugin: $name@$MarketplaceName" -ForegroundColor Green
    }

    # Set defaultMode to allowAll so agents run autonomously without per-command prompts.
    # The deny list below still blocks destructive operations.
    if (-not ($settings.PSObject.Properties.Name -contains 'defaultMode')) {
        $settings | Add-Member -NotePropertyName 'defaultMode' -NotePropertyValue 'allowAll'
        Write-Host "    [+] Set defaultMode: allowAll" -ForegroundColor Green
    } else {
        $settings.defaultMode = 'allowAll'
        Write-Host "    [=] Updated defaultMode: allowAll" -ForegroundColor DarkGray
    }

    # Add permissions block if not already present
    if (-not ($settings.PSObject.Properties.Name -contains 'permissions')) {
        $permissions = [PSCustomObject]@{
            allow = @(
                "Bash(.claude/orchestrator/**)"
                "Bash(.claude\orchestrator\**)"
            )
            deny = @(
                "Bash(git push*)"
                "Bash(git merge*)"
                "Bash(git rebase*)"
                "Bash(git reset --hard*)"
                "Bash(git clean*)"
                "Bash(rm -rf*)"
                "Bash(Remove-Item*-Recurse*)"
                "Bash(sudo*)"
                "Bash(runas*)"
                "Bash(shutdown*)"
                "Bash(Restart-Computer*)"
                "Bash(Stop-Computer*)"
                "Bash(Set-ExecutionPolicy*)"
                "Bash(net user*)"
                "Bash(net localgroup*)"
                "Bash(npm publish*)"
                "Bash(dotnet publish*)"
                "Bash(curl*|*sh)"
                "Bash(iex*WebClient*)"
                "Bash(Invoke-Expression*Download*)"
            )
        }
        $settings | Add-Member -NotePropertyName 'permissions' -NotePropertyValue $permissions
        Write-Host "    [+] Written permissions security block" -ForegroundColor Green
    } else {
        Write-Host "    [=] permissions already present - skipping" -ForegroundColor DarkGray
    }

    # Write updated settings.json
    $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $targetSettingsPath -Encoding UTF8
    Write-Host "    [+] Written: $targetSettingsPath" -ForegroundColor Green
    Write-Host ""

    Write-Host "    [i] Plugin files will be copied to $Target\.claude\plugins\" -ForegroundColor Cyan
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
    Write-Host "    [!] No .claudeignore found in $ScriptRoot - skipping." -ForegroundColor Yellow
}

Write-Host ""

# ============================================================
# PHASE 4 - Copy plugin files into target project
# Copies plugins/orchestrator and plugins/windows-dev-toolkit
# into {target}/.claude/plugins/ and writes marketplace manifest
# ============================================================
if (-not $SkipPlugins) {
    Write-Host "  [Phase 4] Copying plugin files to $Target\.claude\plugins\..." -ForegroundColor Yellow
    Write-Host ""

    $targetPluginsDir = Join-Path $Target '.claude\plugins'

    # Write marketplace manifest (always overwrite - it is installer-generated)
    $mktManifestDir  = Join-Path $targetPluginsDir '.claude-plugin'
    $mktManifestPath = Join-Path $mktManifestDir 'marketplace.json'
    if (-not (Test-Path $mktManifestDir)) {
        New-Item -Path $mktManifestDir -ItemType Directory -Force | Out-Null
    }
    $mktManifest = [PSCustomObject]@{
        name  = $MarketplaceName
        owner = [PSCustomObject]@{ name = 'rbenzing' }
        plugins = @(
            [PSCustomObject]@{ name = 'orchestrator';        source = './orchestrator' }
            [PSCustomObject]@{ name = 'windows-dev-toolkit'; source = './windows-dev-toolkit' }
        )
    }
    $mktManifest | ConvertTo-Json -Depth 5 | Set-Content -Path $mktManifestPath -Encoding UTF8
    Write-Host "    [+] Written: $mktManifestPath" -ForegroundColor Green

    # Copy each plugin directory (never overwrite existing files)
    $pluginCopied = 0
    $pluginSkipped = 0
    foreach ($name in $PluginNames) {
        $srcPlugin  = Join-Path $ScriptRoot "plugins\$name"
        $destPlugin = Join-Path $targetPluginsDir $name

        if (-not (Test-Path $srcPlugin)) {
            Write-Host "    [!] Plugin source not found: $srcPlugin" -ForegroundColor Yellow
            continue
        }

        $items = Get-ChildItem -Path $srcPlugin -Recurse
        foreach ($item in $items) {
            $relativePath = $item.FullName.Substring($srcPlugin.Length)
            $destItem     = Join-Path $destPlugin $relativePath

            if ($item.PSIsContainer) {
                if (-not (Test-Path $destItem)) {
                    New-Item -Path $destItem -ItemType Directory -Force | Out-Null
                }
            } else {
                if ($item.Name -eq 'README.md') { continue }
                $destDir = Split-Path -Parent $destItem
                if (-not (Test-Path $destDir)) {
                    New-Item -Path $destDir -ItemType Directory -Force | Out-Null
                }
                if (Test-Path $destItem) {
                    $pluginSkipped++
                    Write-Host "    = plugins\$name$relativePath" -ForegroundColor DarkGray
                } else {
                    Copy-Item -Path $item.FullName -Destination $destItem
                    $pluginCopied++
                    Write-Host "    + plugins\$name$relativePath" -ForegroundColor DarkGreen
                }
            }
        }
    }

    Write-Host ""
    Write-Host "    [+] Plugins: $pluginCopied new files copied, $pluginSkipped existing skipped." -ForegroundColor Green
    Write-Host ""
}

if ($PluginsOnly) {
    Write-Host "  ====================================================" -ForegroundColor Green
    Write-Host "  Plugins + .claudeignore installed to $Target" -ForegroundColor Green
    Write-Host "  Open $Target in Claude Code to activate." -ForegroundColor Green
    Write-Host "  ====================================================" -ForegroundColor Green
    Write-Host ""
    exit 0
}

# ============================================================
# PHASE 5 - Copy .claude/ harness to target project
# ============================================================
Write-Host "  [Phase 5] Copying .claude/ harness to target project..." -ForegroundColor Yellow
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
    $marker = if ($existing -contains $dir) { " (exists - new files only)" } else { "" }
    Write-Host "  [DIR] $dir/ - $count files$marker" -ForegroundColor White
}
Write-Host ""
Write-Host "  Total: $totalFiles source files. Existing files in target will not be overwritten." -ForegroundColor White
Write-Host ""

$confirm = Read-Host "  Proceed? (Y/n)"
if ($confirm -and $confirm -notin @('y', 'Y', 'yes', 'Yes', 'YES')) {
    Write-Host ""
    Write-Host "  Cancelled." -ForegroundColor DarkGray
    exit 0
}

# --- Copy (never overwrite — skip files that already exist) ---
Write-Host ""
$copiedCount = 0
$skippedCount = 0
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
            # Skip README.md files - they are repo documentation, not runtime files
            if ($item.Name -eq 'README.md') { continue }
            $destDir = Split-Path -Parent $destItem
            if (-not (Test-Path $destDir)) {
                New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            }
            if (Test-Path $destItem) {
                $skippedCount++
                Write-Host "  = $dir$relativePath" -ForegroundColor DarkGray
            } else {
                Copy-Item -Path $item.FullName -Destination $destItem
                $copiedCount++
                Write-Host "  + $dir$relativePath" -ForegroundColor DarkGreen
            }
        }
    }
}

Write-Host ""
Write-Host "  ====================================================" -ForegroundColor Green
Write-Host "  Done! Copied $copiedCount new files, skipped $skippedCount existing." -ForegroundColor Green
Write-Host "  ====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Cyan
Write-Host "    1. Open $Target in Claude Code" -ForegroundColor White
Write-Host "    2. Plugins will activate automatically from .claude/settings.json" -ForegroundColor White
Write-Host "    3. Type 'orchestrator' or run /orchestrator:start <project-name>" -ForegroundColor White
Write-Host ""
