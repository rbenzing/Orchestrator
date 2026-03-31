# Skills Module Rules

All agents run in **Contract-Router** mode. Stateless. No shared context. Every task = one YAML contract.

## Contract Startup Protocol (all non-orchestrator agents)

1. `get-contract.ps1 -ProjectName "{project}" -AssignedAgent "@{role}"`
2. Parse: `objective`, `required_reads`, `acceptance_criteria`, `deliverables`
3. Read ONLY files in `required_reads`
4. Execute the `objective` — no scope expansion
5. Validate all `acceptance_criteria`
6. Close: `update-contract.ps1 -ProjectName "{project}" -ContractId "{id}" -Status "Closed"` (or `"Blocked" -ErrorTrace "..."`)
7. Summarize: `summarize-artifact.ps1 -Path ".claude/artifacts/{project}/{role}/primary-deliverable.md"`
8. **Stop** — do not proceed, do not create contracts, do not hand off

## Execution Loop — DPVI

Every unit of work follows: **Decompose** (smallest independent sub-tasks) → **Parallel** (execute independent tasks concurrently) → **Verify** (run `check-gate.ps1`, cross-check acceptance criteria) → **Iterate** (fix failures, re-verify, max 3 cycles then escalate).

## Escalation Protocol

Never ask the user. Escalate blockers to Orchestrator:
```
handoff.ps1 -From "{role}" -To "Orchestrator" -ProjectName "{project}" -IsFeedback -Issues "blocker: ..."
```

## Skills Reference

| Skill | Scripts |
|-------|---------|
| orchestration-contracts | new, get, update, archive, run-orchestrator |
| orchestration-artifacts | init-project, artifact-status, check-gate |
| orchestration-handoffs | handoff |
| orchestration-state | save-state, load-state |
| utility-tools | extract-symbols, summarize-artifact, format-and-lint, cleanup-workspace, get-compact-diff, truncate-error-log |
| dev-tools | grep, find-files, tree, git-summary, git-diff, kill-port, remove-files |
| nodejs-windows | run-tests, run-lint, run-build |
| angular-windows | run-tests, run-build, run-serve |
| dotnet-windows | dotnet-build, dotnet-test, dotnet-run, dotnet-restore, dotnet-format |
| polyglot-tools | python-run, pip-install, poetry-run, cargo-run, go-run, ruby-run |
| windows-environment | mkdir, copy-item, move-item, rename-item |

## Permissions

- **Orchestrator**: all orchestration-* scripts
- **Developer**: dev-tools, utility-tools, nodejs/angular/dotnet-windows, polyglot-tools, windows-environment
- **Tester**: dev-tools, nodejs/angular/dotnet-windows, utility-tools (truncate-error-log)
- **Code Reviewer**: dev-tools (git-diff, grep), utility-tools (get-compact-diff, summarize-artifact)
- **All agents**: read SKILL.md files; use `summarize-artifact.ps1` for files >300 lines; never modify scripts

## Conventions

- Artifacts go in `.claude/artifacts/{project}/{role}/` — keep each file <500 lines
- Use bullet points/tables over prose. Reference file paths instead of inlining code.
- Never create project code inside `.claude/`
- Prefer toolkit scripts over raw PowerShell (see `powershell-rules.md`)

