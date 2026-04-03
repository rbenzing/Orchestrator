# Orchestration System — Architecture & Reference

> CLI-only Contract-Router multi-agent orchestration harness.

## Architecture Overview

All work is dispatched through **compact YAML task contracts**. There is no role-play mode.

```
User request
    │
    ▼
Orchestrator Agent  (.claude/agents/orchestrator.md)
    │  creates YAML contracts
    ▼
.claude/orchestrator/contracts/{project}/TSK-NNN.yml
    │  polled by
    ▼
run-orchestrator.ps1  (dependency-aware dispatch loop)
    │  activates
    ▼
Specialist Agent  (.claude/agents/{agent}.md)
    │  reads contract + required_reads only
    │  writes artifacts to .claude/orchestrator/artifacts/{project}/{agent}/
    │  closes contract → stops
    ▼
cleanup-workspace.ps1  (post-task hook)
    │
    ▼
Next contract dispatched
```

---

## The 8 Agents

| Agent | File | Role |
|---|---|---|
| **Orchestrator** | `agents/orchestrator.md` | Project Manager / Contract Router |
| **Researcher** | `agents/researcher.md` | Requirements analysis & research |
| **Architect** | `agents/architect.md` | System & technical design |
| **UI Designer** | `agents/ui-designer.md` | UI/UX specification & accessibility |
| **Planner** | `agents/planner.md` | Story breakdown & implementation spec |
| **Developer** | `agents/developer.md` | TDD implementation |
| **Code Reviewer** | `agents/code-reviewer.md` | Quality gate & security review |
| **Tester** | `agents/tester.md` | Test authoring & validation |

---

## Contract Lifecycle

```
new-contract.ps1 → status: Open
                        │
              agent executes task
                        │
         update-contract.ps1 → status: Closed
                        │
          archive-contracts.ps1 → moved to archive/
```

**Status values**: `Open` → `Blocked` → `Review` → `Closed`

**Contract fields**: `id`, `project`, `type`, `assigned_agent`, `model_tier`, `status`, `objective`,
`required_reads`, `deliverables`, `acceptance_criteria`, `dependencies`, `attempt_count`,
`max_attempts`, `next_routing`, `execution_history`

**Contract location**: `.claude/orchestrator/contracts/{project}/TSK-NNN.yml`

---

## Route Selection Profiles

The Orchestrator selects the **smallest valid route** for each request:

| Profile | Agents Activated | When Used |
|---|---|---|
| **Minimal Fix** | Developer → Reviewer → Tester | Well-scoped bug fix with clear acceptance target |
| **Feature (Backend)** | Researcher → Architect → Planner → Tester → Developer → Reviewer → Tester | New backend feature |
| **Feature (UI)** | Researcher → Architect → UI Designer → Planner → Tester → Developer → Reviewer → Tester | New UI feature |
| **Migration/Refactor** | Researcher → Architect → Planner → Tester → Developer → Reviewer → Tester | Refactor or migration |
| **Research-Heavy** | Researcher → (re-evaluate) | Ambiguous or high-risk request |

---

## Model Tiering

Each contract specifies `model_tier` to control cost:

| Tier | When Used |
|---|---|
| `haiku` | Simple lookups, summaries, straightforward formatting |
| `sonnet` | Default for most agents (research, planning, development, review) |
| `opus` | Ambiguous routing decisions, repeated failures, major architecture conflicts |

---

## Artifact Locations

All documentation artifacts go under `.claude/orchestrator/artifacts/{project}/{agent}/`.
All actual project code goes **outside** of `.claude/`.

```
.claude/orchestrator/artifacts/{project}/
  researcher/    proposal.md, requirements.md, technical-constraints.md
  architect/     architecture.md, ADRs
  ui-designer/   ui-spec.md, design-system.md, accessibility.md
  planner/       story-breakdown.md, implementation-spec.md, design.md
  developer/     implementation-notes.md
  code-reviewer/ code-review-report.md
  tester/        test-results.md
```

---

## State Persistence & Recovery

State is saved at every phase transition so the Orchestrator can survive context compaction.

```powershell
# Save state
.claude\skills\orchestration-state\scripts\save-state.ps1 `
  -ProjectName "my-app" -Phase "development" -ActiveContractID "TSK-005" -RouterPhase "waiting" -NextAction "Dispatch @developer"

# Load state (always the first action on activation)
.claude\skills\orchestration-state\scripts\load-state.ps1
```

State files live at: `.claude/orchestrator/state/{project}/orchestrator-state.yml`

---

## Key Scripts

| Script | Purpose |
|---|---|
| `orchestration-contracts/scripts/new-contract.ps1` | Create a YAML task contract |
| `orchestration-contracts/scripts/update-contract.ps1` | Update status / append execution history |
| `orchestration-contracts/scripts/get-contract.ps1` | Query contracts by status / agent |
| `orchestration-contracts/scripts/run-orchestrator.ps1` | Dependency-aware dispatch loop |
| `orchestration-contracts/scripts/archive-contracts.ps1` | Archive closed contracts |
| `orchestration-artifacts/scripts/init-project.ps1` | Scaffold artifact directories |
| `orchestration-artifacts/scripts/check-gate.ps1` | Validate phase or contract gate |
| `orchestration-artifacts/scripts/artifact-status.ps1` | Dashboard of artifact coverage |
| `orchestration-handoffs/scripts/handoff.ps1` | Create forward / feedback contracts |
| `orchestration-state/scripts/save-state.ps1` | Persist workflow checkpoint |
| `orchestration-state/scripts/load-state.ps1` | Recover from compaction |
| `utility-tools/scripts/cleanup-workspace.ps1` | Post-task cache purge |
| `utility-tools/scripts/summarize-artifact.ps1` | Extract compact summary from large Markdown |
| `utility-tools/scripts/extract-symbols.ps1` | Pull targeted code symbols without full-file reads |
| `utility-tools/scripts/truncate-error-log.ps1` | Shrink stack traces to failure + context lines |

All scripts live under `.claude/skills/`.

---

## Security & Safety

- **Protected directory**: `.claude/agents/` — blocked from writes by `validate-orchestration-command.ps1` PreToolUse hook
- **Context blacklist**: `.claudeignore` blocks `node_modules`, `.cache`, `coverage`, `dist` from indexing
- **Dangerous commands**: the hook also blocks `rm -rf`, `format C:`, and similar destructive patterns
- **Agents cannot modify skill scripts** during project execution

---

## Further Reading

| Document | Location |
|---|---|
| Activation & workflow rules | `.claude/rules/orchestration-workflow.md` |
| PowerShell tool & environment rules | `.claude/rules/powershell-rules.md` |
| Agent prompt guidelines | `.claude/skills/AGENTS.md` |

