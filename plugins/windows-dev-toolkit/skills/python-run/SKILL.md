---
name: python-run
description: Run Python scripts or modules on Windows
---

# python-run.ps1

Run Python scripts or modules. Uses python not python3 on Windows.

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\python-run\scripts\python-run.ps1" -ScriptPath "main.py"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\python-run\scripts\python-run.ps1" -Module "pytest" -ProjectPath "tests" -PassThruArgs "-v","--tb=short"
```

Params: -ScriptPath OR -Module one required, -ProjectPath, -PassThruArgs

## Rules
- Always use named parameters
- Use python not python3 on Windows
