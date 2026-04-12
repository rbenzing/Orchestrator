---
name: truncate-error-log
description: Truncate command output to first failure
---

# truncate-error-log.ps1

Run a command and slice output to first failure. Prevents long stack traces from flooding context.

```
${CLAUDE_PLUGIN_ROOT}\skills\truncate-error-log\scripts\truncate-error-log.ps1 -Command "npm test" -MaxLines 30
```

Params: -Command required, -MaxLines default 30

## When to Use
- Test run produced thousands of output lines
