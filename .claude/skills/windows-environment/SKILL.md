---
name: windows-environment
description: Windows environment guide and PowerShell filesystem operation scripts (mkdir, copy, move, rename). Hardened for non-interactive AI agent execution with named parameters, safety guards, and stray-argument catching.
---

# Windows Environment Guide

You are operating on a **Windows** machine. This guide prevents common mistakes AI agents make when assuming Linux or macOS.

## Filesystem Scripts

PowerShell scripts for safe filesystem operations. All scripts block writes to protected directories (`.git`, `.claude`).

### `make-dir.ps1` — Create directories
```
.claude\skills\windows-environment\scripts\make-dir.ps1 -Path "src\components"
.claude\skills\windows-environment\scripts\make-dir.ps1 -Path "src\models","src\services","src\utils"
```
Params: `-Path` (required, accepts array)

### `copy-item.ps1` — Copy files or directories
```
.claude\skills\windows-environment\scripts\copy-item.ps1 -Source "template.json" -Destination "config.json"
.claude\skills\windows-environment\scripts\copy-item.ps1 -Source "templates\base" -Destination "src\new-module" -Recurse
```
Params: `-Source` (required), `-Destination` (required), `-Recurse`, `-Force`

### `move-item.ps1` — Move files or directories
```
.claude\skills\windows-environment\scripts\move-item.ps1 -Source "old-name.ts" -Destination "new-name.ts"
.claude\skills\windows-environment\scripts\move-item.ps1 -Source "src\legacy" -Destination "src\deprecated"
```
Params: `-Source` (required), `-Destination` (required), `-Force`

### `rename-item.ps1` — Rename a file or directory in place
```
.claude\skills\windows-environment\scripts\rename-item.ps1 -Path "src\utils.js" -NewName "helpers.js"
.claude\skills\windows-environment\scripts\rename-item.ps1 -Path "src\old-module" -NewName "new-module"
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
| Find text in files | `grep -r "pattern" .` | **`.claude\skills\dev-tools\scripts\grep.ps1 -Pattern "pattern"`** |
| Find files | `find . -name "*.js"` | **`.claude\skills\dev-tools\scripts\find-files.ps1 -Name "*.js"`** |
| Directory tree | `tree` / `ls -R` | **`.claude\skills\dev-tools\scripts\tree.ps1 -Path "src" -Depth 3`** |
| Git status | `git log; git status` | **`.claude\skills\dev-tools\scripts\git-summary.ps1`** |
| Git diff | `git diff --stat` | **`.claude\skills\dev-tools\scripts\git-diff.ps1 -Stat`** |
| Kill process/port | `kill -9 PID` | **`.claude\skills\dev-tools\scripts\kill-port.ps1 -Port 3000 -Force`** |
| Environment variable | `echo $HOME` | `$env:USERPROFILE` or `$env:HOME` |
| Set env var | `export FOO=bar` | `$env:FOO = "bar"` |
| Chain commands | `cmd1 && cmd2` | `cmd1; if ($?) { cmd2 }` |
| Redirect stderr | `2>/dev/null` | `2>$null` |
| Null device | `/dev/null` | `$null` or `NUL` |
| Which/where | `which git` | `Get-Command git` or `where.exe git` |
| Process list | `ps aux` | `Get-Process` |
| File permissions | `chmod +x file` | Not applicable (use `Unblock-File` for downloaded scripts) |
| Create directory | `mkdir -p path/to/dir` | `New-Item -ItemType Directory -Path "path\to\dir" -Force` |
| Remove directory | `rm -rf dir` | `Remove-Item -Recurse -Force dir` |
| Cat file | `cat file.txt` | `Get-Content file.txt` |
| Head/tail | `head -20 file` | `Get-Content file -TotalCount 20` / `Get-Content file -Tail 20` |
| Curl | `curl -s URL` | `Invoke-RestMethod URL` or `Invoke-WebRequest URL` |

> **IMPORTANT**: For tasks with **bold** entries above, ALWAYS use the toolkit script instead of raw PowerShell commands. See `.claude/skills/dev-tools/SKILL.md` and `.claude/skills/nodejs-windows/SKILL.md` for full parameter details.

## Path Separators

- Windows uses **backslashes**: `C:\Users\dev\project\src\file.cs`
- Forward slashes work in most contexts but not all (especially native Windows APIs)
- Use `Join-Path` to build paths safely: `Join-Path $env:USERPROFILE "project" "src"`
- Use `[System.IO.Path]::Combine()` for multi-segment paths

### Common Path Variables

| Variable | Windows | Linux/Mac equivalent |
|----------|---------|---------------------|
| Home directory | `$env:USERPROFILE` | `$HOME` or `~` |
| Temp directory | `$env:TEMP` | `/tmp` |
| Program Files | `$env:ProgramFiles` | `/usr/local` |
| App Data | `$env:APPDATA` | `~/.config` |
| Current dir | `$PWD` or `Get-Location` | `$PWD` |

## Line Endings

- Windows uses `\r\n` (CRLF), Linux/Mac uses `\n` (LF)
- Git usually handles this via `core.autocrlf`
- When writing files, be aware of encoding: PowerShell defaults to UTF-16 LE BOM
- Use `-Encoding utf8` or `-Encoding utf8NoBOM` when writing files:
  ```powershell
  Set-Content -Path "file.txt" -Value $content -Encoding utf8
  ```

## Case Sensitivity

- Windows file system is **case-insensitive** (but case-preserving)
- `File.txt` and `file.txt` are the **same file** on Windows
- Do NOT create files that differ only by case — it will cause conflicts

## Running Scripts

- PowerShell execution policy may block scripts. If needed:
  ```powershell
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  ```
- Run `.ps1` scripts directly: `.\script.ps1` (note the `.\` prefix for current directory)
- Python: `python script.py` (not `python3` — Windows typically uses `python`)
- Node.js: `node script.js` (same as Linux)

## Package Managers

| Tool | Windows command |
|------|----------------|
| Node.js packages | `npm install` / `yarn` / `pnpm` |
| Python packages | `pip install` (not `pip3`) |
| .NET packages | `dotnet add package` |
| System packages | `winget install` or `choco install` |

## Process & Port Management

**ALWAYS use the toolkit script** instead of raw commands:

```powershell
# ❌ WRONG — raw commands are fragile and miss safety checks:
Get-NetTCPConnection -LocalPort 3000 | Select-Object OwningProcess
Stop-Process -Id (Get-NetTCPConnection -LocalPort 3000).OwningProcess -Force

# ✅ RIGHT — dry-run by default, protects critical processes:
.claude\skills\dev-tools\scripts\kill-port.ps1 -Port 3000
.claude\skills\dev-tools\scripts\kill-port.ps1 -Port 3000 -Force
.claude\skills\dev-tools\scripts\kill-port.ps1 -ProcessId 12345 -Force
```

## CRITICAL: Forbidden Patterns -- Use Toolkit Scripts Instead

**The shell is PowerShell. NEVER use cmd.exe, batch syntax, or bash/Unix commands.**

### Forbidden Patterns and Their Toolkit Replacements

```
❌ cmd /c "anything"                    — NEVER shell out to cmd.exe
❌ cmd /c "set NODE_OPTIONS=... && ng test" — Use angular-windows run-tests.ps1 -LegacyOpenSSL
❌ cmd /c "run-tests.cmd"               — Just run: .\run-tests.cmd (native in PowerShell)
❌ cmd /c "dir /s /b *.js" 2>nul        — Use find-files.ps1
❌ cmd /c "command1 & command2"          — Batch & chaining is invalid
❌ for /r %f in (*.js) do @echo %f      — Use find-files.ps1
❌ dir /s /b                             — Use find-files.ps1 or tree.ps1
❌ 2>nul                                 — Batch null redirect (use 2>$null)
❌ command1 && command2                  — Not valid in PowerShell 5.1
❌ grep -r "pattern" .                   — Use grep.ps1
❌ find . -name "*.js" -type f           — Use find-files.ps1
❌ cat file | head -20                   — Use Get-Content -TotalCount 20
❌ cd path && npm test                   — Use run-tests.ps1
❌ cd path && ng test                    — Use angular-windows run-tests.ps1
❌ $myVar = "foo"; command -Arg $myVar   — $ variables get stripped (see below)
❌ Select-String -Recurse               — Use grep.ps1 (handles .gitignore, excludes)
❌ Get-ChildItem -Recurse -Filter       — Use find-files.ps1 (handles excludes)
❌ Get-NetTCPConnection + Stop-Process   — Use kill-port.ps1 (has safety guards)
```

### Correct Replacements

```powershell
# ❌ WRONG: cmd /c "dir /s /b src\__tests__\*.js" 2>nul & for /r ...
# ✅ RIGHT:
.claude\skills\dev-tools\scripts\find-files.ps1 -Name "*.js" -Path "src\__tests__"

# ❌ WRONG: find . -name "*.test.js" -type f
# ✅ RIGHT:
.claude\skills\dev-tools\scripts\find-files.ps1 -Name "*.test.js"

# ❌ WRONG: grep -r "import" src/
# ❌ ALSO WRONG: Select-String -Path "src\**\*.js" -Pattern "import" -Recurse
# ✅ RIGHT:
.claude\skills\dev-tools\scripts\grep.ps1 -Pattern "import" -Path "src" -Include "*.js"

# ❌ WRONG: cmd /c "dir /s /b" to list files
# ✅ RIGHT:
.claude\skills\dev-tools\scripts\tree.ps1 -Path "." -ShowFiles

# ❌ WRONG: cd path && npm test
# ✅ RIGHT:
.claude\skills\nodejs-windows\scripts\run-tests.ps1 -ProjectPath "ClientApp"

# ❌ WRONG: cmd /c "cd /d C:\app && set NODE_OPTIONS=--openssl-legacy-provider && ng test"
# ✅ RIGHT:
.claude\skills\angular-windows\scripts\run-tests.ps1 -ProjectPath "C:\app" -LegacyOpenSSL -Headless

# ❌ WRONG: cmd /c "run-tests.cmd"
# ✅ RIGHT — .cmd files run natively in PowerShell:
.\run-tests.cmd

# ❌ WRONG: cmd /c "ng build --configuration production"
# ✅ RIGHT:
.claude\skills\angular-windows\scripts\run-build.ps1 -ProjectPath "ClientApp" -Configuration "production"
```

### CRITICAL: Never Use PowerShell Variables in Terminal Commands

The `launch-process` tool wraps every command with `powershell -NoLogo -NonInteractive -Command ...`.
This means **`$` variables are interpolated by the outer shell and become empty strings** before your
script ever sees them.

```
❌ WRONG — variable is stripped to empty string:
$name = "user-auth"; .claude\skills\orchestration-artifacts\scripts\init-project.ps1 -ProjectName $name

❌ WRONG — $env variables also get stripped:
Write-Host $env:TEMP

✅ RIGHT — always use literal values directly:
.claude\skills\orchestration-artifacts\scripts\init-project.ps1 -ProjectName "user-auth"

✅ RIGHT — toolkit scripts handle env vars internally:
.claude\skills\dev-tools\scripts\git-summary.ps1

✅ RIGHT — if you must compose, use inline expressions:
Get-ChildItem -Path (Join-Path "orchestration" "artifacts") -Recurse
```

**Rule: Every parameter value in a terminal command MUST be a literal string. Never assign to a `$variable` and reference it later.**

### Use Toolkit Scripts Instead of Raw Commands

```powershell
# Find files (replaces: dir /s /b *.js, find . -name "*.js", Get-ChildItem -Recurse)
.claude\skills\dev-tools\scripts\find-files.ps1 -Name "*.js"
.claude\skills\dev-tools\scripts\find-files.ps1 -Name "*.jsx" -Path "src"

# Search file contents (replaces: grep -r "pattern" ., Select-String -Recurse)
.claude\skills\dev-tools\scripts\grep.ps1 -Pattern "pattern" -Include "*.js"
.claude\skills\dev-tools\scripts\grep.ps1 -Pattern "TODO|FIXME" -Path "src" -Context 2

# Directory listing (replaces: dir, Get-ChildItem, tree)
.claude\skills\dev-tools\scripts\tree.ps1 -Path "src" -Depth 3 -ShowFiles

# Git operations (replaces: git log, git status, git diff)
.claude\skills\dev-tools\scripts\git-summary.ps1
.claude\skills\dev-tools\scripts\git-diff.ps1 -Stat

# Kill process on port (replaces: Get-NetTCPConnection + Stop-Process)
.claude\skills\dev-tools\scripts\kill-port.ps1 -Port 3000 -Force

# Run Node.js tests (replaces: cd path && npm test, Push-Location; npm test; Pop-Location)
.claude\skills\nodejs-windows\scripts\run-tests.ps1 -ProjectPath "ClientApp"

# Lint code (replaces: cd path && npm run lint)
.claude\skills\nodejs-windows\scripts\run-lint.ps1 -ProjectPath "ClientApp" -Fix

# Build project (replaces: cd path && npm run build)
.claude\skills\nodejs-windows\scripts\run-build.ps1 -ProjectPath "ClientApp"
```

### PowerShell Syntax (no toolkit script needed)

```powershell
# Chain commands (replaces: command1 && command2)
command1; if ($?) { command2 }

# Redirect stderr to null (replaces: 2>nul)
command 2>$null

# Read file contents (replaces: cat file, head -20)
Get-Content "file.txt"
Get-Content "file.txt" -TotalCount 20
Get-Content "file.txt" -Tail 20
```

### Why This Matters

PowerShell parses the ENTIRE command line before executing. Batch syntax characters like `&`, `for /r`, and `2>nul` cause **parse errors** — the command never even runs. This is not a compatibility issue; it is a fundamental syntax mismatch.

## Common Gotchas

1. **`ls` is an alias for `Get-ChildItem`** — it works but returns objects, not text. Don't pipe it expecting Unix `ls` output format.
2. **`rm` is an alias for `Remove-Item`** — it works but doesn't support `-rf`. Use `-Recurse -Force` instead.
3. **`cat` is an alias for `Get-Content`** — returns an array of lines, not a single string.
4. **Semicolons, not `&&`** — PowerShell uses `;` to chain commands. `&&` works in PowerShell 7+ but not in Windows PowerShell 5.1.
5. **Single vs double quotes** — PowerShell only interpolates variables in double quotes: `"$var"` expands, `'$var'` is literal.
6. **`select` is an alias for `Select-Object`** — not the Unix `select` command.
7. **Long paths** — Windows has a 260-character path limit by default. Deep `node_modules` can hit this.
8. **NEVER use `cmd /c`** — Do not shell out to `cmd.exe`. All commands must be native PowerShell.
9. **NEVER use batch syntax** — No `&` chaining, no `for /r`, no `dir /s /b`, no `2>nul`. Use PowerShell equivalents.
10. **NEVER use `$` variables in terminal commands** — They get stripped by the launch-process wrapper. Always use literal string values.

