# Orchestration Module Rules

## Scope
These rules apply to all files within the `/orchestration/` directory tree.

## Agent Permissions

### Orchestrator Agent
- **Full access** to all orchestration artifacts and prompts
- Can create, modify, and delete project artifacts under `artifacts/`
- Can read all prompt definitions under `prompts/`
- Must use `check-gate.ps1` before phase transitions

### Researcher Agent
- **Write access** to `artifacts/{project}/research/`
- **Read access** to all other artifacts for context
- Must not modify prompt definitions

### Architect Agent
- **Write access** to `artifacts/{project}/architecture/`
- **Read access** to research artifacts for context
- Must not modify prompt definitions

### UI Designer Agent
- **Write access** to `artifacts/{project}/ui-design/`
- **Read access** to research and architecture artifacts for context

### Planner Agent
- **Write access** to `artifacts/{project}/planning/`
- **Read access** to research, architecture, and UI design artifacts

### Developer Agent
- **Write access** to `artifacts/{project}/development/`
- **Read access** to all prior phase artifacts
- Must create project code **outside** the `/orchestration/` directory

### Code Reviewer Agent
- **Write access** to `artifacts/{project}/reviews/`
- **Read access** to all artifacts and project source code

### Tester Agent
- **Write access** to `artifacts/{project}/testing/`
- **Read access** to all artifacts and project source code

## Conventions
- All artifact files must follow the naming conventions defined in each phase's prompt
- Artifacts must be organized by project name under `artifacts/{project}/`
- Prompt files are read-only reference material — never modify them during project execution
- State files are managed exclusively by orchestration-state scripts

