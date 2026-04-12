---
name: dotnet-build
description: Build .NET project or solution
---

# dotnet-build.ps1

Build a .NET project or solution with configuration options.

```
${CLAUDE_PLUGIN_ROOT}\skills\dotnet-build\scripts\dotnet-build.ps1 -ProjectPath "src\MyApi" -Configuration "Release"
```

Params: -ProjectPath required, -Configuration, -Verbosity, -NoRestore, -PassThruArgs

## Rules
- Always use named parameters
- Never use dotnet build directly -- use this script
