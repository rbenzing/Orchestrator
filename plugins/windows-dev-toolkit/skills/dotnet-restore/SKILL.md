---
name: dotnet-restore
description: Restore NuGet packages for .NET project
---

# dotnet-restore.ps1

Restore NuGet packages for a .NET project or solution.

```
${CLAUDE_PLUGIN_ROOT}\skills\dotnet-restore\scripts\dotnet-restore.ps1 -ProjectPath "."
```

Params: -ProjectPath required, -Verbosity, -PassThruArgs

## Rules
- Always use named parameters
- Never use dotnet restore directly -- use this script
