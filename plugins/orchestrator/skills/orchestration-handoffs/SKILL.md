---
name: orchestration-handoffs
description: Standardized handoff protocol and message generator
---

# Orchestration Handoffs

Handoff protocol for agent transitions. Every handoff includes artifact paths, key findings, next-phase readiness

## Agent Transition Map

- Orchestrator -> Researcher: project brief approved
- Researcher -> Architect: research complete
- Architect -> UI Designer: architecture complete if UI
- Architect -> Planner: architecture complete no UI
- UI Designer -> Planner: UI specs complete
- Planner -> Developer: stories ready
- Developer -> Code Reviewer: build passing
- Code Reviewer -> Tester: code approved
- Code Reviewer -> Developer: issues found feedback
- Tester -> Orchestrator: all tests passed
- Tester -> Developer: bugs found feedback

## Script

### handoff.ps1 -- Generate handoff or feedback messages
```
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-handoffs\scripts\handoff.ps1 -From "Researcher" -To "Architect" -ProjectName "user-auth" -Findings "OAuth 2.0 recommended"
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-handoffs\scripts\handoff.ps1 -From "Tester" -To "Developer" -ProjectName "user-auth" -IsFeedback -Issues "Login fails - Critical"
```
Params: -From required, -To required, -ProjectName required, -Findings, -IsFeedback, -Issues

Valid agents: Orchestrator, Researcher, Architect, UI Designer, Planner, Developer, Code Reviewer, Tester

