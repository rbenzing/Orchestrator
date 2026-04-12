---
name: remove-files
description: Safely remove files with dry-run default
---

# remove-files.ps1

Safely remove files or directories. Dry-run by default. Blocks .git, .claude, node_modules, system dirs, parent traversal.

```
${CLAUDE_PLUGIN_ROOT}\skills\remove-files\scripts\remove-files.ps1 -Path "dist","coverage" -Recurse -Force
```

Params: -Path required (accepts array), -Recurse, -Force, -Quiet

## Rules
- Always use named parameters
- Dry-run by default -- use -Force to actually delete
- Never use Remove-Item directly
- Never use the remove-files IDE tool
