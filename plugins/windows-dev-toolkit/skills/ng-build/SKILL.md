---
name: ng-build
description: Build Angular app with configuration options
---

# run-build.ps1

Build Angular application. Handles NODE_OPTIONS and legacy OpenSSL.

```
${CLAUDE_PLUGIN_ROOT}\skills\ng-build\scripts\run-build.ps1 -ProjectPath "ClientApp" -LegacyOpenSSL -Configuration "production"
```

Params: -ProjectPath required, -LegacyOpenSSL, -Configuration, -ScriptName, -SourceMap, -PassThruArgs

## Rules
- Never use ng build directly -- use this script
- Never use cmd /c
