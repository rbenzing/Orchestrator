---
name: cargo-run
description: Run Cargo build/test/check/clippy commands
---

# cargo-run.ps1

Run Cargo Rust commands: build, test, run, check, clippy, fmt, doc.

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}\skills\cargo-run\scripts\cargo-run.ps1" -Command "test" -PassThruArgs "--release"
```

Params: -Command required (build|test|run|check|clippy|fmt|doc), -ProjectPath, -PassThruArgs

## Rules
- Always use named parameters
- Never use cargo directly -- use this script
