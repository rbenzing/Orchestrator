# Windows Dev Toolkit Plugin

PowerShell dev tool wrappers for Windows — hardened for non-interactive AI agent execution with named parameters and stray-argument catching.

## What's Included

| Skill | Scripts | Purpose |
|-------|---------|---------|
| **dev-tools** | grep, find-files, tree, git-summary, git-diff, kill-port, remove-files | File search, git ops, process management |
| **utility-tools** | summarize-artifact, extract-symbols, truncate-error-log, get-compact-diff, format-and-lint, cleanup-workspace | Token-saving utilities |
| **windows-environment** | make-dir, copy-item, move-item, rename-item | Safe filesystem operations |
| **nodejs-windows** | run-tests, run-lint, run-build | Node.js / npm toolchain |
| **angular-windows** | run-tests, run-build, run-serve | Angular CLI with legacy OpenSSL support |
| **dotnet-windows** | dotnet-build, dotnet-test, dotnet-run, dotnet-restore, dotnet-format | .NET CLI |
| **polyglot-tools** | python-run, pip-install, poetry-run, cargo-run, go-run, ruby-run | Python, Rust, Go, Ruby |

## Installation (Internal)

```bash
# Load for a single session
claude --plugin-dir ./plugins/windows-dev-toolkit

# Install permanently
claude plugin install windows-dev-toolkit@local-marketplace

# Team scope
claude plugin install windows-dev-toolkit@local-marketplace --scope project
```

## Requirements

- Windows with `powershell.exe` in PATH
- Language runtimes installed separately (Node.js, .NET SDK, Python, etc.)

## Key Rules

- All scripts use **named parameters only** — no positional binding
- Every parameter value must be a **literal string** — never `$variables`
- **No `cmd /c`** — all commands are native PowerShell
- **No `&&` chaining** — use `; if ($?) { }` guards
- Scripts are invoked via `${CLAUDE_PLUGIN_ROOT}\skills\{name}\scripts\{script}.ps1`

## Why These Wrappers?

Raw PowerShell commands have sharp edges in AI agent contexts:
- `&&` chaining doesn't work in PowerShell 5.1
- `npx` resolves from the wrong directory in monorepos
- `cmd /c` shells out to cmd.exe breaking the PowerShell context
- `$variables` in `launch-process` commands get interpolated to empty strings
- `Remove-Item` has no safety guards; `kill-port.ps1` protects critical processes

These scripts fix all of the above.
