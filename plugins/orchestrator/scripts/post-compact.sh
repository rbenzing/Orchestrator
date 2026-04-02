#!/usr/bin/env bash
# PostCompact hook — injects resume instructions after context compaction.
# Claude reads this to re-orient immediately after the context window resets.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/post-compact.ps1"
exit $?
