---
name: orchestration-handoffs
description: Standardized handoff protocol and message generator for agent-to-agent transitions in the 8-phase orchestration pipeline.
---

# Orchestration Handoffs

Handoff protocol for agent transitions. Every handoff includes artifact paths, key findings, and next-phase readiness.

## Agent Transition Map

| From | To | Trigger |
|---|---|---|
| Orchestrator | Researcher | Project brief approved |
| Researcher | Architect | Research complete |
| Architect | UI Designer | Architecture complete (if UI) |
| Architect | Planner | Architecture complete (no UI) |
| UI Designer | Planner | UI specs complete |
| Planner | Developer | Stories ready |
| Developer | Code Reviewer | Build passing |
| Code Reviewer | Tester | Code approved |
| Code Reviewer | Developer | Issues found (feedback) |
| Tester | Orchestrator | All tests passed |
| Tester | Developer | Bugs found (feedback) |

## Script

### `handoff.ps1` -- Generate handoff or feedback messages
```
.augment\skills\orchestration-handoffs\scripts\handoff.ps1 -From "Researcher" -To "Architect" -ProjectName "user-auth" -Findings "OAuth 2.0 recommended"
.augment\skills\orchestration-handoffs\scripts\handoff.ps1 -From "Tester" -To "Developer" -ProjectName "user-auth" -IsFeedback -Issues "Login fails - Critical"
```
Params: `-From` (required), `-To` (required), `-ProjectName` (required), `-Findings`, `-IsFeedback`, `-Issues`

Valid agents: Orchestrator, Researcher, Architect, UI Designer, Planner, Developer, Code Reviewer, Tester

