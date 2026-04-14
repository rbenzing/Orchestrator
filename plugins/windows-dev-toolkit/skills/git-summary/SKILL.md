---
name: git-summary
description: Show branch, status, and recent commits
---

# git-summary.ps1

Display current branch, working tree status, and recent commit log.

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\git-summary\scripts\git-summary.ps1" -LogCount 20 -ShowStash
```

Params: -Path, -LogCount, -ShowStash

## Rules
- Always use named parameters
- Every value must be a literal string
- Never use git log/status directly
