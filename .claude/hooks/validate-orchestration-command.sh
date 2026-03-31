#!/usr/bin/env bash
# Hook entry point: pipes stdin JSON to the PowerShell validator.
# Claude hooks require a .sh file; this wrapper delegates to PowerShell on Windows.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/validate-orchestration-command.ps1"
exit $?

