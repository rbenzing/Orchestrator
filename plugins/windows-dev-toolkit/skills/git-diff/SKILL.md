---
name: git-diff
description: Show staged, unstaged, or ref-based diffs
---

# git-diff.ps1

Display git diffs: staged, unstaged, or between refs. Supports stat and name-only modes.

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\git-diff\scripts\git-diff.ps1" -Ref1 "main" -Stat
```

Params: -Staged, -Ref1, -Ref2, -Path, -FilePath, -Stat, -NameOnly

## Rules
- Always use named parameters
- Every value must be a literal string
- Never use git diff directly
