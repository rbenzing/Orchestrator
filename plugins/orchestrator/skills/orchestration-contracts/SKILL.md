---
name: orchestration-contracts
description: Manages the full lifecycle of YAML task contracts — creation, status transitions, retrieval, and archival. Core routing primitive for the Contract-Router architecture.
---

## Scripts

### `new-contract.ps1`
Creates a new YAML contract file under `.claude/orchestrator/contracts/{ProjectName}/`.

```powershell
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\new-contract.ps1 `
  -ProjectName "user-auth" `
  -ContractId  "TSK-001" `
  -Type        "Task" `
  -AssignedAgent "@developer" `
  -ModelTier   "sonnet" `
  -Objective   "Implement the JWT login endpoint." `
  -Deliverables "src/auth/login.ts","tests/auth/login.test.ts" `
  -AcceptanceCriteria "All unit tests pass","check-gate passes" `
  -RequiredReads ".claude/orchestrator/artifacts/user-auth/planning/stories.md" `
  -IfPass "Route to @code-reviewer" `
  -IfFail "Return to Router with Feedback Contract"
```
**Types**: `Project` | `Story` | `Task` | `TDD-Red` | `TDD-Green` | `TDD-Refactor` | `Feedback` | `Validation`
**ModelTier**: `haiku` (lint/typos) | `sonnet` (standard) | `opus` (complex/retry)

### `update-contract.ps1`
Transitions a contract's status and appends an execution history entry.

```powershell
# Mark closed (success)
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\update-contract.ps1 `
  -ProjectName "user-auth" -ContractId "TSK-001" -Status "Closed"

# Mark blocked (failure) — increments attempt_count
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\update-contract.ps1 `
  -ProjectName "user-auth" -ContractId "TSK-001" -Status "Blocked" `
  -ErrorTrace  "check-gate: 3/4 tests passed" `
  -FailedRef   "src/auth/login.ts"
```
**Statuses**: `Open` | `Review` | `Blocked` | `Closed`

### `get-contract.ps1`
Reads the active Open contract for an agent. Outputs the YAML file path.

```powershell
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\get-contract.ps1 `
  -ProjectName "user-auth" -AssignedAgent "@developer"

${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\get-contract.ps1 `
  -ProjectName "user-auth" -ContractId "TSK-001" -Raw
```

### `archive-contracts.ps1`
Moves all Closed contracts into `.claude/orchestrator/contracts/{project}/archive/{date}/`.

```powershell
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\archive-contracts.ps1 -ProjectName "user-auth"
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\archive-contracts.ps1 -ProjectName "all" -DryRun
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\archive-contracts.ps1 -ProjectName "all"
```

### `run-orchestrator.ps1`
Dependency-aware dispatch loop. Reads all Open contracts, resolves dependencies, outputs dispatch order.

```powershell
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\run-orchestrator.ps1 -ProjectName "user-auth"
```
