---
name: utility-tools
description: Cost-saving PowerShell scripts that reduce agent token usage during task execution. Includes artifact summarization, symbol extraction, error log truncation, compact diff generation, formatting/linting, and workspace cleanup.
---

## Scripts

### `summarize-artifact.ps1`
Extracts headings, bullets, key:value pairs from large Markdown artifacts — skips prose and code bodies. Use before loading a full artifact to decide if the full version is needed.

```powershell
${CLAUDE_PLUGIN_ROOT}\skills\utility-tools\scripts\summarize-artifact.ps1 -Path ".claude\orchestrator\artifacts\{project}\architect\architecture.md"
${CLAUDE_PLUGIN_ROOT}\skills\utility-tools\scripts\summarize-artifact.ps1 -Path ".claude\orchestrator\artifacts\{project}\planner\story-breakdown.md" -MaxLines 80
```
Params: `-Path` (required), `-MaxLines` (default 60), `-IncludeBody`

### `extract-symbols.ps1`
Extracts specific functions, classes, or interfaces from source files using regex. Use when only a single method signature is needed from a large file.

```powershell
${CLAUDE_PLUGIN_ROOT}\skills\utility-tools\scripts\extract-symbols.ps1 -Path "src\auth\login.ts" -Symbol "login"
${CLAUDE_PLUGIN_ROOT}\skills\utility-tools\scripts\extract-symbols.ps1 -Path "src\models\user.ts" -Type "interface"
```

### `truncate-error-log.ps1`
Wraps a test/build command and slices output to the last N lines of the first failure. Use when test output exceeds readable context.

```powershell
${CLAUDE_PLUGIN_ROOT}\skills\utility-tools\scripts\truncate-error-log.ps1 -Command "npm test" -MaxLines 30
${CLAUDE_PLUGIN_ROOT}\skills\utility-tools\scripts\truncate-error-log.ps1 -Command "dotnet test" -MaxLines 50 -ProjectPath "src\Api"
```

### `get-compact-diff.ps1`
Summarized unified diff between two refs or working tree vs HEAD. Use for code review.

```powershell
${CLAUDE_PLUGIN_ROOT}\skills\utility-tools\scripts\get-compact-diff.ps1
${CLAUDE_PLUGIN_ROOT}\skills\utility-tools\scripts\get-compact-diff.ps1 -Ref1 "main" -Ref2 "HEAD" -Stat
```

### `format-and-lint.ps1`
Auto-detects project type (Node/TS, .NET, Python) and runs the appropriate formatter/linter. Run before invoking Code Reviewer.

```powershell
${CLAUDE_PLUGIN_ROOT}\skills\utility-tools\scripts\format-and-lint.ps1
${CLAUDE_PLUGIN_ROOT}\skills\utility-tools\scripts\format-and-lint.ps1 -Fix:$false
${CLAUDE_PLUGIN_ROOT}\skills\utility-tools\scripts\format-and-lint.ps1 -Paths "src/auth"
```
Supports: `prettier`, `eslint`, `dotnet format`, `ruff`, `black`

### `cleanup-workspace.ps1`
Deletes common cache and temp directories between tasks.

```powershell
${CLAUDE_PLUGIN_ROOT}\skills\utility-tools\scripts\cleanup-workspace.ps1
${CLAUDE_PLUGIN_ROOT}\skills\utility-tools\scripts\cleanup-workspace.ps1 -Root "C:\Src\my-project" -DryRun
```
Cleans: `.pytest_cache`, `node_modules/.cache`, `coverage/`, `.nyc_output`, `dist/`, `build/`, log files > 1MB.
