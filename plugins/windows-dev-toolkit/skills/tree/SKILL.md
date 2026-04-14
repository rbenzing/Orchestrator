---
name: tree
description: Show directory tree with depth control
---

# tree.ps1

Display directory tree with configurable depth and file visibility.

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\tree\scripts\tree.ps1" -Path "src" -Depth 4 -ShowFiles
```

Params: -Path, -Depth, -ShowFiles

## Rules
- Always use named parameters
- Every value must be a literal string
- Never use ls -R or Get-ChildItem -Recurse directly
