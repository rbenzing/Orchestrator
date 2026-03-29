---
name: polyglot-tools
description: PowerShell wrappers for multi-language toolchains (Python/pip/poetry, Rust/cargo, Go, Ruby/bundle) on Windows. Hardened for non-interactive AI agent execution with named parameters and stray-argument catching.
---

# Polyglot Tools

PowerShell scripts for multi-language development toolchains. All scripts use mandatory named parameters, catch stray arguments, and output structured text.

## Scripts

### `python-run.ps1` — Run Python scripts or modules
```
.augment\skills\polyglot-tools\scripts\python-run.ps1 -ScriptPath "main.py"
.augment\skills\polyglot-tools\scripts\python-run.ps1 -Module "pytest" -ProjectPath "tests" -PassThruArgs "-v","--tb=short"
```
Params: `-ScriptPath` OR `-Module` (one required), `-ProjectPath`, `-PassThruArgs`

### `pip-install.ps1` — Install Python packages
```
.augment\skills\polyglot-tools\scripts\pip-install.ps1 -Packages "flask","requests"
.augment\skills\polyglot-tools\scripts\pip-install.ps1 -RequirementsFile "requirements.txt" -ProjectPath "backend"
```
Params: `-Packages` OR `-RequirementsFile` (one required), `-ProjectPath`, `-Upgrade`, `-PassThruArgs`

### `poetry-run.ps1` — Run Poetry commands
```
.augment\skills\polyglot-tools\scripts\poetry-run.ps1 -Command "install" -ProjectPath "backend"
.augment\skills\polyglot-tools\scripts\poetry-run.ps1 -Command "run" -PassThruArgs "pytest","-v"
```
Params: `-Command` (required: install, update, add, remove, run, build, lock, show), `-ProjectPath`, `-PassThruArgs`

### `cargo-run.ps1` — Run Cargo (Rust) commands
```
.augment\skills\polyglot-tools\scripts\cargo-run.ps1 -Command "build" -ProjectPath "rust-lib"
.augment\skills\polyglot-tools\scripts\cargo-run.ps1 -Command "test" -PassThruArgs "--release"
```
Params: `-Command` (required: build, test, run, check, clippy, fmt, doc), `-ProjectPath`, `-PassThruArgs`

### `go-run.ps1` — Run Go commands
```
.augment\skills\polyglot-tools\scripts\go-run.ps1 -Command "build" -ProjectPath "api"
.augment\skills\polyglot-tools\scripts\go-run.ps1 -Command "test" -PassThruArgs "./..."
```
Params: `-Command` (required: build, test, run, mod, fmt, vet, get), `-ProjectPath`, `-PassThruArgs`

### `ruby-run.ps1` — Run Ruby or Bundler commands
```
.augment\skills\polyglot-tools\scripts\ruby-run.ps1 -ScriptPath "app.rb"
.augment\skills\polyglot-tools\scripts\ruby-run.ps1 -BundleCommand "install" -ProjectPath "rails-app"
.augment\skills\polyglot-tools\scripts\ruby-run.ps1 -BundleCommand "exec" -PassThruArgs "rails","server"
```
Params: `-ScriptPath` OR `-BundleCommand` (one required), `-ProjectPath`, `-PassThruArgs`

## Rules
- Always use **named parameters** — no positional binding
- Every value must be a **literal string** — never use `$` variables
- **Never use python/pip/poetry/cargo/go/ruby/bundle directly** — use these scripts instead

