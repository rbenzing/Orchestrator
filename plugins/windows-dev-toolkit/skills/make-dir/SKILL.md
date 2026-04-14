---
name: make-dir
description: Create directories safely on Windows
---

# make-dir.ps1

Create directories with safety guards. Blocks writes to protected directories.

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\make-dir\scripts\make-dir.ps1" -Path "src\components"
```

Params: -Path required (accepts array)

## Rules
- Always use named parameters
- Never use mkdir or New-Item directly
