---
name: angular-windows
description: Guides AI agents on correctly running Angular CLI (ng) commands on Windows PowerShell — handling NODE_OPTIONS, ChromeHeadless testing, legacy OpenSSL, .cmd file execution, and command chaining errors.
---

## Rule 1: NEVER Use `cmd /c` — PowerShell Is the Shell

| ❌ Wrong | ✅ Correct |
|----------|-----------|
| `cmd /c "cd /d C:\app && ng test"` | `${CLAUDE_PLUGIN_ROOT}\skills\angular-windows\scripts\run-tests.ps1 -ProjectPath "C:\app"` |
| `cmd /c "set NODE_OPTIONS=--openssl-legacy-provider && ng build"` | `${CLAUDE_PLUGIN_ROOT}\skills\angular-windows\scripts\run-build.ps1 -ProjectPath "." -LegacyOpenSSL` |
| `cmd /c "run-tests.cmd"` | `.\run-tests.cmd` |
| `cmd /c "ng serve --port 4200"` | `${CLAUDE_PLUGIN_ROOT}\skills\angular-windows\scripts\run-serve.ps1 -ProjectPath "." -Port 4200` |

## Rule 2: Use `-LegacyOpenSSL` for Older Angular Projects

```powershell
${CLAUDE_PLUGIN_ROOT}\skills\angular-windows\scripts\run-tests.ps1 -ProjectPath "ClientApp" -LegacyOpenSSL
${CLAUDE_PLUGIN_ROOT}\skills\angular-windows\scripts\run-build.ps1 -ProjectPath "ClientApp" -LegacyOpenSSL
```

## Rule 3: Use `npm test` / `npm run build` — Not `ng` Directly

| ❌ Avoid | ✅ Prefer |
|----------|----------|
| `ng test` | `npm test` or `run-tests.ps1` |
| `ng build --configuration production` | `npm run build` or `run-build.ps1 -Configuration "production"` |
| `ng serve` | `npm start` or `run-serve.ps1` |

## Rule 4: Running `.cmd` / `.bat` Files

PowerShell runs `.cmd` and `.bat` files natively — no `cmd /c` needed:
```powershell
.\run-tests.cmd
.\build.bat
```

## Rule 5: ChromeHeadless for Headless Testing

```powershell
${CLAUDE_PLUGIN_ROOT}\skills\angular-windows\scripts\run-tests.ps1 -ProjectPath "ClientApp" -Headless -NoWatch
```

## Scripts

### `run-tests.ps1` — Angular test runner
```powershell
${CLAUDE_PLUGIN_ROOT}\skills\angular-windows\scripts\run-tests.ps1 -ProjectPath "ClientApp"
${CLAUDE_PLUGIN_ROOT}\skills\angular-windows\scripts\run-tests.ps1 -ProjectPath "ClientApp" -LegacyOpenSSL -Headless -NoWatch
${CLAUDE_PLUGIN_ROOT}\skills\angular-windows\scripts\run-tests.ps1 -ProjectPath "." -Include "src/app/components"
```
Params: `-ProjectPath` (required), `-LegacyOpenSSL`, `-Headless`, `-NoWatch`, `-Include`, `-CodeCoverage`, `-PassThruArgs`

### `run-build.ps1` — Angular build runner
```powershell
${CLAUDE_PLUGIN_ROOT}\skills\angular-windows\scripts\run-build.ps1 -ProjectPath "ClientApp"
${CLAUDE_PLUGIN_ROOT}\skills\angular-windows\scripts\run-build.ps1 -ProjectPath "." -LegacyOpenSSL -Configuration "production"
```
Params: `-ProjectPath` (required), `-LegacyOpenSSL`, `-Configuration`, `-ScriptName`, `-SourceMap`, `-PassThruArgs`

### `run-serve.ps1` — Angular dev server
```powershell
${CLAUDE_PLUGIN_ROOT}\skills\angular-windows\scripts\run-serve.ps1 -ProjectPath "ClientApp"
${CLAUDE_PLUGIN_ROOT}\skills\angular-windows\scripts\run-serve.ps1 -ProjectPath "." -LegacyOpenSSL -Port 4200 -Open
```
Params: `-ProjectPath` (required), `-LegacyOpenSSL`, `-Port`, `-Open`, `-Configuration`, `-PassThruArgs`
