# Orchestrator :: Multi-Agent Orchestration System

![Version](https://img.shields.io/badge/version-2.5-blue)
![License](https://img.shields.io/github/license/rbenzing/Orchestrator)
![Issues](https://img.shields.io/github/issues/rbenzing/Orchestrator)
![Last Commit](https://img.shields.io/github/last-commit/rbenzing/Orchestrator)

> Coordinate 8 specialized AI agents to deliver high-quality, tested code through structured development phases.

---

## Overview

A multi-agent orchestration system that coordinates 8 specialized AI agents (Orchestrator, Researcher, Architect, UI Designer, Planner, Developer, Code Reviewer, Tester) to complete full-stack development projects.

Each agent operates through a **Contract Router**, using structured YAML task contracts with strict quality gates to ensure production-ready output.

---

## Key Features

* 🎯 Triggered by natural language activation (e.g. "orchestrator")
* 📋 Contract-Router architecture (objective, inputs, acceptance criteria, routing)
* 🔄 TDD workflow:
  Research → Architecture → UI → Plan → Test (author) → Develop → Review → Test (validate)
* 🛤️ Smart routing (Minimal Fix, Feature Backend, Feature UI, Research-Heavy)
* ⚡ Parallel contract execution
* ✅ Quality gates between every phase
* 💾 Persistent state (`.claude/orchestrator/state/`)
* 📝 Artifacts stored per agent
* 🔒 Safe execution model (PowerShell hardened, dangerous commands blocked)
* 🤖 Orchestrator-first escalation (no user interruption)

---

## Plugin System

Orchestrator is implemented as a **local Claude plugin system**.

Plugins are located in this repo at:

```
plugins/
├── orchestrator/
└── windows-dev-toolkit/
```

### Included Plugins

* **orchestrator** — Multi-agent orchestration engine
* **windows-dev-toolkit** — Safe PowerShell tooling and automation

Claude loads plugins listed under `enabledPlugins` in your project's `.claude/settings.json`. The installer writes those entries for you.

---

## Installation

> ⚠️ Orchestrator is not an npm package. It installs by adding Claude plugin files to your project.

---

### PowerShell Installer (Windows)

```powershell
git clone https://github.com/rbenzing/Orchestrator.git
cd Orchestrator
.\install.ps1 -Target "C:\Path\To\YourProject"
```

This will:

* Register the `internal` marketplace (pointing to this repo's `marketplace.json`) in your project's `.claude/settings.json`
* Enable both plugins via `enabledPlugins` (`orchestrator@internal`, `windows-dev-toolkit@internal`)
* Copy `.claudeignore` into your project
* Write the `toolPermissions` security block to `settings.json`

When you next open your project in Claude Code, you will be prompted to trust the marketplace and install the plugins.

---

## Activation

After installation:

1. Open your project in Claude (VS Code or Claude Desktop)
2. Start a new chat session
3. Use one of the following prompts:

```
orchestrator
```

or

```
initialize orchestrator
```

or

```
start orchestration
```

If needed, force activation:

```
You are the Orchestrator agent. Initialize the system.
```

---

## Verification

Ensure the system is correctly installed:

### Expected settings.json entries

```json
{
  "extraKnownMarketplaces": {
    "internal": {
      "source": { "source": "file", "path": "C:\\GIT\\Orchestrator\\marketplace.json" }
    }
  },
  "enabledPlugins": {
    "orchestrator@internal": true,
    "windows-dev-toolkit@internal": true
  }
}
```

### Confirm plugin manifests exist

```
{orchestrator-repo}/plugins/orchestrator/plugin.json
{orchestrator-repo}/plugins/windows-dev-toolkit/plugin.json
```

### Reopen the project in Claude Code after install

---

## Quick Start

After activation, try:

* "Build a blog API with Node.js and PostgreSQL"
* "Create a JWT authentication system"
* "Develop a REST API with CRUD operations"

---

## Example Workflow

```
You: Build a REST API with Node.js and PostgreSQL

[Orchestrator] Creating project brief...
[Researcher] Analyzing requirements...
[Architect] Designing system architecture...
[UI Designer] Creating UI specifications...
[Planner] Creating technical plan...
[Tester] Writing tests (TDD)...
[Developer] Implementing features...
[Code Reviewer] Reviewing code...
[Tester] Validating implementation...
```

---

## How It Works

* Claude loads plugins listed in `enabledPlugins` in `.claude/settings.json`
* Each plugin defines agents, commands, skills, and hooks
* The Orchestrator routes work through structured contracts
* State is persisted to disk for reliability across sessions

---

## Troubleshooting

If Orchestrator does not activate:

1. Check that `enabledPlugins` in your project's `.claude/settings.json` contains `"orchestrator@internal": true` and that `extraKnownMarketplaces` points to the correct `marketplace.json` path

2. Restart Claude / VS Code

3. Confirm plugin manifest exists:

```
{orchestrator-repo}/plugins/orchestrator/plugin.json
```

4. Try manual activation:

```
You are the Orchestrator agent. Begin orchestration.
```

5. Ensure you opened the correct project root

---

## Documentation

For detailed documentation, see [`.claude/orchestrator/README.md`](./.claude/orchestrator/README.md)

Includes:

* Agent roles
* Contract lifecycle
* Routing strategies
* State persistence
* Security model

---

## Contributing

See `CONTRIBUTING.md` for guidelines.

---

## License

This project is licensed under the Apache License 2.0.
See the `LICENSE` file for details.
