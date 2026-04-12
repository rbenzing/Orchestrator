---
name: find-files
description: Find files by name or regex pattern
---

# find-files.ps1

Find files by name pattern or regex. Git-aware, excludes .git/node_modules/bin/obj.

```
${CLAUDE_PLUGIN_ROOT}\skills\find-files\scripts\find-files.ps1 -Name "*.test.ts"
${CLAUDE_PLUGIN_ROOT}\skills\find-files\scripts\find-files.ps1 -Name "Controller" -Regex
```

Params: -Name required, -Path, -Regex, -DirectoriesOnly, -MaxResults

## Rules
- Always use named parameters
- Every value must be a literal string
- Never use Get-ChildItem -Recurse -Filter directly
