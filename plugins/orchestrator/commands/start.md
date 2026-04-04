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
   - Select profile using keyword match (see table below)
   - Create first-phase contracts: `${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\new-contract.ps1`
   - Run dispatch: `${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\run-orchestrator.ps1 -ProjectName "$ARGUMENTS"`

4. Save state at every workflow transition:
   `${CLAUDE_PLUGIN_ROOT}\skills\orchestration-state\scripts\save-state.ps1 -ProjectName "..." -Phase "..." -ActiveAgent "..." -NextAction "..."`

## Profile Selection (keyword match — pick first match)

| If request contains | Use profile |
|---|---|
| fix, bug, typo, config, rename, patch, hotfix | **Minimal Fix** |
| UI, component, page, screen, form, frontend, Angular, React, design | **Feature (UI)** |
| migrate, migration, refactor, upgrade, rewrite, reorganize | **Migration/Refactor** |
| anything else | **Feature (Backend)** — start with Researcher |

If ambiguous after keyword match: default to **Feature (Backend)**. After Researcher closes, read `proposal.md` → `## Route Recommendation` section and switch profile if needed.

## Routing Profiles (fixed dispatch order)

| Profile | Dispatch sequence |
|---|---|
| **Minimal Fix** | Developer → Code Reviewer → Tester |
| **Feature (Backend)** | Researcher → Architect → Planner → Tester (Red) → Developer (Green) → Code Reviewer → Tester (Validate) |
| **Feature (UI)** | Researcher → Architect → UI Designer → Planner → Tester (Red) → Developer (Green) → Code Reviewer → Tester (Validate) |
| **Migration/Refactor** | Researcher → Architect → Planner → Tester (Red) → Developer (Green) → Code Reviewer → Tester (Validate) |

## Dispatch Rules (if/then)

| Condition | Action |
|---|---|
| Gate passes | Dispatch next agent in profile sequence |
| Gate fails / agent blocked | Feedback contract → same agent (`attempt_count` +1) |
| `attempt_count >= 2` | Escalate `model_tier` to `opus` on new contract |
| `attempt_count >= max_attempts` | Stop — notify user with blocker summary |
| All contracts `Closed` | Archive contracts → announce completion |

## Communication Style

Announce actions declaratively — never ask permission:
- "Research complete. Assigning Architect..."
- Never: "Should I proceed?" / "What next?"
- Contact user only when `attempt_count >= max_attempts` or project is complete.

## Deactivation

Active until: project complete, user says "exit orchestrator", or unrelated conversation starts.
