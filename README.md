# Orchestrator :: Multi-Agent Orchestration System

![Version](https://img.shields.io/badge/version-2.5-blue)
![License](https://img.shields.io/github/license/rbenzing/Orchestrator)
![Issues](https://img.shields.io/github/issues/rbenzing/Orchestrator)
![Last Commit](https://img.shields.io/github/last-commit/rbenzing/Orchestrator)

> Coordinate 8 specialized AI agents to deliver high-quality, tested code through structured development phases.

## Overview

A multi-agent orchestration system that coordinates 8 specialized AI agents (Orchestrator, Researcher, Architect, UI Designer, Planner, Developer, Code Reviewer, Tester) to complete full-stack development projects. Each agent has a specific role, dispatched by a **Contract Router** through structured YAML task contracts with quality gates to ensure production-ready code.

**Key Features:**
- 🎯 Auto-triggered by typing "orchestrator"
- 📋 **Contract-Router architecture** — every unit of work has a compact YAML contract (objective, required reads, acceptance criteria, next route)
- 🔄 TDD workflow: Research → Architecture → UI Design → Plan → **Test (author)** → Develop → Review → **Test (validate)** → Complete
- 🛤️ **Smart routing** — Orchestrator selects the smallest valid route (Minimal Fix, Feature Backend, Feature UI, Research-Heavy)
- 💰 **Model tiering** — haiku/sonnet/opus assigned per contract to minimize cost
- ⚡ Autonomous parallel execution: independent contracts dispatched concurrently
- ✅ Quality gates between each phase, validated against contract acceptance criteria
- 📝 Artifacts stored at `.claude/orchestrator/artifacts/{project}/{agent}/`
- 🛡️ Hardened PowerShell toolkit with safety checks (path validation, protected directories)
- 🔒 Dangerous commands denied — safe operations fully autonomous (no user prompts)
- 💾 State persistence — survives LLM context compaction with automatic recovery
- 🤖 Orchestrator-first escalation — agents never ask the user; they escalate to the Orchestrator
- 🅰️ Angular & Node.js Windows skills — safe PowerShell wrappers for builds, tests, and dev servers

## Installation

### Option A: Installer Script (Recommended)

1. **Double-click `install.bat`** (or run `.\install.ps1` from PowerShell)
2. **Enter the target project path** when prompted
3. **Confirm** the copy

```
> .\install.ps1 -Target "C:\Src\MyProject"
```

### Option B: Manual Copy

Copy the `.claude/` directory to your project root.

### After Installing

1. **Open the target project** in VS Code with Claude Extension (or use `claude cli`)

2. **Type "orchestrator"** to activate:
   ```
   You: "orchestrator"
   AI: 🎯 Orchestration System Activated
       I am now operating as the Orchestrator Agent...
   ```

3. **Start building:**
   ```
   You: "Build a REST API with Node.js and PostgreSQL"

   AI: [Orchestrator] Creating project brief...
       [Researcher] Analyzing requirements...
       [Architect] Designing system architecture...
       [UI Designer] Creating UI specifications...
       [Planner] Creating technical plan...
       [Tester] Writing test specs (TDD)...
       [Developer] Implementing features...
       [Code Reviewer] Reviewing code...
       [Tester] Validating tests...
   ```

## Quick Start

After typing "orchestrator" to activate the system, you can request:
- `"Build a blog API with Node.js and PostgreSQL"`
- `"Create a user authentication system with JWT"`
- `"Develop a REST API with CRUD operations"`

## Documentation

For detailed documentation, see [`.claude/orchestrator/README.md`](./.claude/orchestrator/README.md)

**Topics covered:**
- CLI-only Contract-Router architecture
- The 8 agents and their roles
- Contract lifecycle (new → open → review → closed → archived)
- Route selection profiles (Minimal Fix, Feature Backend, Feature UI, Research-Heavy)
- Model tiering and cost optimization
- State persistence and context recovery
- Orchestrator-first escalation protocol
- Hardened toolkit and security model
- Complete workflow details and examples

## Contributing

See `CONTRIBUTING.md` for guidelines.

## License

This project is licensed under the Apache License 2.0.  
See the `LICENSE` file for details.
