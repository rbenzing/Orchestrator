---
name: orchestration-state
description: Saves, loads and clears orchestrator workflow state
---

# Orchestration State

File-based state persistence. After context compaction the orchestrator reads state to recover its exact workflow position

State file: ${CLAUDE_PLUGIN_ROOT}/state/state-{project-name}.yml

## When to Save

Save at every workflow transition:
- Phase changes research -> architecture -> planning etc
- Story status changes in-progress -> review -> testing -> complete
- Agent hand-offs Developer -> Code Reviewer -> Tester
- After any decision that changes workflow direction

## When to Load

Load immediately when:
- Orchestrator starts a new response always as first action
- Context feels unfamiliar or incomplete compaction likely happened
- User says continue, resume, or keep going

## Scripts

### save-state.ps1 -- Persist state to disk
```
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-state\scripts\save-state.ps1 -ProjectName "user-auth" -Phase "development" -ActiveAgent "Developer" -ActiveContractID "TSK-003" -RouterPhase "waiting" -NextAction "Waiting for Developer to close TSK-003"
```
Params: -ProjectName required, -Phase required, -ActiveAgent required, -NextAction required, -ActiveContractID, -RouterPhase, -CurrentStory, -StoryStatus, -StoryQueue, -CompletedStories, -Notes

### load-state.ps1 -- Load state from disk
```
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-state\scripts\load-state.ps1 -ProjectName "user-auth"
```
Params: -ProjectName required. Outputs full state file contents. Warning if no state file exists

### clear-state.ps1 -- Delete or reset state for a project
```
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-state\scripts\clear-state.ps1 -ProjectName "user-auth"
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-state\scripts\clear-state.ps1 -ProjectName "user-auth" -Reset
```
Params: -ProjectName required, -Reset (write blank defaults instead of deleting)
Use after project completion or to recover from a corrupted state file

## Rules

- Always save state before handing off to another agent
- Always load state as the FIRST action in any orchestrator response
- State files are auto-generated -- do not edit manually
- One state file per project, compact YAML