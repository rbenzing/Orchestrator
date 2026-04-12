#!/usr/bin/env bash
# PostToolUse hook: injects token budget warning when approaching session limit.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/post-tool-budget.ps1"
exit $?
