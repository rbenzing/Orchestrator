---
name: nodejs-windows
description: Guides AI agents on correctly running Node.js, npm, and npx commands on Windows PowerShell — avoiding command chaining errors, npx cache mismatches, and package.json resolution failures common in monorepos and subdirectory projects.
---

## Rule 1: Never Use `&&` to Chain Commands

PowerShell 5.1 does NOT support `&&`.

| ❌ Wrong | ✅ Correct |
|----------|-----------|
| `cd src/app && npm test` | `Set-Location src\app; npm test` |
| `cd ClientApp && npx react-scripts test` | `Set-Location ClientApp; npm test` |
| `npm install && npm run build` | `npm install; if ($LASTEXITCODE -eq 0) { npm run build }` |

## Rule 2: Prefer `npm run` / `npm test` Over `npx`

| ❌ Avoid | ✅ Prefer |
|----------|----------|
| `npx react-scripts test` | `npm test` |
| `npx react-scripts build` | `npm run build` |
| `npx react-scripts start` | `npm start` |
| `npx jest --coverage` | `npm test -- --coverage` |
| `npx eslint .` | `npm run lint` (if defined) |

## Rule 3: Pass Extra Args with `--`

```powershell
npm test -- --watchAll=false --verbose
npm test -- --coverage
```

## Scripts

### `run-tests.ps1` — Node.js test runner
```powershell
${CLAUDE_PLUGIN_ROOT}\skills\nodejs-windows\scripts\run-tests.ps1 -ProjectPath "ClientApp"
${CLAUDE_PLUGIN_ROOT}\skills\nodejs-windows\scripts\run-tests.ps1 -ProjectPath "src\app" -TestPathPattern "components/charts" -Coverage
```
Params: `-ProjectPath` (required), `-TestPathPattern`, `-TestNamePattern`, `-NoWatch`, `-ForceExit`, `-Coverage`, `-PassThruArgs`

### `run-lint.ps1` — ESLint / npm run lint
```powershell
${CLAUDE_PLUGIN_ROOT}\skills\nodejs-windows\scripts\run-lint.ps1 -ProjectPath "ClientApp"
${CLAUDE_PLUGIN_ROOT}\skills\nodejs-windows\scripts\run-lint.ps1 -ProjectPath "src\app" -Fix
${CLAUDE_PLUGIN_ROOT}\skills\nodejs-windows\scripts\run-lint.ps1 -ProjectPath "ClientApp" -Files "src/**/*.ts" -Fix
```
Params: `-ProjectPath` (required), `-Fix`, `-Quiet`, `-MaxWarnings`, `-Files`, `-Format`, `-PassThruArgs`

> Verifies a `lint` script exists in package.json before running.

### `run-build.ps1` — npm run build
```powershell
${CLAUDE_PLUGIN_ROOT}\skills\nodejs-windows\scripts\run-build.ps1 -ProjectPath "ClientApp"
${CLAUDE_PLUGIN_ROOT}\skills\nodejs-windows\scripts\run-build.ps1 -ProjectPath "src\app" -SourceMap
${CLAUDE_PLUGIN_ROOT}\skills\nodejs-windows\scripts\run-build.ps1 -ProjectPath "." -ScriptName "build:prod"
```
Params: `-ProjectPath` (required), `-ScriptName` (default "build"), `-Profile`, `-SourceMap`, `-NoBrowserslistUpdate`, `-PassThruArgs`
