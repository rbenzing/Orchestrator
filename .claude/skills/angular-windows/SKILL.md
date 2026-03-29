---
name: angular-windows
description: Guides AI agents on correctly running Angular CLI (ng) commands on Windows PowerShell — handling NODE_OPTIONS, ChromeHeadless testing, legacy OpenSSL, .cmd file execution, and command chaining errors.
---

# Angular on Windows PowerShell

Common pitfalls when AI agents run Angular CLI tooling on Windows. **Read this before running any ng/Angular commands.**

## Rule 1: NEVER Use `cmd /c` — PowerShell Is the Shell

The shell is PowerShell. **Never shell out to cmd.exe.** `.cmd` files run natively in PowerShell.

| ❌ Wrong | ✅ Correct |
|----------|-----------|
| `cmd /c "cd /d C:\app && ng test"` | `.claude\skills\angular-windows\scripts\run-tests.ps1 -ProjectPath "C:\app"` |
| `cmd /c "set NODE_OPTIONS=--openssl-legacy-provider && ng build"` | `.claude\skills\angular-windows\scripts\run-build.ps1 -ProjectPath "." -LegacyOpenSSL` |
| `cmd /c "run-tests.cmd"` | `.\run-tests.cmd` (runs directly in PowerShell) |
| `cmd /c "ng serve --port 4200"` | `.claude\skills\angular-windows\scripts\run-serve.ps1 -ProjectPath "." -Port 4200` |

## Rule 2: Use `-LegacyOpenSSL` for Older Angular Projects

Angular projects on Node.js 17+ often need `NODE_OPTIONS=--openssl-legacy-provider`. **Don't set this manually** — use the script flag:

```powershell
# ❌ WRONG — cmd.exe chaining, batch syntax
cmd /c "set NODE_OPTIONS=--openssl-legacy-provider && ng test"

# ❌ WRONG — && not valid in PowerShell 5.1
$env:NODE_OPTIONS = "--openssl-legacy-provider" && ng test

# ✅ RIGHT — script handles it
.claude\skills\angular-windows\scripts\run-tests.ps1 -ProjectPath "ClientApp" -LegacyOpenSSL
.claude\skills\angular-windows\scripts\run-build.ps1 -ProjectPath "ClientApp" -LegacyOpenSSL
```

## Rule 3: Use `npm test` / `npm run build` — Not `ng` Directly

Like React projects, prefer npm scripts over direct CLI invocation:

| ❌ Avoid | ✅ Prefer |
|----------|----------|
| `ng test` | `npm test` or `run-tests.ps1` |
| `ng build --configuration production` | `npm run build` or `run-build.ps1 -Configuration "production"` |
| `ng serve` | `npm start` or `run-serve.ps1` |
| `ng lint` | `npm run lint` or nodejs-windows `run-lint.ps1` |

## Rule 4: Running `.cmd` / `.bat` Files

PowerShell runs `.cmd` and `.bat` files natively. No `cmd /c` needed.

```powershell
# ❌ WRONG
cmd /c "run-tests.cmd"
cmd /c "build.bat"

# ✅ RIGHT — just call them directly
.\run-tests.cmd
.\build.bat

# ✅ RIGHT — with arguments
.\run-tests.cmd --no-watch --browsers=ChromeHeadless
```

## Rule 5: ChromeHeadless for CI/Headless Testing

Angular Karma tests default to launching Chrome with a GUI. For headless:

```powershell
# Use the script — handles ChromeHeadless automatically
.claude\skills\angular-windows\scripts\run-tests.ps1 -ProjectPath "ClientApp" -Headless

# Or with no-watch for CI
.claude\skills\angular-windows\scripts\run-tests.ps1 -ProjectPath "ClientApp" -Headless -NoWatch
```

## Scripts

### `run-tests.ps1` — Angular test runner
```
.claude\skills\angular-windows\scripts\run-tests.ps1 -ProjectPath "ClientApp"
.claude\skills\angular-windows\scripts\run-tests.ps1 -ProjectPath "ClientApp" -LegacyOpenSSL -Headless -NoWatch
.claude\skills\angular-windows\scripts\run-tests.ps1 -ProjectPath "." -Include "src/app/components"
```
Params: `-ProjectPath` (required), `-LegacyOpenSSL`, `-Headless`, `-NoWatch`, `-Include`, `-CodeCoverage`, `-PassThruArgs`

### `run-build.ps1` — Angular build runner
```
.claude\skills\angular-windows\scripts\run-build.ps1 -ProjectPath "ClientApp"
.claude\skills\angular-windows\scripts\run-build.ps1 -ProjectPath "." -LegacyOpenSSL -Configuration "production"
```
Params: `-ProjectPath` (required), `-LegacyOpenSSL`, `-Configuration`, `-ScriptName`, `-SourceMap`, `-PassThruArgs`

### `run-serve.ps1` — Angular dev server
```
.claude\skills\angular-windows\scripts\run-serve.ps1 -ProjectPath "ClientApp"
.claude\skills\angular-windows\scripts\run-serve.ps1 -ProjectPath "." -LegacyOpenSSL -Port 4200 -Open
```
Params: `-ProjectPath` (required), `-LegacyOpenSSL`, `-Port`, `-Open`, `-Configuration`, `-PassThruArgs`

## Quick Reference

| Task | Command |
|------|---------|
| Run tests (headless) | `.claude\skills\angular-windows\scripts\run-tests.ps1 -ProjectPath "ClientApp" -Headless -NoWatch` |
| Run tests (legacy SSL) | `.claude\skills\angular-windows\scripts\run-tests.ps1 -ProjectPath "ClientApp" -LegacyOpenSSL -Headless` |
| Build production | `.claude\skills\angular-windows\scripts\run-build.ps1 -ProjectPath "ClientApp" -Configuration "production"` |
| Build (legacy SSL) | `.claude\skills\angular-windows\scripts\run-build.ps1 -ProjectPath "ClientApp" -LegacyOpenSSL` |
| Dev server | `.claude\skills\angular-windows\scripts\run-serve.ps1 -ProjectPath "ClientApp" -Port 4200` |
| Lint | `.claude\skills\nodejs-windows\scripts\run-lint.ps1 -ProjectPath "ClientApp"` |
| Run .cmd file | `.\run-tests.cmd` (no cmd /c needed) |

