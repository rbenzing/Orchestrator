---
name: orchestration-state
description: Persistent workflow state for the orchestration pipeline. Saves and loads orchestrator position so workflow survives context compaction.
---

# Orchestration State

File-based state persistence for the orchestrator. After Claude compacts context, the orchestrator reads the state file to recover its exact workflow position.

## State File Location

```
.claude/state/{project-name}/orchestrator-state.yml
```

## When to Save State

Save state at **every** workflow transition:
- Phase changes (research → architecture → planning → etc.)
- Story status changes (in-progress → review → testing → complete)
- Agent hand-offs (Developer → Code Reviewer → Tester)
- After any decision that changes the workflow direction

## When to Load State

Load state **immediately** when:
- The orchestrator starts a new response (always, as first action)
- Context feels unfamiliar or incomplete (compaction likely happened)
- The user says "continue", "resume", or "keep going"

## Scripts

### `save-state.ps1` — Persist orchestrator state to disk
```
.claude\skills\orchestration-state\scripts\save-state.ps1 -ProjectName "user-auth" -Phase "development" -ActiveAgent "Developer" -ActiveContractID "TSK-003" -RouterPhase "waiting" -NextAction "Waiting for Developer to close TSK-003"
```
Params: `-ProjectName` (required), `-Phase` (required), `-ActiveAgent` (required), `-NextAction` (required), `-ActiveContractID`, `-RouterPhase`, `-CurrentStory`, `-StoryStatus`, `-StoryQueue`, `-CompletedStories`, `-Notes`

### `load-state.ps1` — Load orchestrator state from disk
```
.claude\skills\orchestration-state\scripts\load-state.ps1 -ProjectName "user-auth"
```
Params: `-ProjectName` (required)

Outputs the full state file contents. If no state file exists, outputs a warning.

## Rules

- **Always save state before handing off to another agent**
- **Always load state as the FIRST action in any orchestrator response**
- State files are auto-generated — do not edit manually
- One state file per project
- State file uses compact YAML for easy parsing by the LLM

