---
name: extract-symbols
description: Extract function/class from source file
---

# extract-symbols.ps1

Extract specific functions, classes, or interfaces from source files. Avoids loading full files.

```
${CLAUDE_PLUGIN_ROOT}\skills\extract-symbols\scripts\extract-symbols.ps1 -FilePath "src\auth\login.ts" -Symbols "loginHandler","AuthError"
${CLAUDE_PLUGIN_ROOT}\skills\extract-symbols\scripts\extract-symbols.ps1 -FilePath "src\models\user.ts" -Symbols "UserModel" -ContextLines 4
```

Params: -FilePath required, -Symbols required (array), -ContextLines default 2

## When to Use
- Need one function/class from a large file
