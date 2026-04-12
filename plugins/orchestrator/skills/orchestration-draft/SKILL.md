---
name: orchestration-draft
description: Draft-and-verify harness runs a Haiku draft of a contract then uses the agent's assigned model to verify or fix.
---

Always call these scripts via `launch-process`. Never use `Bash`.

All parameters on a single line — no backtick line continuation.

Scripts are at: `${CLAUDE_PLUGIN_ROOT}\skills\orchestration-draft\scripts\`

---

## draft-verify.ps1

Records the outcome of a Draft+Verify execution cycle and promotes draft artifacts to the final agent directory.

**When to call**: After both the draft phase (Haiku) and verify phase (Sonnet) have completed. The agent calls this script to finalize the result before running `check-gate.ps1`.

**Usage**:

```
launch-process: ${CLAUDE_PLUGIN_ROOT}\skills\orchestration-draft\scripts\draft-verify.ps1 -ProjectName "{project}" -ContractId "{contract-id}" -AgentDir "{agent-dir}" -Result "pass"
```

```
launch-process: ${CLAUDE_PLUGIN_ROOT}\skills\orchestration-draft\scripts\draft-verify.ps1 -ProjectName "{project}" -ContractId "{contract-id}" -AgentDir "{agent-dir}" -Result "fix" -FailedCriteria "Criterion A","Criterion B"
```

**Required parameters**:

| Parameter | Description |
|---|---|
| `-ProjectName` | Project identifier (e.g. `user-auth`) |
| `-ContractId` | Contract ID (e.g. `TSK-003`) |
| `-AgentDir` | Agent artifact dir name: `developer`, `tester`, or `planner` |
| `-Result` | `pass` — draft promoted unchanged \| `fix` — verifier corrected artifacts |

**Optional parameters**:

| Parameter | Default | Description |
|---|---|---|
| `-FailedCriteria` | `@()` | Acceptance criteria strings that failed the draft — recorded for audit |
| `-Root` | cwd | Repository root |

**What it does**:

- `pass`: copies all files from `draft/{project}/{contract-id}/` → `artifacts/{project}/{agent-dir}/`
- `fix`: records failed criteria (verifier has already written corrected artifacts to the final dir)
- Updates contract YAML: sets `draft_result` and `draft_notes`
- Prints cost estimate: ~30% (pass) or ~110% (fix) vs a full Sonnet run

**Draft artifact dir** (where Haiku writes during draft phase):
```
.claude/orchestrator/draft/{project}/{contract-id}/
```

**Final artifact dir** (where check-gate reads from — always):
```
.claude/orchestrator/artifacts/{project}/{agent-dir}/
```
