# Orchestration Artifacts

This directory contains all work products generated during the multi-agent development process.

## Directory Structure

```
/artifacts/
  /research/{project-name}/          - Research phase outputs
  /architecture/{project-name}/      - Architecture phase outputs
  /ui-design/{project-name}/         - UI design phase outputs
  /planning/{project-name}/          - Planning phase outputs
  /development/{project-name}/       - Development phase outputs
  /reviews/{project-name}/           - Code review phase outputs
  /testing/{project-name}/           - Testing phase outputs
```

## Artifact Types by Phase

### Research Phase
- `context-document.md` - Comprehensive problem analysis and context
- `requirements.md` - Detailed requirements breakdown
- `technical-constraints.md` - Technical limitations and considerations

### Architecture Phase
- `system-architecture.md` - System architecture design and diagrams
- `adrs/` - Architecture Decision Records
- `component-boundaries.md` - Component boundary definitions

### UI Design Phase
- `ui-specifications.md` - UI/UX specifications and wireframes
- `design-system.md` - Design system definitions (colors, typography, spacing)
- `accessibility-specs.md` - Accessibility requirements and standards

### Planning Phase
- `stories.md` - User stories with acceptance criteria
- `technical-plan.md` - Technical implementation plan and architecture
- `task-breakdown.md` - Detailed task breakdown with sequences

### Development Phase
- `implementation-notes.md` - Developer's implementation notes and decisions
- `build-logs.txt` - Build and lint output logs
- Source code files (in main project directories)

### Review Phase
- `code-review-report.md` - Comprehensive code review findings
- `feedback.md` - Detailed feedback for developer (if changes needed)

### Testing Phase
- `test-results.md` - Complete test execution results
- `bug-reports.md` - Detailed bug reports (if issues found)
- `test-coverage.md` - Test coverage analysis

## Workflow

1. **Orchestrator** initiates project → assigns to **Researcher**
2. **Researcher** creates artifacts in `/research/{project}/` → hands to **Architect**
3. **Architect** creates artifacts in `/architecture/{project}/` → hands to **UI Designer** (or **Planner** if backend-only)
4. **UI Designer** creates artifacts in `/ui-design/{project}/` → hands to **Planner**
5. **Planner** creates artifacts in `/planning/{project}/` → hands to **Tester** (TDD test authoring)
6. **Tester** authors failing tests → hands to **Developer**
7. **Developer** creates artifacts in `/development/{project}/` → hands to **Code Reviewer**
8. **Code Reviewer** creates artifacts in `/reviews/{project}/` → hands to **Tester** or back to **Developer**
9. **Tester** creates artifacts in `/testing/{project}/` → reports to **Orchestrator**

## Artifact Lifecycle

- **Created**: When agent completes their phase
- **Referenced**: By downstream agents for context
- **Updated**: During iteration/feedback loops
- **Archived**: After project completion

## Best Practices

1. **Naming**: Use descriptive, consistent names
2. **Format**: Use Markdown for readability
3. **Completeness**: Include all required sections
4. **Clarity**: Write for other agents to understand
5. **Traceability**: Reference related artifacts
6. **Versioning**: Note dates and versions for iterations

## Getting Started

When starting a new project:
1. Orchestrator creates project brief
2. Each agent creates their artifacts in the appropriate directory
3. Agents reference previous phase artifacts for context
4. All artifacts are preserved for project history

---

**Note**: This directory structure supports the multi-agent orchestration workflow. Each agent is responsible for creating and maintaining their phase's artifacts.

