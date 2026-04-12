#!/usr/bin/env bash
# PreToolUse hook: pipes stdin JSON to the PowerShell token budget guard.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/token-budget-guard.ps1"
exit $?
