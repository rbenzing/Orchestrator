---
name: get-compact-diff
description: Summarized unified diff for code review
---

# get-compact-diff.ps1

Generate summarized unified diff. Used by code-reviewer to review only what changed.

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\get-compact-diff\scripts\get-compact-diff.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\get-compact-diff\scripts\get-compact-diff.ps1" -BaseBranch "main" -MaxLines 300 -OutputFile ".claude\artifacts\{project}\code-reviewer\diff.md"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\get-compact-diff\scripts\get-compact-diff.ps1" -Staged
```

Params: -BaseBranch default HEAD~1, -Files (array), -MaxLines default 200, -OutputFile, -Staged

## When to Use
- Code reviewer needs to see changes without loading full files
