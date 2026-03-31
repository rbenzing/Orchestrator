---
name: orchestration-artifacts
description: Artifact directory structure, project initialization, completion dashboard, and quality gate validation for the Contract-Router orchestration pipeline.
---

# Orchestration Artifacts

Canonical directory layout for all orchestration artifacts. Every agent stores deliverables under `.claude/artifacts/{project}/{agent}/` using this structure.

## Directory Structure

```
.claude/artifacts/
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

### `init-project.ps1` -- Create artifact directory tree
```
.claude\skills\orchestration-artifacts\scripts\init-project.ps1 -ProjectName "user-auth"
.claude\skills\orchestration-artifacts\scripts\init-project.ps1 -ProjectName "dashboard.v2" -BasePath "artifacts"
```
Params: `-ProjectName` (required), `-BasePath`

### `artifact-status.ps1` -- Artifact completion dashboard
```
.claude\skills\orchestration-artifacts\scripts\artifact-status.ps1 -ProjectName "user-auth"
```
Params: `-ProjectName` (required), `-Root`

### `check-gate.ps1` -- Quality gate validation
```
.claude\skills\orchestration-artifacts\scripts\check-gate.ps1 -ProjectName "user-auth" -Phase "research"
.claude\skills\orchestration-artifacts\scripts\check-gate.ps1 -ProjectName "billing" -Phase "all" -IsMigration
```
Params: `-ProjectName` (required), `-Phase` (required: research|architecture|ui-design|planning|development|reviews|testing|all), `-IsMigration`, `-Root`

