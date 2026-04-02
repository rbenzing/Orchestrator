#!/usr/bin/env bash
# SubagentStart hook — injects active project/contract context into each subagent.
# Subagents know which project they're operating in without being told explicitly.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/subagent-start.ps1"
exit $?
