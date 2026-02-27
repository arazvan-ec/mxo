# Task System Context

## Overview

MXO uses a file-based task tracking system following agent-native architecture principles. Tasks are the first entity type and serve as the model for all future entity types.

## Task Architecture

### Directory Structure

Each task is an entity following the entity-scoped directory pattern:

```
tasks/{task_id}/
├── task.json       # Structured task data (source of truth for state)
├── notes.md        # Human-readable description, requirements, context
└── agent_log.md    # Agent reasoning, decisions, progress notes
```

### Task ID Convention

Format: `{NNN}_{snake_case_short_description}`

Examples: `001_bootstrap_project`, `002_add_user_auth`, `003_fix_login_bug`

Numeric prefix ensures chronological ordering. Description ensures human readability.

### Task States

| State       | Meaning                                    |
|-------------|--------------------------------------------|
| pending     | Created but work has not started           |
| in_progress | Actively being worked on                   |
| completed   | All work finished and verified             |
| failed      | Attempted but could not be completed       |
| skipped     | Deliberately not done (reason in agent_log)|

### CRUD Operations

- **Create**: Copy `tasks/templates/task.json` into new `tasks/{task_id}/task.json`, fill fields, create `notes.md` and `agent_log.md`
- **Read**: Read `task.json` for state, `notes.md` for context, `agent_log.md` for history
- **Update**: Modify `task.json` fields (especially status). Append to `agent_log.md`
- **Delete**: Remove the task directory (rare; prefer status=skipped)

---

## Current Project State

- **Initialized**: 2026-02-27
- **Architecture**: Agent-native (see `docs/reference/agent_native_guide.md`)
- **Rules**: See `CLAUDE.md` in project root

## Recent Activity

- 2026-02-27: Project bootstrapped with agent-native architecture

## Active Tasks

(Updated as tasks are created and completed)

- None currently active
