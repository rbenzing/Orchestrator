---
name: dotnet-windows
description: PowerShell wrappers for .NET CLI commands (build, test, run, restore, format) on Windows. Hardened for non-interactive AI agent execution with named parameters and stray-argument catching.
---

## Scripts

### `dotnet-build.ps1` — Build a .NET project or solution
```powershell
${CLAUDE_PLUGIN_ROOT}\skills\dotnet-windows\scripts\dotnet-build.ps1 -ProjectPath "src\MyApi"
${CLAUDE_PLUGIN_ROOT}\skills\dotnet-windows\scripts\dotnet-build.ps1 -ProjectPath "." -Configuration "Release" -Verbosity "minimal"
```
Params: `-ProjectPath` (required), `-Configuration`, `-Verbosity`, `-NoRestore`, `-PassThruArgs`

### `dotnet-test.ps1` — Run .NET tests
```powershell
${CLAUDE_PLUGIN_ROOT}\skills\dotnet-windows\scripts\dotnet-test.ps1 -ProjectPath "tests\MyApi.Tests"
${CLAUDE_PLUGIN_ROOT}\skills\dotnet-windows\scripts\dotnet-test.ps1 -ProjectPath "." -Filter "FullyQualifiedName~Integration" -NoBuild
```
Params: `-ProjectPath` (required), `-Filter`, `-NoBuild`, `-NoRestore`, `-Verbosity`, `-PassThruArgs`

### `dotnet-run.ps1` — Run a .NET project
```powershell
${CLAUDE_PLUGIN_ROOT}\skills\dotnet-windows\scripts\dotnet-run.ps1 -ProjectPath "src\MyApi"
${CLAUDE_PLUGIN_ROOT}\skills\dotnet-windows\scripts\dotnet-run.ps1 -ProjectPath "src\MyApi" -Configuration "Release" -LaunchProfile "Development"
```
Params: `-ProjectPath` (required), `-Configuration`, `-LaunchProfile`, `-NoBuild`, `-PassThruArgs`

### `dotnet-restore.ps1` — Restore NuGet packages
```powershell
${CLAUDE_PLUGIN_ROOT}\skills\dotnet-windows\scripts\dotnet-restore.ps1 -ProjectPath "."
${CLAUDE_PLUGIN_ROOT}\skills\dotnet-windows\scripts\dotnet-restore.ps1 -ProjectPath "src\MyApi" -Verbosity "minimal"
```
Params: `-ProjectPath` (required), `-Verbosity`, `-PassThruArgs`

### `dotnet-format.ps1` — Format .NET code
```powershell
${CLAUDE_PLUGIN_ROOT}\skills\dotnet-windows\scripts\dotnet-format.ps1 -ProjectPath "src\MyApi"
${CLAUDE_PLUGIN_ROOT}\skills\dotnet-windows\scripts\dotnet-format.ps1 -ProjectPath "." -VerifyNoChanges -Severity "warn"
```
Params: `-ProjectPath` (required), `-VerifyNoChanges`, `-Severity`, `-Diagnostics`, `-PassThruArgs`

## Rules
- Always use **named parameters** — no positional binding
- Every value must be a **literal string** — never use `$` variables
- **Never use `dotnet` directly** — use these scripts instead
