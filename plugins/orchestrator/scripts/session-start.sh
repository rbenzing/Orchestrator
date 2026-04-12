#!/usr/bin/env bash
# SessionStart hook: injects orchestrator recovery context if an active session exists.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/session-start.ps1"
exit $?
