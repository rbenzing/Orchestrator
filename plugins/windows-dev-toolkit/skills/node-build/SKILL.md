---
name: node-build
description: Run npm build with config options
---

# run-build.ps1

Run npm run build with optional script name, profiling, and source maps.

```
${CLAUDE_PLUGIN_ROOT}\skills\node-build\scripts\run-build.ps1 -ProjectPath "ClientApp" -ScriptName "build:prod"
```

Params: -ProjectPath required, -ScriptName default build, -Profile, -SourceMap, -NoBrowserslistUpdate, -PassThruArgs

## Rules
- Always use named parameters
- Never use && to chain commands
