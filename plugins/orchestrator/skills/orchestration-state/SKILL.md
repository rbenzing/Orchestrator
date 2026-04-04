---
name: orchestration-state
description: Persistent workflow state for the orchestration pipeline. Saves and loads orchestrator position so workflow survives context compaction.
---

> **TOOL**: Always call these scripts via `launch-process`. Never use `Bash`.
> **FORMAT**: All parameters on a single line — no backtick line continuation.
> **PATH**: Use `${CLAUDE_PLUGIN_ROOT}\skills\orchestration-state\scripts\` prefix.

## State File Location

```
.claude/orchestrator/state/{project-name}/orchestrator-state.yml
```

## When to Save State

Save at **every** workflow transition: phase changes, story status changes, agent hand-offs, any routing decision.

## When to Load State

Load **immediately** when starting a response, after compaction, or when the user says "continue" / "resume".

## Scripts

### `save-state.ps1`
Persists orchestrator state to disk.

```
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-state\scripts\save-state.ps1 -ProjectName "user-auth" -Phase "development" -ActiveAgent "Developer" -ActiveContractID "TSK-003" -RouterPhase "waiting" -NextAction "Waiting for Developer to close TSK-003"
```

Required: `-ProjectName` `-Phase` `-ActiveAgent` `-NextAction`
Optional: `-ActiveContractID` `-RouterPhase` `-CurrentStory` `-StoryStatus` `-StoryQueue` `-CompletedStories` `-Notes`

### `load-state.ps1`
Loads orchestrator state from disk. Outputs full state file contents.

```
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-state\scripts\load-state.ps1 -ProjectName "user-auth"
```

Required: `-ProjectName`

## Rules

- Always save state before handing off to another agent
- Always load state as the FIRST action in any orchestrator response
- State files are auto-generated — do not edit manually
- One state file per project
