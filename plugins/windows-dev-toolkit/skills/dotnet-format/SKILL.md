---
name: dotnet-format
description: Format .NET code and verify style rules
---

# dotnet-format.ps1

Format .NET code. Can verify without changes for CI gating.

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\dotnet-format\scripts\dotnet-format.ps1" -ProjectPath "." -VerifyNoChanges -Severity "warn"
```

Params: -ProjectPath required, -VerifyNoChanges, -Severity, -Diagnostics, -PassThruArgs

## Rules
- Always use named parameters
- Never use dotnet format directly -- use this script
