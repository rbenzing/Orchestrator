# Multi-Agent Orchestration System

> Coordinate 8 specialized AI agents to deliver high-quality, tested code through structured development phases.

## Overview

A multi-agent orchestration system that coordinates 8 specialized AI agents (Orchestrator, Researcher, Architect, UI Designer, Planner, Developer, Code Reviewer, Tester) to complete full-stack development projects. Each agent has a specific role, working together through a structured workflow with quality gates to ensure production-ready code.

**Key Features:**
- 🎯 Auto-triggered by typing "orchestrator"
- 🔄 TDD workflow: Research → Architecture → UI Design → Plan → **Test (author)** → Develop → Review → **Test (validate)** → Complete
- ⚡ Autonomous parallel execution: every agent follows **Decompose → Parallel → Verify → Iterate**
- ✅ Quality gates between each phase
- 📝 Complete documentation in `/.claude/artifacts/`
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

Copy the `.claude/` and `orchestration/` directories to your project root.

### After Installing

1. **Open the target project** in VS Code with Claude Extension (or use `auggie chat`)

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

For detailed documentation, see [`/orchestration/README.md`](./orchestration/README.md)

**Topics covered:**
- Dual-mode architecture (VS Code Extension vs Auggie CLI)
- The 8 agents and their roles
- Autonomous execution protocol (Decompose → Parallel → Verify → Iterate)
- State persistence and context recovery
- Orchestrator-first escalation protocol
- Hardened toolkit and security model
- Complete workflow details
- Project structure
- Examples and best practices

---

**Version**: 1.4
