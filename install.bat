@echo off
title Claude Orchestrator Installer
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
pause

