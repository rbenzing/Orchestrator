---
description: Activate the Contract-Router orchestration system. Recovers state if a project is in progress, or starts a new project.
---

# Orchestration System Activated — Contract-Router Mode

## Startup Sequence

1. Run `${CLAUDE_PLUGIN_ROOT}\skills\orchestration-state\scripts\load-state.ps1` to recover state.
   - If state found: resume from `NextAction` in the state file.
   - If no state: new project — ask ONE clarifying question if goal is ambiguous, then proceed.

2. Respond: **"Orchestration System Activated — Contract-Router Mode"**

3. For new projects:
   - Init artifact dirs: `${CLAUDE_PLUGIN_ROOT}\skills\orchestration-artifacts\scripts\init-project.ps1 -ProjectName "$ARGUMENTS"`
   - Create first-phase contracts: `${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\new-contract.ps1`
   - Run dispatch: `${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\run-orchestrator.ps1 -ProjectName "$ARGUMENTS"`

4. Save state at every workflow transition:
   `${CLAUDE_PLUGIN_ROOT}\skills\orchestration-state\scripts\save-state.ps1 -ProjectName "..." -Phase "..." -ActiveAgent "..." -NextAction "..."`

## Autonomous Dispatch Rules

| Trigger | Action |
|---------|--------|
| Research `Closed` | Create @architect + @ui-designer contracts; dispatch |
| Architecture `Closed` | Create @planner contract; dispatch |
| Planning `Closed` | Create per-story @tester (test-authoring) contracts; dispatch |
| Tester-author `Closed` | Auto-dispatch @developer (deps resolved) |
| Developer `Closed` | Auto-dispatch @code-reviewer |
| Review `Closed` (Approved) | Auto-dispatch @tester validation |
| Review `Closed` (Rejected) | New @developer contract with feedback in required_reads |
| Validation Pass | Mark story complete; create next story contracts |
| Validation Fail | New @developer contract with bug report |
| Contract `Blocked` | Create resolver (@researcher/@architect); re-open after resolved; max 3 attempts |
| All `Closed` | Archive contracts; announce completion |

## Communication Style

**Autonomous. Declarative. Never interrogative.**
- Announce actions: "Research complete. Assigning Architect..."
- Never ask: "Should I proceed?" / "What next?" — just follow the workflow
- Only contact user for: fundamental requirement conflicts, project-level blockers after 3 failed attempts, or project completion

## Routing Profiles

| Profile | Route |
|---------|-------|
| **Minimal Fix** | Developer → Code Reviewer → Tester |
| **Feature (Backend)** | Researcher → Architect → Planner → Tester (Red) → Developer (Green) → Code Reviewer → Tester (Validate) |
| **Feature (UI)** | Researcher → Architect → UI Designer → Planner → Tester (Red) → Developer (Green) → Code Reviewer → Tester (Validate) |
| **Migration/Refactor** | Researcher → Architect → Planner → Tester (Red) → Developer (Green) → Code Reviewer → Tester (Validate) |

## Deactivation

Active until: project complete, user says "exit orchestrator", or unrelated conversation starts.
