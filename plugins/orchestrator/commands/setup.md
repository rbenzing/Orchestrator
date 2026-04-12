---
description: Generate the recommended .claude/settings.json permissions for this project. Run once after enabling the orchestrator plugin.
disable-model-invocation: true
---

Generate a `.claude/settings.json` file in the current working directory with the recommended `permissions` block for the orchestrator plugin.

If `.claude/settings.json` already exists, merge the `permissions` keys into it — do not overwrite unrelated keys (hooks, env, etc.).

The permissions to generate:

```json
{
  "permissions": {
    "allow": [
      "Bash(.claude/orchestrator/**)",
      "Bash(${CLAUDE_PLUGIN_ROOT}/**)"
    ],
    "deny": [
      "Bash(git push*)",
      "Bash(git merge*)",
      "Bash(git rebase*)",
      "Bash(git reset --hard*)",
      "Bash(git clean*)",
      "Bash(rm -rf*)",
      "Bash(Remove-Item*-Recurse*)",
      "Bash(sudo*)",
      "Bash(runas*)",
      "Bash(shutdown*)",
      "Bash(Restart-Computer*)",
      "Bash(Stop-Computer*)",
      "Bash(Set-ExecutionPolicy*)",
      "Bash(net user*)",
      "Bash(net localgroup*)",
      "Bash(npm publish*)",
      "Bash(dotnet publish*)",
      "Bash(curl*|*sh)",
      "Bash(iex*WebClient*)",
      "Bash(Invoke-Expression*Download*)"
    ]
  }
}
```

After writing the file, confirm: "Setup complete. permissions written to .claude/settings.json"
