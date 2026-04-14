---
name: dotnet-test
description: Run .NET tests with optional filter
---

# dotnet-test.ps1

Run .NET tests with optional name filtering, no-build, and verbosity.

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\dotnet-test\scripts\dotnet-test.ps1" -ProjectPath "tests\MyApi.Tests" -Filter "FullyQualifiedName~Integration"
```

Params: -ProjectPath required, -Filter, -NoBuild, -NoRestore, -Verbosity, -PassThruArgs

## Rules
- Always use named parameters
- Never use dotnet test directly -- use this script
