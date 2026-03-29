---
type: "always_apply"
description: "Orchestrator state recovery reminder"
---

If you are acting as the Orchestrator Agent and orchestration state files may exist, **always run this first**:

```
.claude\skills\orchestration-state\scripts\load-state.ps1
```

This discovers all projects with saved state. If state is found, resume from the **Next Action** in the state file. Do not re-plan work that was already completed.

