---
name: orchestration-artifacts
description: YAML artifact CRUD, templates, and quality gates
---

# Orchestration Artifacts

One YAML file per contract per agent. ContractId is the filename. Deterministic schema, token-efficient.

## Directory Structure

```
${CLAUDE_PLUGIN_ROOT}/artifacts/{project}/
  researcher/    {contract-id}.yml  (requirements template)
  architect/     {contract-id}.yml  (architecture template)
  ui-designer/   {contract-id}.yml  (ui-spec template)
  planner/       {contract-id}.yml  (stories template)
  developer/     {contract-id}.yml  (dev-log template)
  code-reviewer/ {contract-id}.yml  (review template)
  tester/        {contract-id}.yml  (test-results template)
```

Templates: `${CLAUDE_PLUGIN_ROOT}/skills/orchestration-artifacts/templates/`

## Rules

1. Source code goes OUTSIDE ${CLAUDE_PLUGIN_ROOT}/ -- only planning artifacts live here
2. Each agent owns its subdirectory -- agents must not write into another agent's directory
3. Use CRUD scripts below -- do not manually create artifact files
4. All artifacts are YAML -- no markdown prose, no unicode, no unnecessary formatting
5. Use get-artifact -Field to read single fields -- avoid loading full files
6. One artifact per contract -- never append to another contract's artifact

## CRUD Scripts

### new-artifact.ps1 -- Create artifact from template for a contract
```
new-artifact.ps1 -ProjectName "auth" -Agent "researcher" -ContractId "TSK-001"
```
Params: -ProjectName, -Agent, -ContractId (all required), -BasePath, -Force

### get-artifact.ps1 -- Read artifact, single field, or list all
```
get-artifact.ps1 -ProjectName "auth" -Agent "researcher" -ContractId "TSK-001"
get-artifact.ps1 -ProjectName "auth" -Agent "researcher" -ContractId "TSK-001" -Field "goal"
get-artifact.ps1 -ProjectName "auth" -Agent "developer"
```
Params: -ProjectName, -Agent required. -ContractId (read one), -Field (single field). No ContractId = list all.

### update-artifact.ps1 -- Update a field in an artifact
```
update-artifact.ps1 -ProjectName "auth" -Agent "researcher" -ContractId "TSK-001" -Field "goal" -Value "JWT auth"
```
Params: -ProjectName, -Agent, -ContractId, -Field, -Value (all required), -Status default active

### validate-artifact.ps1 -- Check required fields are populated
```
validate-artifact.ps1 -ProjectName "auth" -Agent "researcher" -ContractId "TSK-001"
validate-artifact.ps1 -ProjectName "auth" -Agent "developer"
```
Params: -ProjectName, -Agent required. -ContractId validates one; omit to validate all in agent dir.

## Infrastructure Scripts

### init-project.ps1 -- Create agent directories (no pre-created files)
```
init-project.ps1 -ProjectName "auth"
```
Params: -ProjectName required, -BasePath

### artifact-status.ps1 -- Artifact dashboard (scans all .yml per agent)
```
artifact-status.ps1 -ProjectName "auth"
```
Params: -ProjectName required, -Root

### check-gate.ps1 -- Quality gate (validates all artifacts in agent dir)
```
check-gate.ps1 -ProjectName "auth" -Phase "research"
```
Params: -ProjectName required, -Phase (research|architecture|ui-design|planning|development|reviews|testing|all), -Root

