#!/usr/bin/env bash
# UserPromptSubmit hook — injects ambient orchestration context into every prompt.
# Keeps Claude oriented on the active project/phase/agent without reading files.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/user-prompt-submit.ps1"
exit $?
