#!/usr/bin/env bash
# PreCompact hook — serializes orchestration state into compaction context.
# Ensures workflow position survives conversation summarization.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/pre-compact.ps1"
exit $?
