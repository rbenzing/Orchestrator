# Skill: orchestration-contracts

## Purpose
Manages the full lifecycle of YAML task contracts — creation, status transitions, retrieval, and archival. This is the core routing primitive for the Contract-Router architecture.

## Scripts

### `new-contract.ps1`
Creates a new YAML contract file under `.claude/contracts/{ProjectName}/`.

```powershell
.claude\skills\orchestration-contracts\scripts\new-contract.ps1 `
  -ProjectName "user-auth" `
  -ContractId  "TSK-001" `
  -Type        "Task" `
  -AssignedAgent "@developer" `
  -ModelTier   "sonnet" `
  -Objective   "Implement the JWT login endpoint." `
  -Deliverables "src/auth/login.ts","tests/auth/login.test.ts" `
  -AcceptanceCriteria "All unit tests pass","check-gate passes" `
  -RequiredReads ".claude/artifacts/user-auth/planning/stories.md" `
  -IfPass "Route to @code-reviewer" `
  -IfFail "Return to Router with Feedback Contract"
```

**Types**: `Project` | `Story` | `Task` | `TDD-Red` | `TDD-Green` | `TDD-Refactor` | `Feedback` | `Validation`  
**ModelTier**: `haiku` (lint/typos) | `sonnet` (standard) | `opus` (complex/retry)

---

### `update-contract.ps1`
Transitions a contract's status and appends an execution history entry.

```powershell
# Mark closed (success)
.claude\skills\orchestration-contracts\scripts\update-contract.ps1 `
  -ProjectName "user-auth" -ContractId "TSK-001" -Status "Closed"

# Mark blocked (failure) — increments attempt_count
.claude\skills\orchestration-contracts\scripts\update-contract.ps1 `
  -ProjectName "user-auth" -ContractId "TSK-001" -Status "Blocked" `
  -ErrorTrace  "check-gate: 3/4 tests passed" `
  -FailedRef   "src/auth/login.ts"
```

**Statuses**: `Open` | `Review` | `Blocked` | `Closed`

---

### `get-contract.ps1`
Reads the active Open contract for an agent. Outputs the YAML file path.

```powershell
# Find active contract for an agent
.claude\skills\orchestration-contracts\scripts\get-contract.ps1 `
  -ProjectName "user-auth" -AssignedAgent "@developer"

# Read a specific contract (raw YAML)
.claude\skills\orchestration-contracts\scripts\get-contract.ps1 `
  -ProjectName "user-auth" -ContractId "TSK-001" -Raw
```

---

### `archive-contracts.ps1`
Moves all Closed contracts into `.claude/contracts/{project}/archive/{date}/`.

```powershell
# Archive one project
.claude\skills\orchestration-contracts\scripts\archive-contracts.ps1 -ProjectName "user-auth"

# Archive all projects (dry run first)
.claude\skills\orchestration-contracts\scripts\archive-contracts.ps1 -ProjectName "all" -DryRun
.claude\skills\orchestration-contracts\scripts\archive-contracts.ps1 -ProjectName "all"
```

---

## Contract File Layout
```
.claude/contracts/
  {project-name}/
    TSK-001.yml      # Open/Active
    TSK-002.yml      # Open/Active
    archive/
      2025-01-15/
        TSK-000.yml  # Closed
```

## Schema Reference
See `planned-upgrade/contract-schema.md` for the full YAML field specification.

