---
name: pip-install
description: Install Python packages via pip wrapper
---

# pip-install.ps1

Install Python packages via pip. Supports requirements files and upgrade mode.

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\pip-install\scripts\pip-install.ps1" -Packages "flask","requests"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\pip-install\scripts\pip-install.ps1" -RequirementsFile "requirements.txt"
```

Params: -Packages OR -RequirementsFile one required, -ProjectPath, -Upgrade, -PassThruArgs

## Rules
- Always use named parameters
- Use pip not pip3 on Windows
