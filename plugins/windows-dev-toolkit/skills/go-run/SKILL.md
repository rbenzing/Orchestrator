---
name: go-run
description: Run Go build/test/vet/fmt commands
---

# go-run.ps1

Run Go commands: build, test, run, mod, fmt, vet, get.

```
${CLAUDE_PLUGIN_ROOT}\skills\go-run\scripts\go-run.ps1 -Command "test" -PassThruArgs "./..."
```

Params: -Command required (build|test|run|mod|fmt|vet|get), -ProjectPath, -PassThruArgs

## Rules
- Always use named parameters
- Never use go directly -- use this script
