---
name: copy-item
description: Copy files or directories safely on Windows
---

# copy-item.ps1

Copy files or directories with safety guards. Blocks writes to protected directories.

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\copy-item\scripts\copy-item.ps1" -Source "template.json" -Destination "config.json" -Recurse
```

Params: -Source required, -Destination required, -Recurse, -Force

## Rules
- Always use named parameters
- Never use Copy-Item directly
