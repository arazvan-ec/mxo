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
- 2026-02-27: mxo-track domain model fully implemented (task 002)
  - 13 entity types with schemas and CRUD documentation
  - 9 agent operations defined as composable prompts
  - Config layer with roles, statuses, service types, vehicle types
  - CLAUDE.md updated with domain-specific rules
- 2026-02-28: API backend implemented (task 003)
  - Hono + TypeScript REST API over file-based storage
  - Generic CRUD engine for all 11 entity types
  - Auth middleware with role-based access
  - Multi-tenancy filtering by customer_id/driver_id
  - Operations API for listing and reading agent prompts
  - Config API for platform configuration

## Completed Tasks

- `001_bootstrap_project` — Project initialization
- `002_mxo_track_domain_model` — Full domain model for logistics platform
- `003_api_backend` — REST API over file-based storage (Hono + TypeScript)

## Active Tasks

- None currently active

## Next Steps

- Create sample data (demo customer, vehicles, drivers, shipments)
- Execute end-to-end flow: CSV import → route creation → optimization → delivery
- Refine operation prompts based on first real executions
- Add pricing config for billing operations
- Add frontend (React/Next.js) consuming the API
