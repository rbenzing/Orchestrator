---
name: summarize-artifact
description: Compact summary of large files for agents
---

# summarize-artifact.ps1

Extract headings, bullets, key:value pairs from large files. Skips prose and code. Use before loading full artifact.

```
${CLAUDE_PLUGIN_ROOT}\skills\summarize-artifact\scripts\summarize-artifact.ps1 -Path ".claude\artifacts\{project}\architect\architecture.yml"
```

Params: -Path required, -MaxLines default 60, -IncludeBody (include 3 body lines per heading)

## When to Use
- Before reading any file >300 lines
