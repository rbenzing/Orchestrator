---
name: windows-environment
description: Windows environment guide and PowerShell filesystem operation scripts (mkdir, copy, move, rename). Hardened for non-interactive AI agent execution with named parameters, safety guards, and stray-argument catching.
---

# Windows Environment Guide

You are operating on a **Windows** machine. This guide prevents common mistakes AI agents make when assuming Linux or macOS.

## Filesystem Scripts

PowerShell scripts for safe filesystem operations. All scripts block writes to protected directories (`.git`, `.claude`).

### `make-dir.ps1` — Create directories
```powershell
${CLAUDE_PLUGIN_ROOT}\skills\windows-environment\scripts\make-dir.ps1 -Path "src\components"
${CLAUDE_PLUGIN_ROOT}\skills\windows-environment\scripts\make-dir.ps1 -Path "src\models","src\services","src\utils"
```
Params: `-Path` (required, accepts array)

### `copy-item.ps1` — Copy files or directories
```powershell
${CLAUDE_PLUGIN_ROOT}\skills\windows-environment\scripts\copy-item.ps1 -Source "template.json" -Destination "config.json"
${CLAUDE_PLUGIN_ROOT}\skills\windows-environment\scripts\copy-item.ps1 -Source "templates\base" -Destination "src\new-module" -Recurse
```
Params: `-Source` (required), `-Destination` (required), `-Recurse`, `-Force`

### `move-item.ps1` — Move files or directories
```powershell
${CLAUDE_PLUGIN_ROOT}\skills\windows-environment\scripts\move-item.ps1 -Source "old-name.ts" -Destination "new-name.ts"
${CLAUDE_PLUGIN_ROOT}\skills\windows-environment\scripts\move-item.ps1 -Source "src\legacy" -Destination "src\deprecated"
```
Params: `-Source` (required), `-Destination` (required), `-Force`

### `rename-item.ps1` — Rename a file or directory in place
```powershell
${CLAUDE_PLUGIN_ROOT}\skills\windows-environment\scripts\rename-item.ps1 -Path "src\utils.js" -NewName "helpers.js"
${CLAUDE_PLUGIN_ROOT}\skills\windows-environment\scripts\rename-item.ps1 -Path "src\old-module" -NewName "new-module"
```
Params: `-Path` (required), `-NewName` (required)

### Filesystem Script Rules
- Always use **named parameters** — no positional binding
- Every value must be a **literal string** — never use `$` variables
- **Never use mkdir/New-Item/Copy-Item/Move-Item/Rename-Item directly** — use these scripts instead
- All scripts block paths into protected directories (.git, .claude)

## Shell: PowerShell (not bash)

The default shell is **PowerShell**. Do NOT use bash syntax.

| Task | ❌ Bash (wrong) | ✅ Correct |
|------|----------------|------------------------|
| List files | `ls -la` | `Get-ChildItem` or `dir` |
| Find text in files | `grep -r "pattern" .` | **`${CLAUDE_PLUGIN_ROOT}\skills\dev-tools\scripts\grep.ps1 -Pattern "pattern"`** |
| Find files | `find . -name "*.js"` | **`${CLAUDE_PLUGIN_ROOT}\skills\dev-tools\scripts\find-files.ps1 -Name "*.js"`** |
| Directory tree | `tree` / `ls -R` | **`${CLAUDE_PLUGIN_ROOT}\skills\dev-tools\scripts\tree.ps1 -Path "src" -Depth 3`** |
| Git status | `git log; git status` | **`${CLAUDE_PLUGIN_ROOT}\skills\dev-tools\scripts\git-summary.ps1`** |
| Git diff | `git diff --stat` | **`${CLAUDE_PLUGIN_ROOT}\skills\dev-tools\scripts\git-diff.ps1 -Stat`** |
| Kill process/port | `kill -9 PID` | **`${CLAUDE_PLUGIN_ROOT}\skills\dev-tools\scripts\kill-port.ps1 -Port 3000 -Force`** |
| Environment variable | `echo $HOME` | `$env:USERPROFILE` or `$env:HOME` |
| Set env var | `export FOO=bar` | `$env:FOO = "bar"` |
| Chain commands | `cmd1 && cmd2` | `cmd1; if ($?) { cmd2 }` |
| Redirect stderr | `2>/dev/null` | `2>$null` |
| Null device | `/dev/null` | `$null` or `NUL` |
| Which/where | `which git` | `Get-Command git` or `where.exe git` |

> **IMPORTANT**: For tasks with **bold** entries above, ALWAYS use the toolkit script instead of raw PowerShell commands.

## CRITICAL: Forbidden Patterns — Use Toolkit Scripts Instead

**The shell is PowerShell. NEVER use cmd.exe, batch syntax, or bash/Unix commands.**

```
❌ cmd /c "anything"                         — NEVER shell out to cmd.exe
❌ command1 && command2                       — Not valid in PowerShell 5.1
❌ grep -r "pattern" .                        — Use grep.ps1
❌ find . -name "*.js" -type f               — Use find-files.ps1
❌ $myVar = "foo"; command -Arg $myVar        — $ variables get stripped (use literals)
❌ Select-String -Recurse                     — Use grep.ps1
❌ Get-ChildItem -Recurse -Filter            — Use find-files.ps1
❌ Get-NetTCPConnection + Stop-Process        — Use kill-port.ps1
```

### Correct Replacements

```powershell
# Find files
${CLAUDE_PLUGIN_ROOT}\skills\dev-tools\scripts\find-files.ps1 -Name "*.test.ts"
${CLAUDE_PLUGIN_ROOT}\skills\dev-tools\scripts\find-files.ps1 -Name "*.js" -Path "src\__tests__"

# Search file contents
${CLAUDE_PLUGIN_ROOT}\skills\dev-tools\scripts\grep.ps1 -Pattern "import" -Path "src" -Include "*.js"

# Directory listing
${CLAUDE_PLUGIN_ROOT}\skills\dev-tools\scripts\tree.ps1 -Path "." -ShowFiles

# Run Node.js tests
${CLAUDE_PLUGIN_ROOT}\skills\nodejs-windows\scripts\run-tests.ps1 -ProjectPath "ClientApp"

# Run Angular tests (headless, legacy SSL)
${CLAUDE_PLUGIN_ROOT}\skills\angular-windows\scripts\run-tests.ps1 -ProjectPath "ClientApp" -LegacyOpenSSL -Headless

# Angular build
${CLAUDE_PLUGIN_ROOT}\skills\angular-windows\scripts\run-build.ps1 -ProjectPath "ClientApp" -Configuration "production"

# Kill process on port
${CLAUDE_PLUGIN_ROOT}\skills\dev-tools\scripts\kill-port.ps1 -Port 3000 -Force
```

### CRITICAL: Never Use PowerShell Variables in Terminal Commands

The `launch-process` tool wraps commands with `powershell -NoLogo -NonInteractive -Command ...`.
`$` variables are interpolated by the outer shell and become empty strings before your script sees them.

```
❌ WRONG — variable is stripped to empty string:
$name = "user-auth"; someScript.ps1 -ProjectName $name

✅ RIGHT — always use literal values directly:
someScript.ps1 -ProjectName "user-auth"
```

**Rule: Every parameter value in a terminal command MUST be a literal string.**

### PowerShell Syntax (no toolkit script needed)

```powershell
# Chain commands (replaces: command1 && command2)
command1; if ($?) { command2 }

# Redirect stderr to null (replaces: 2>nul)
command 2>$null

# Read file contents
Get-Content "file.txt"
Get-Content "file.txt" -TotalCount 20
```

## Path Separators

- Windows uses **backslashes**: `C:\Users\dev\project\src\file.cs`
- Forward slashes work in most contexts but not all
- Use `Join-Path` to build paths safely

## Line Endings

- Windows uses `\r\n` (CRLF), Linux/Mac uses `\n` (LF)
- When writing files, use `-Encoding utf8` or `-Encoding utf8NoBOM`

## Case Sensitivity

- Windows file system is **case-insensitive** (but case-preserving)
- Do NOT create files that differ only by case

## Common Gotchas

1. **`ls` is an alias for `Get-ChildItem`** — returns objects, not text
2. **`rm` is an alias for `Remove-Item`** — use `-Recurse -Force` (not `-rf`)
3. **`cat` is an alias for `Get-Content`** — returns an array of lines
4. **Semicolons, not `&&`** — PowerShell uses `;` to chain. `&&` works in PowerShell 7+ but not 5.1
5. **Single vs double quotes** — PowerShell only interpolates variables in double quotes
6. **NEVER use `cmd /c`** — all commands must be native PowerShell
7. **NEVER use `$` variables in terminal commands** — they get stripped by launch-process
