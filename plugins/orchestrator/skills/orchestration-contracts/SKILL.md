---
name: orchestration-contracts
description: Manages the full lifecycle of YAML task contracts — creation, status transitions, retrieval, and archival. Core routing primitive for the Contract-Router architecture.
---

> **TOOL**: Always call these scripts via `launch-process`. Never use `Bash`.
> **FORMAT**: All parameters on a single line — no backtick line continuation.
> **PATH**: Use `${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\` prefix.

## Scripts

### `new-contract.ps1`
Creates a new YAML contract file under `.claude/orchestrator/contracts/{ProjectName}/`.

```
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\new-contract.ps1 -ProjectName "user-auth" -ContractId "TSK-001" -Type "Task" -AssignedAgent "@developer" -ModelTier "sonnet" -Objective "Implement the JWT login endpoint." -Deliverables "src/auth/login.ts","tests/auth/login.test.ts" -AcceptanceCriteria "All unit tests pass","check-gate passes" -IfPass "Route to @code-reviewer" -IfFail "Return to Router with Feedback Contract"
```

Required: `-ProjectName` `-ContractId` `-Type` `-AssignedAgent` `-Objective`
Optional: `-ModelTier` `-Deliverables` `-AcceptanceCriteria` `-RequiredReads` `-Dependencies` `-IfPass` `-IfFail`

**Types**: `Project` | `Story` | `Task` | `TDD-Red` | `TDD-Green` | `TDD-Refactor` | `Feedback` | `Validation`
**ModelTier**: `haiku` | `sonnet` | `opus`

### `update-contract.ps1`
Transitions a contract's status and appends an execution history entry.

```
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\update-contract.ps1 -ProjectName "user-auth" -ContractId "TSK-001" -Status "Closed"
```

```
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\update-contract.ps1 -ProjectName "user-auth" -ContractId "TSK-001" -Status "Blocked" -ErrorTrace "check-gate: 3/4 tests passed" -FailedRef "src/auth/login.ts"
```

Required: `-ProjectName` `-ContractId` `-Status`
Optional: `-ErrorTrace` `-FailedRef`
**Statuses**: `Open` | `Review` | `Blocked` | `Closed`

### `get-contract.ps1`
Reads the active Open contract for an agent. Outputs the YAML file path.

```
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\get-contract.ps1 -ProjectName "user-auth" -AssignedAgent "@developer"
```

```
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\get-contract.ps1 -ProjectName "user-auth" -ContractId "TSK-001" -Raw
```

Required: `-ProjectName`
Optional: `-AssignedAgent` `-ContractId` `-Raw`

### `archive-contracts.ps1`
Moves all Closed contracts into `.claude/orchestrator/contracts/{project}/archive/{date}/`.

```
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\archive-contracts.ps1 -ProjectName "user-auth"
```

```
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\archive-contracts.ps1 -ProjectName "all" -DryRun
```

Required: `-ProjectName`
Optional: `-DryRun`

### `run-orchestrator.ps1`
Dependency-aware dispatch loop. Reads all Open contracts, resolves dependencies, outputs dispatch order.

```
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\run-orchestrator.ps1 -ProjectName "user-auth"
```

```
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\run-orchestrator.ps1 -ProjectName "user-auth" -Dispatch
```

```
${CLAUDE_PLUGIN_ROOT}\skills\orchestration-contracts\scripts\run-orchestrator.ps1 -ProjectName "user-auth" -PostTask -CompletedContractID "TSK-003"
```

Required: `-ProjectName`
Optional: `-Dispatch` `-PostTask` `-CompletedContractID`
