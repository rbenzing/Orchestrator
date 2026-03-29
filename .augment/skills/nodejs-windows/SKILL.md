---
name: nodejs-windows
description: Guides AI agents on correctly running Node.js, npm, and npx commands on Windows PowerShell — avoiding command chaining errors, npx cache mismatches, and package.json resolution failures common in monorepos and subdirectory projects.
---

# Node.js on Windows PowerShell

Common pitfalls when AI agents run Node.js tooling on Windows. **Read this before running any npm/npx commands.**

## Rule 1: Never Use `&&` to Chain Commands

PowerShell 5.1 (the default Windows shell) does NOT support `&&`.

| ❌ Wrong | ✅ Correct |
|----------|-----------|
| `cd src/app && npm test` | `Set-Location src\app; npm test` |
| `cd ClientApp && npx react-scripts test` | `Set-Location ClientApp; npm test` |
| `npm install && npm run build` | `npm install; if ($LASTEXITCODE -eq 0) { npm run build }` |

**Best practice:** Use `Set-Location` (or `Push-Location`/`Pop-Location`) on a separate line, then run the command:

```powershell
Push-Location "CallMiner.UI.Notifications\ClientApp"
npm test
Pop-Location
```

## Rule 2: Prefer `npm run` / `npm test` Over `npx`

**`npx` is dangerous in subdirectories.** When you run `npx react-scripts test`, npx may:
1. Download a fresh copy of `react-scripts` to a global cache (`npm-cache\_npx\...`)
2. Run it from the cache — which does NOT see your project's `package.json`
3. Fail with: `Cannot find module '...\package.json'`

**Fix:** Use the npm script aliases defined in the project's `package.json` instead:

| ❌ Avoid | ✅ Prefer |
|----------|----------|
| `npx react-scripts test` | `npm test` |
| `npx react-scripts build` | `npm run build` |
| `npx react-scripts start` | `npm start` |
| `npx jest --coverage` | `npm test -- --coverage` |
| `npx eslint .` | `npm run lint` (if defined) or `npx --no-install eslint .` |

### Why `npm test` Works

`npm test` runs the `"test"` script from the **local** `package.json`, using the **locally installed** `react-scripts` from `node_modules/.bin/`. No cache mismatch.

### When You Must Use npx

If the tool isn't in `package.json` scripts, use `npx --no-install` to force using the local copy:

```powershell
# Force local — fails fast if not installed locally (which is what you want)
npx --no-install react-scripts test --watchAll=false --verbose
```

Or call the local binary directly:

```powershell
# Explicit local binary path
node_modules\.bin\react-scripts test --watchAll=false --verbose
```

## Rule 3: Always `cd` First, Then Run

Node.js tools resolve `package.json` relative to the **current working directory**. Always change directory BEFORE running commands.

```powershell
# ✅ Correct: cd first, then run
Set-Location "MyApp\ClientApp"
npm install
npm test

# ❌ Wrong: running from parent with a path argument
npm test --prefix MyApp\ClientApp   # Unreliable with some tools
```

### Monorepo / Subdirectory Pattern

For projects where the Node.js app lives in a subdirectory:

```powershell
# Save current location, go to app, run commands, come back
Push-Location "src\MyApp\ClientApp"
try {
    npm install
    npm test
    npm run build
} finally {
    Pop-Location
}
```

## Rule 4: Check for `package.json` Before Running

Before running any npm command, verify you're in the right directory:

```powershell
if (-not (Test-Path "package.json")) {
    Write-Error "No package.json found in $(Get-Location). Wrong directory?"
    return
}
npm test
```

## Rule 5: Pass Extra Args with `--`

To pass arguments through npm scripts, use `--` as a separator:

```powershell
# Pass --watchAll=false to the underlying test runner
npm test -- --watchAll=false --verbose

# Pass --coverage to jest via npm test
npm test -- --coverage

# Pass env to react-scripts build
npm run build -- --profile
```

## Quick Reference: Common Commands

| Task | PowerShell Command |
|------|-------------------|
| Install dependencies | `npm install` or `npm ci` (CI/clean) |
| Run tests | `npm test` |
| Run tests (no watch) | `npm test -- --watchAll=false` |
| Run tests (verbose) | `npm test -- --verbose` |
| Build project | `npm run build` |
| Start dev server | `npm start` |
| Lint code | `npm run lint` |
| Run arbitrary script | `npm run <script-name>` |
| Check what scripts exist | `npm run` (lists all scripts) |
| Check installed packages | `npm ls --depth=0` |
| Clear npm cache | `npm cache clean --force` |
| Clear npx cache | `Remove-Item -Recurse -Force "$env:LOCALAPPDATA\npm-cache\_npx"` |

## Debugging: `Cannot find module 'package.json'`

This error almost always means one of:

1. **Wrong working directory** — `cd` to the directory containing `package.json` first
2. **npx cache mismatch** — use `npm test` instead of `npx react-scripts test`
3. **Missing `npm install`** — run `npm install` before running scripts
4. **npx cached a stale copy** — clear with: `Remove-Item -Recurse "$env:LOCALAPPDATA\npm-cache\_npx" -Force`

## Scripts

### `run-tests.ps1` -- Node.js test runner
```
.augment\skills\nodejs-windows\scripts\run-tests.ps1 -ProjectPath "ClientApp"
.augment\skills\nodejs-windows\scripts\run-tests.ps1 -ProjectPath "src\app" -TestPathPattern "components/charts" -Coverage
```
Params: `-ProjectPath` (required), `-TestPathPattern`, `-TestNamePattern`, `-NoWatch`, `-ForceExit`, `-Coverage`, `-PassThruArgs`

### `run-lint.ps1` -- ESLint / npm run lint
```
.augment\skills\nodejs-windows\scripts\run-lint.ps1 -ProjectPath "ClientApp"
.augment\skills\nodejs-windows\scripts\run-lint.ps1 -ProjectPath "src\app" -Fix
.augment\skills\nodejs-windows\scripts\run-lint.ps1 -ProjectPath "." -Quiet -MaxWarnings 0
.augment\skills\nodejs-windows\scripts\run-lint.ps1 -ProjectPath "ClientApp" -Files "src/**/*.ts" -Fix
```
Params: `-ProjectPath` (required), `-Fix`, `-Quiet`, `-MaxWarnings`, `-Files`, `-Format`, `-PassThruArgs`

> Verifies a `lint` script exists in package.json before running.

### `run-build.ps1` -- npm run build
```
.augment\skills\nodejs-windows\scripts\run-build.ps1 -ProjectPath "ClientApp"
.augment\skills\nodejs-windows\scripts\run-build.ps1 -ProjectPath "src\app" -SourceMap
.augment\skills\nodejs-windows\scripts\run-build.ps1 -ProjectPath "." -ScriptName "build:prod"
```
Params: `-ProjectPath` (required), `-ScriptName` (default "build"), `-Profile`, `-SourceMap`, `-NoBrowserslistUpdate`, `-PassThruArgs`

> Supports build script variants via `-ScriptName`. Shows elapsed time on completion.

