---
type: "agent_requested"
description: "PowerShell environment rules for all agents"
---

# PowerShell Rules

**Shell: PowerShell on Windows.** Use `.claude/skills/` scripts — not raw commands.

## Toolkit Mapping

| Instead of | Use |
|------------|-----|
| `Get-ChildItem -Recurse \| Select-String` | `dev-tools\scripts\grep.ps1 -Pattern "..."` |
| `Get-ChildItem -Recurse -Filter "*.ts"` | `dev-tools\scripts\find-files.ps1 -Name "*.ts"` |
| `dir`, `tree` | `dev-tools\scripts\tree.ps1 -Path "src" -Depth 3` |
| `git log/status/branch` | `dev-tools\scripts\git-summary.ps1` |
| `git diff` | `dev-tools\scripts\git-diff.ps1 -Ref1 "main" -Stat` |
| `npm test` / `npx react-scripts test` | `nodejs-windows\scripts\run-tests.ps1 -ProjectPath "path"` |
| `cmd /c "set NODE_OPTIONS=... && ng test"` | `angular-windows\scripts\run-tests.ps1 -ProjectPath "path" -LegacyOpenSSL` |
| `Remove-Item` / `del` | `dev-tools\scripts\remove-files.ps1 -Path "dist" -Recurse` |

All script paths relative to `.claude\skills\`.

## Forbidden

- **No `cmd /c`** — never shell out to cmd.exe
- **No `&&` chaining** — use `cmd1; if ($?) { cmd2 }`
- **No Unix commands** (`grep`, `find`, `cat`) — use PowerShell equivalents or toolkit
- **No `npx`** — use `npm test` / `npm run build`
- **No batch syntax** (`for /r`, `dir /s`, `2>nul`) — use PowerShell equivalents

## Critical: No `$` Variables in Terminal Commands

`launch-process` wraps commands in `powershell -Command ...` — all `$` variables are interpolated by the outer shell and become empty strings.

**Every parameter value MUST be a literal string.** Never assign to `$var` then reference it.

```
WRONG: $name = "x"; .\script.ps1 -Param $name
RIGHT: .\script.ps1 -Param "x"
```

