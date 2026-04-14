---
name: cleanup-workspace
description: Delete temp/cache dirs after task close
---

# cleanup-workspace.ps1

Delete cache and temp directories. Called by orchestrator as post-task hook. Cleans: .pytest_cache, node_modules/.cache, coverage/, dist/, build/, large logs >1MB.

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\cleanup-workspace\scripts\cleanup-workspace.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\cleanup-workspace\scripts\cleanup-workspace.ps1" -Root "C:\Src\my-project" -DryRun
```

Params: -Root, -DryRun

## When to Use
- After every contract close (orchestrator calls this automatically)
