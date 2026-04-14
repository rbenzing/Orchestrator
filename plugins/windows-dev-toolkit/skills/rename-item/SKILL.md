---
name: rename-item
description: Rename file or directory in place on Windows
---

# rename-item.ps1

Rename a file or directory in place with safety guards.

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\rename-item\scripts\rename-item.ps1" -Path "src\utils.js" -NewName "helpers.js"
```

Params: -Path required, -NewName required

## Rules
- Always use named parameters
- Never use Rename-Item directly
