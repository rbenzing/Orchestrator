---
name: orchestration-contracts
description: YAML contract lifecycle, dispatch, and archival
---

# Orchestration Contracts

Manages full lifecycle of YAML task contracts -- creation, status transitions, retrieval, archival.

## Scripts

### new-contract.ps1 -- Create YAML contract
```powershell
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\new-contract.ps1 `
  -ProjectName "user-auth" -ContractId "TSK-001" -Type "Task" `
  -AssignedAgent "@developer" -ModelTier "sonnet" `
  -Objective "Implement the JWT login endpoint" `
  -Deliverables "src/auth/login.ts","tests/auth/login.test.ts" `
  -AcceptanceCriteria "All unit tests pass","check-gate passes" `
  -RequiredReads "${CLAUDE_PLUGIN_ROOT}/artifacts/user-auth/planning/stories.md" `
  -IfPass "Route to @code-reviewer" -IfFail "Return to Router with Feedback Contract"
```
Types: Project | Story | Task | TDD-Red | TDD-Green | TDD-Refactor | Feedback | Validation
ModelTier: haiku lint/typos | sonnet standard | opus complex/retry

### update-contract.ps1 -- Transition status
```powershell
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\update-contract.ps1 `
  -ProjectName "user-auth" -ContractId "TSK-001" -Status "Closed"

${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\update-contract.ps1 `
  -ProjectName "user-auth" -ContractId "TSK-001" -Status "Blocked" `
  -ErrorTrace "check-gate: 3/4 tests passed" -FailedRef "src/auth/login.ts"
```
Statuses: Open | Review | Blocked | Closed

### get-contract.ps1 -- Read active contract
```powershell
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\get-contract.ps1 `
  -ProjectName "user-auth" -AssignedAgent "@developer"

${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\get-contract.ps1 `
  -ProjectName "user-auth" -ContractId "TSK-001" -Raw
```

### archive-contracts.ps1 -- Archive closed contracts
```powershell
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\archive-contracts.ps1 -ProjectName "user-auth"
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\archive-contracts.ps1 -ProjectName "all" -DryRun
```

## Contract File Layout
```
${CLAUDE_PLUGIN_ROOT}/contracts/{project-name}/
  TSK-001.yml    # Open/Active
  archive/2025-01-15/TSK-000.yml  # Closed
```

