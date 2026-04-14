---
name: grep
description: Search file contents by regex pattern
---

# grep.ps1

Search file contents by regex. Git-aware, excludes .git/node_modules/bin/obj.

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\grep\scripts\grep.ps1" -Pattern "TODO|FIXME"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\grep\scripts\grep.ps1" -Pattern "class\s+\w+" -Include "*.cs" -Context 2
```

Params: -Pattern required, -Path, -Include, -Context, -CaseSensitive, -MaxResults

## Rules
- Always use named parameters
- Every value must be a literal string
- Never use Select-String -Recurse directly
