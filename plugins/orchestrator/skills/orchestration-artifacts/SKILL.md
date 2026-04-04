---
name: orchestration-artifacts
description: Artifact directory structure, project initialization, completion dashboard, and quality gate validation for the Contract-Router orchestration pipeline.
---

> **TOOL**: Always call these scripts via `launch-process`. Never use `Bash`.
> **FORMAT**: All parameters on a single line — no backtick line continuation.
> **PATH**: Use `${CLAUDE_PLUGIN_ROOT}\skills\orchestration-artifacts\scripts\` prefix.

## Directory Structure

```
.claude/orchestrator/artifacts/
+-- {project-name}/
|   +-- researcher/
|   |   +-- proposal.md, requirements.md, technical-constraints.md
|   |   +-- specs/ (scenarios.md, spec-before.md for migrations)
|   +-- architect/
|   |   +-- architecture.md, decisions/, diagrams/
|   +-- ui-designer/
|   |   +-- ui-spec.md, design-system.md, accessibility.md, flows/
|   +-- planner/
|   |   +-- design.md, implementation-spec.md, story-breakdown.md
|   +-- developer/
|   |   +-- implementation-notes.md, build-logs.txt
|   +-- code-reviewer/
|   |   +-- code-review-report.md
|   +-- tester/
|       +-- test-results.md, test-coverage.md
```

## Rules

1. Source code goes OUTSIDE `.claude/` — only planning artifacts live here
2. Each agent owns its subdirectory — agents must not write into another agent's directory
3. `{project-name}` must be consistent across all agent directories

## Scripts

### `init-project.ps1`
Creates the full artifact directory tree for a project.

```
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-artifacts\scripts\init-project.ps1 -ProjectName "user-auth"
```

Required: `-ProjectName`
Optional: `-BasePath`

### `artifact-status.ps1`
Artifact completion dashboard — shows which files exist per agent.

```
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-artifacts\scripts\artifact-status.ps1 -ProjectName "user-auth"
```

Required: `-ProjectName`
Optional: `-Root`

### `check-gate.ps1`
Quality gate validation — verifies required artifacts and section headers exist.

```
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-artifacts\scripts\check-gate.ps1 -ProjectName "user-auth" -Phase "research"
```

```
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-artifacts\scripts\check-gate.ps1 -ProjectName "user-auth" -Phase "all" -IsMigration
```

```
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-artifacts\scripts\check-gate.ps1 -ProjectName "user-auth" -ContractID "TSK-003"
```

Required: `-ProjectName` + one of `-Phase` or `-ContractID`
Optional: `-Phase` (research|architecture|ui-design|planning|development|reviews|testing|all) `-ContractID` `-IsMigration` `-Root`
