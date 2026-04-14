---
name: ng-serve
description: Start Angular dev server on Windows
---

# run-serve.ps1

Start Angular dev server. Handles NODE_OPTIONS and legacy OpenSSL.

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\ng-serve\scripts\run-serve.ps1" -ProjectPath "ClientApp" -LegacyOpenSSL -Port 4200
```

Params: -ProjectPath required, -LegacyOpenSSL, -Port, -Open, -Configuration, -PassThruArgs

## Rules
- Never use ng serve directly -- use this script
- Never use cmd /c
