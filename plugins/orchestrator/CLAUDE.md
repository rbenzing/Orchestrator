# Orchestrator Plugin — Tool Usage Rules

## Tool Preference

Always prefer orchestrator plugin scripts over built-in tools for the operations below.
These scripts handle path resolution, state tracking, and contract management correctly.

| Operation | Use this | Not this |
|-----------|----------|----------|
| Read a file | Built-in Read / view is fine | — |
| Search files | Built-in Grep / Glob is fine | — |
| Save workflow state | `save-state.ps1` | Manual YAML writes |
| Load workflow state | `load-state.ps1` | Reading state files directly |
| Clear workflow state | `clear-state.ps1` | Deleting state files manually |
| Create a contract | `new-contract.ps1` | Manual YAML writes |
| Update a contract | `update-contract.ps1` | Editing contract files directly |
| Get open contracts | `get-contract.ps1` | Reading contract dirs directly |
| Archive contracts | `archive-contracts.ps1` | Manual moves |
| Run dispatch loop | `run-orchestrator.ps1` | Ad-hoc dispatch logic |
| Agent hand-off | `handoff.ps1` | Calling new-contract.ps1 directly |
| Init artifact dirs | `init-project.ps1` | mkdir / New-Item |
| Create artifact | `new-artifact.ps1` | Writing YAML manually |
| Update artifact | `update-artifact.ps1` | Editing artifact files directly |
| Get artifact | `get-artifact.ps1` | Reading artifact files directly |
| Validate artifact | `validate-artifact.ps1` | Manual checks |
| Artifact status | `artifact-status.ps1` | Counting files manually |
| Check quality gate | `check-gate.ps1` | Manual acceptance criteria checks |
| Draft+Verify result | `draft-verify.ps1` | Ad-hoc artifact promotion |
| Generate subagent prompt | `generate-subagent-prompt.ps1` | Inline prompt construction |

## Script Root

All plugin scripts are under `${CLAUDE_PLUGIN_ROOT}\skills\` and `${CLAUDE_PLUGIN_ROOT}\scripts\`.
Invoke them with the `Bash` tool using their full path.

## Permissions

- Only run scripts inside `.claude/orchestrator/` or under `${CLAUDE_PLUGIN_ROOT}`.
- Never run destructive git operations (push, merge, reset --hard, clean).
- Never escalate privileges (sudo, runas, Set-ExecutionPolicy).
- Never publish packages or trigger deployments.
