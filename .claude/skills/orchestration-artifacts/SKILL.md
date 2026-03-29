---
name: orchestration-artifacts
description: Artifact directory structure, project initialization, completion dashboard, and quality gate validation for the 8-phase orchestration pipeline.
---

# Orchestration Artifacts

Canonical directory layout for all orchestration artifacts. Every agent stores deliverables under `/.claude/artifacts/` using this structure.

## Directory Structure

```
.claude/artifacts/
+-- research/{project-name}/
|   +-- proposal.md, requirements.md, technical-constraints.md
|   +-- specs/ (scenarios.md, spec-before.md for migrations)
+-- architecture/{project-name}/
|   +-- architecture.md, decisions/, diagrams/
+-- ui-design/{project-name}/
|   +-- ui-spec.md, design-system.md, accessibility.md, flows/
+-- planning/{project-name}/
|   +-- design.md, implementation-spec.md, story-breakdown.md
+-- development/{project-name}/
|   +-- implementation-notes.md, build-logs.txt
+-- reviews/{project-name}/
|   +-- code-review-report.md
+-- testing/{project-name}/
    +-- test-results.md, test-coverage.md
```

## Rules

1. Source code goes OUTSIDE `/orchestration/` -- only planning artifacts live here
2. Each phase owns its subdirectory -- agents must not write into another phase's directory
3. `{project-name}` must be consistent across all phases

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

