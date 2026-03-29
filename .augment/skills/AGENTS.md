# Skills Module Rules

## Scope
These rules apply to all files within the `.augment/skills/` directory tree.

## Agent Permissions

### All Agents
- **Read access** to SKILL.md files for understanding available capabilities
- **Execute access** to scripts relevant to their role
- Must not modify skill definitions or scripts during project execution

### Orchestrator Agent
- **Execute access** to all orchestration skill scripts:
  - `orchestration-artifacts/scripts/` — artifact management and gate checks
  - `orchestration-handoffs/scripts/` — agent handoff management
  - `orchestration-state/scripts/` — state persistence and recovery

### Developer Agent
- **Execute access** to development skill scripts:
  - `angular-windows/scripts/` — Angular project scaffolding and builds
  - `nodejs-windows/scripts/` — Node.js environment management
  - `dotnet-windows/scripts/` — .NET CLI operations (build, test, run, restore, format)
  - `polyglot-tools/scripts/` — Multi-language toolchains (Python, Rust, Go, Ruby)
  - `dev-tools/scripts/` — Development tooling utilities
  - `windows-environment/` — Windows environment guide and filesystem operations (mkdir, copy, move, rename)

### Tester Agent
- **Execute access** to testing-related skill scripts:
  - `dev-tools/scripts/` — Test runner utilities
  - `angular-windows/scripts/` — Angular test execution
  - `nodejs-windows/scripts/` — Node.js test execution
  - `dotnet-windows/scripts/` — .NET test execution

## Conventions
- Skills are self-contained modules with a SKILL.md descriptor and a scripts/ directory
- Never modify skill scripts during project execution — they are infrastructure
- Report skill script failures to the Orchestrator for resolution

