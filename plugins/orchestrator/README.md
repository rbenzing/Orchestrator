# Orchestrator Plugin

Contract-Router multi-agent orchestration pipeline for Claude Code. Coordinates 8 specialized agents across research, architecture, planning, development, review, and testing phases using YAML task contracts.

## What's Included

| Component | Contents |
|-----------|----------|
| **8 agents** | orchestrator, researcher, architect, ui-designer, planner, developer, code-reviewer, tester |
| **4 skills** | orchestration-contracts, orchestration-artifacts, orchestration-state, orchestration-handoffs |
| **7 hooks** | PreToolUse (validation), PreCompact, PostCompact, SessionStart, UserPromptSubmit, SubagentStart, SubagentStop |
| **2 commands** | `/orchestrator:start`, `/orchestrator:setup` |

## Installation

Run the installer from the Orchestrator repo root, targeting your project:

```powershell
.\install.ps1 -Target "C:\Path\To\YourProject"
```

This registers the `internal` marketplace and enables both plugins in your project's `.claude/settings.json`. When you open the project in Claude Code, you will be prompted to trust the marketplace and install the plugins.

## First-Time Setup

After the plugin activates, run the setup command to write recommended tool permissions to your project:

```
/orchestrator:setup
```

This writes the security deny-list to `.claude/settings.json` that prevents agents from running raw PowerShell, git destructive operations, and credential-leaking patterns.

## Usage

Activate the orchestration system:

```
/orchestrator:start my-project-name
```

Or just type `orchestrator` in any prompt to activate.

## State Files

The plugin creates project-local directories (in your project's `.claude/` folder):

```
.claude/
├── orchestrator/state/{project}/orchestrator-state.yml   ← workflow position
├── orchestrator/contracts/{project}/                     ← YAML task contracts
└── orchestrator/artifacts/{project}/                     ← agent deliverables
```

These are per-project and can be committed to git for team visibility.

## Requirements

- Windows with `powershell.exe` in PATH
- Claude Code latest version

## Workflow

```
Researcher → Architect → [UI Designer] → Planner
         → Tester (Red) → Developer (Green) → Code Reviewer → Tester (Validate)
```

See `commands/start.md` for the full dispatch rule table.
