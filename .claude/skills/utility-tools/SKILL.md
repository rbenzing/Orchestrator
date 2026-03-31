---
name: utility-tools
description: Cost-saving PowerShell scripts that reduce agent token usage during task execution. Includes artifact summarization, symbol extraction, error log truncation, compact diff generation, formatting/linting, and workspace cleanup.
---

# Skill: utility-tools

Cost-saving scripts that reduce agent token usage during task execution.
All scripts are designed to be composable and callable from any agent or the orchestrator loop.

## Scripts

### `summarize-artifact.ps1`
Produces a compact structural summary of large Markdown artifacts (architecture docs, story breakdowns, specs).
Extracts headings, bullets, key:value pairs — skips prose and code bodies.
Use this **before** loading a full artifact so you can decide if the full version is needed.

```powershell
.claude\skills\utility-tools\scripts\summarize-artifact.ps1 -Path ".claude\artifacts\{project}\architect\architecture.md"
.claude\skills\utility-tools\scripts\summarize-artifact.ps1 -Path ".claude\artifacts\{project}\planner\story-breakdown.md" -MaxLines 80
```

**Parameters**: `-Path` (required), `-MaxLines` (default 60), `-IncludeBody` (include 3 body lines per heading)

---

### `extract-symbols.ps1`
Extracts specific functions, classes, or interfaces from source files using regex.
Prevents agents from loading entire monolithic files when they only need a single method signature.

```powershell
.claude\skills\utility-tools\scripts\extract-symbols.ps1 -Path "src\auth\login.ts" -Symbol "login"
.claude\skills\utility-tools\scripts\extract-symbols.ps1 -Path "src\models\user.ts" -Type "interface"
```

---

### `truncate-error-log.ps1`
Wraps a test/build command and slices its output to the last N lines of the first failure.
Prevents 2000-line stack traces from flooding agent context.

```powershell
.claude\skills\utility-tools\scripts\truncate-error-log.ps1 -Command "npm test" -MaxLines 30
.claude\skills\utility-tools\scripts\truncate-error-log.ps1 -Command "dotnet test" -MaxLines 50 -ProjectPath "src\Api"
```

---

### `get-compact-diff.ps1`
Generates a summarized unified diff between two refs (or working tree vs HEAD).
Used by the Code Reviewer agent to review only what changed.

```powershell
.claude\skills\utility-tools\scripts\get-compact-diff.ps1
.claude\skills\utility-tools\scripts\get-compact-diff.ps1 -Ref1 "main" -Ref2 "HEAD" -Stat
```

---

### `format-and-lint.ps1`
Auto-detects project type (Node/TS, .NET, Python) and runs the appropriate formatter/linter.
Resolves trivial style issues before the Code Reviewer agent is invoked.

```powershell
.claude\skills\utility-tools\scripts\format-and-lint.ps1
.claude\skills\utility-tools\scripts\format-and-lint.ps1 -Fix:$false          # dry-run / report only
.claude\skills\utility-tools\scripts\format-and-lint.ps1 -Paths "src/auth"    # scope to a directory
```

Supports: `prettier`, `eslint`, `dotnet format`, `ruff`, `black`

---

### `cleanup-workspace.ps1`
Deletes common cache and temp directories to keep the workspace clean between tasks.
Called by `run-orchestrator.ps1` as a post-task hook after each contract is closed.

```powershell
.claude\skills\utility-tools\scripts\cleanup-workspace.ps1
.claude\skills\utility-tools\scripts\cleanup-workspace.ps1 -Root "C:\Src\my-project" -DryRun
```

Cleans: `.pytest_cache`, `node_modules/.cache`, `coverage/`, `.nyc_output`, `dist/`, `build/`, large log files > 1MB.

---

## When to Use These Scripts

| Situation | Script |
|-----------|--------|
| Need to understand a large artifact before reading it fully | `summarize-artifact.ps1` |
| Need a single function/class from a large source file | `extract-symbols.ps1` |
| Test run produced thousands of lines of output | `truncate-error-log.ps1` |
| Code Reviewer needs to see what changed | `get-compact-diff.ps1` |
| About to invoke Code Reviewer — clean up style first | `format-and-lint.ps1` |
| A contract just closed — clean up temp files | `cleanup-workspace.ps1` |

