---
name: ng-test
description: Run Angular Karma tests headless on Windows
---

# run-tests.ps1

Run Angular Karma tests. Handles NODE_OPTIONS, legacy OpenSSL, ChromeHeadless.

```
${CLAUDE_PLUGIN_ROOT}\skills\ng-test\scripts\run-tests.ps1 -ProjectPath "ClientApp" -LegacyOpenSSL -Headless -NoWatch
```

Params: -ProjectPath required, -LegacyOpenSSL, -Headless, -NoWatch, -Include, -CodeCoverage, -PassThruArgs

## Rules
- Use -LegacyOpenSSL for older Angular on Node 17+
- Use -Headless for CI/agent testing
- Never use ng test directly -- use this script
- Never use cmd /c -- .cmd files run natively in PowerShell
