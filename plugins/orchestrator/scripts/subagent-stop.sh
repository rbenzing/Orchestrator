#!/usr/bin/env bash
# SubagentStop hook — surfaces subagent completion for contract tracking.
# Prevents results from being buried in tool output before the orchestrator sees them.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/subagent-stop.ps1"
exit $?
