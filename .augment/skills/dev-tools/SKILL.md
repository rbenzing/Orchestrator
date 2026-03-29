---
name: dev-tools
description: PowerShell developer tools for file searching, directory traversal, and git operations on Windows. Hardened for non-interactive AI agent execution with named parameters and stray-argument catching.
---

# Dev Tools

PowerShell scripts for common developer tasks. All scripts use mandatory named parameters, catch stray arguments, and output structured text.

## Scripts

### `grep.ps1` — Search file contents by regex
```
.augment\skills\dev-tools\scripts\grep.ps1 -Pattern "TODO|FIXME"
.augment\skills\dev-tools\scripts\grep.ps1 -Pattern "class\s+\w+" -Include "*.cs" -Context 2
```
Params: `-Pattern` (required), `-Path`, `-Include`, `-Context`, `-CaseSensitive`, `-MaxResults`

### `find-files.ps1` — Find files by name pattern
```
.augment\skills\dev-tools\scripts\find-files.ps1 -Name "*.test.ts"
.augment\skills\dev-tools\scripts\find-files.ps1 -Name "Controller" -Regex
.augment\skills\dev-tools\scripts\find-files.ps1 -Name "components" -DirectoriesOnly
```
Params: `-Name` (required), `-Path`, `-Regex`, `-DirectoriesOnly`, `-MaxResults`

### `tree.ps1` — Directory tree with depth control
```
.augment\skills\dev-tools\scripts\tree.ps1
.augment\skills\dev-tools\scripts\tree.ps1 -Path "src" -Depth 4 -ShowFiles
```
Params: `-Path`, `-Depth`, `-ShowFiles`

### `git-summary.ps1` — Branch, status, and recent commits
```
.augment\skills\dev-tools\scripts\git-summary.ps1
.augment\skills\dev-tools\scripts\git-summary.ps1 -LogCount 20 -ShowStash
```
Params: `-Path`, `-LogCount`, `-ShowStash`

### `git-diff.ps1` — Staged, unstaged, or ref-based diffs
```
.augment\skills\dev-tools\scripts\git-diff.ps1
.augment\skills\dev-tools\scripts\git-diff.ps1 -Staged -NameOnly
.augment\skills\dev-tools\scripts\git-diff.ps1 -Ref1 "main" -Stat
```
Params: `-Staged`, `-Ref1`, `-Ref2`, `-Path`, `-FilePath`, `-Stat`, `-NameOnly`

### `kill-port.ps1` — Kill process by TCP port or PID
```
.augment\skills\dev-tools\scripts\kill-port.ps1 -Port 3000
.augment\skills\dev-tools\scripts\kill-port.ps1 -Port 3000 -Force
.augment\skills\dev-tools\scripts\kill-port.ps1 -ProcessId 12345 -Force
```
Params: `-Port` OR `-ProcessId` (one required), `-Force`, `-ProcessName`

> Dry-run by default. Critical Windows processes are always protected.

### `remove-files.ps1` — Safely remove files or directories
```
.augment\skills\dev-tools\scripts\remove-files.ps1 -Path "temp.log"
.augment\skills\dev-tools\scripts\remove-files.ps1 -Path "dist","coverage" -Recurse -Force
.augment\skills\dev-tools\scripts\remove-files.ps1 -Path "src\old-module" -Recurse
```
Params: `-Path` (required, accepts array), `-Recurse`, `-Force`, `-Quiet`

> Dry-run by default. BLOCKS any path outside the working directory, parent traversal (`..\`), system directories, `.git`, `.augment`, and `node_modules`. Use this instead of `Remove-Item` or the `remove-files` tool.

## Rules
- Git-aware: uses `git ls-files` when available, excludes `.git`, `node_modules`, `bin`, `obj`
- Always use **named parameters** — no positional binding
- Every value must be a **literal string** — never use `$` variables
- **Never use `Remove-Item` directly** — use `remove-files.ps1` instead
- **Never use the `remove-files` IDE tool** — use `remove-files.ps1` instead
- **Never use the `kill-process` IDE tool** — use `kill-port.ps1` instead

