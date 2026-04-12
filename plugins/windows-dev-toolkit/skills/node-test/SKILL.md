---
name: node-test
description: Run Node.js tests via npm test wrapper
---

# run-tests.ps1

Run Node.js tests (jest/vitest/mocha) via npm test. Handles cwd, watch mode, coverage.

```
${CLAUDE_PLUGIN_ROOT}\skills\node-test\scripts\run-tests.ps1 -ProjectPath "ClientApp"
${CLAUDE_PLUGIN_ROOT}\skills\node-test\scripts\run-tests.ps1 -ProjectPath "src\app" -TestPathPattern "components/charts" -Coverage
```

Params: -ProjectPath required, -TestPathPattern, -TestNamePattern, -NoWatch, -ForceExit, -Coverage, -PassThruArgs

## Rules
- Always cd to ProjectPath first (script handles this)
- Use npm test not npx -- npx causes cache mismatches on Windows
- Never use && to chain commands -- PowerShell 5.1 does not support &&
- Pass extra args with -- separator
