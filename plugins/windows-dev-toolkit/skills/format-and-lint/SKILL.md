---
name: format-and-lint
description: Auto-detect and format/lint project code
---

# format-and-lint.ps1

Auto-detect project type and run formatter/linter. Supports: prettier, eslint, dotnet format, ruff, black.

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\format-and-lint\scripts\format-and-lint.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\format-and-lint\scripts\format-and-lint.ps1" -Fix:$false -Paths "src/auth"
```

Params: -Fix default true, -Paths, -Root

## When to Use
- Resolve style issues before code review
