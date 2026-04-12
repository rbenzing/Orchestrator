#!/usr/bin/env bash
# Stop hook: blocks agent stop when open contracts exist and state is unsaved.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/stop-guard.ps1"
exit $?
