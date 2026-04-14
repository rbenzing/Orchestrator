---
name: dotnet-run
description: Run .NET project with launch profile
---

# dotnet-run.ps1

Run a .NET project with optional configuration and launch profile.

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\dotnet-run\scripts\dotnet-run.ps1" -ProjectPath "src\MyApi" -Configuration "Release"
```

Params: -ProjectPath required, -Configuration, -LaunchProfile, -NoBuild, -PassThruArgs

## Rules
- Always use named parameters
- Never use dotnet run directly -- use this script
