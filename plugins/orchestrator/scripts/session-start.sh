#!/usr/bin/env bash
# SessionStart hook — discovers and surfaces active orchestration projects.
# Eliminates the need to manually run load-state.ps1 at session start.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/session-start.ps1"
exit $?
