---
name: kill-port
description: Kill process by TCP port number or PID
---

# kill-port.ps1

Kill process listening on a TCP port or by PID. Dry-run by default, protects critical processes.

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\kill-port\scripts\kill-port.ps1" -Port 3000 -Force
```

Params: -Port OR -ProcessId one required, -Force, -ProcessName

## Rules
- Always use named parameters
- Dry-run by default -- use -Force to actually kill
- Never use Get-NetTCPConnection + Stop-Process directly
- Never use the kill-process IDE tool
