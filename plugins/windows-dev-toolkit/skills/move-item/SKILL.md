---
name: move-item
description: Move files or directories safely on Windows
---

# move-item.ps1

Move files or directories with safety guards. Blocks writes to protected directories.

```
${CLAUDE_PLUGIN_ROOT}\skills\move-item\scripts\move-item.ps1 -Source "old-name.ts" -Destination "new-name.ts"
```

Params: -Source required, -Destination required, -Force

## Rules
- Always use named parameters
- Never use Move-Item directly
