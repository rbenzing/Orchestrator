---
name: node-lint
description: Run ESLint via npm run lint wrapper
---

# run-lint.ps1

Run ESLint via npm run lint. Verifies lint script exists in package.json before running.

```
${CLAUDE_PLUGIN_ROOT}\skills\node-lint\scripts\run-lint.ps1 -ProjectPath "ClientApp" -Fix
```

Params: -ProjectPath required, -Fix, -Quiet, -MaxWarnings, -Files, -Format, -PassThruArgs

## Rules
- Always use named parameters
- Never use npx eslint directly
- Never use && to chain commands
