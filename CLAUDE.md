# CLAUDE.md — Project Rules and Guidelines

## Project Identity

MXO follows **agent-native architecture** principles.
Reference: `docs/reference/agent_native_guide.md`

---

## Mandatory Rules

Every response, every file created, every architectural decision MUST comply with these rules. No exceptions.

### Rule 1: Agent-Native Principles

All development must follow the five core principles:

1. **Parity** — Whatever users accomplish through UI, agents must achieve via tools. Never build a capability accessible through only one interface.
2. **Granularity** — Tools and functions must be atomic primitives. Do not bundle decision logic. If a function does two conceptual things, split it.
3. **Composability** — New features should emerge from prompt descriptions of outcomes, not code changes. Ask: "To change this behavior, do I edit a prompt or refactor code?" Prefer prompts.
4. **Emergent Capability** — Design so agents can accomplish tasks not explicitly planned. Do not over-constrain inputs with defensive enums or rigid schemas when flexibility serves better.
5. **Improvement Over Time** — Persist context across sessions. Use `context.md` files. Refine prompts based on what works. Accumulate knowledge in files.

### Rule 2: Files as Universal Interface

- Use the filesystem for data storage wherever possible. No opaque databases unless there is a demonstrated need for query performance at scale.
- Entity-scoped directory structure: `{entity_type}/{entity_id}/`
- Naming conventions:
  - Directories and files: lowercase with underscores
  - Entity data: `{entity}.json`
  - Human-readable content: `{content_type}.md`
  - Agent reasoning/logs: `agent_log.md`
  - Portable working memory: `context.md`
- JSON for structured data, Markdown for human-readable content.
- Every entity directory contains its own data, metadata, and related materials.

### Rule 3: CRUD Completeness

Every entity type MUST support all four operations: create, read, update, delete. When introducing a new entity type, define all four before considering it complete.

### Rule 4: Task Tracking

All work is tracked in the file-based task system under `tasks/`.

- Before starting work, create or update a task.
- Tasks use entity-scoped directories: `tasks/{task_id}/task.json`
- Valid states: `pending`, `in_progress`, `completed`, `failed`, `skipped`
- Update task status as work progresses.
- Never leave a task `in_progress` at end of session without explanation in `agent_log.md`.
- Read `tasks/context.md` at session start.

### Rule 5: Atomic Commits and Pushes

- Every commit must be atomic: one logical change per commit.
- Commit message format:
  ```
  <type>: <short description>
  ```
  Types: `init`, `feat`, `fix`, `refactor`, `docs`, `task`, `chore`
- Push immediately after every commit. `git push` follows every `git commit`.
- Never batch unrelated changes into one commit.
- When in doubt, make the commit smaller.

### Rule 6: Micro-Plans (Divide and Deliver)

- Never create large monolithic plans. Break ALL work into the smallest deliverable steps possible.
- Each step must end with a commit + push. Progress is saved constantly.
- If a step feels too big, split it further.
- This prevents context loss, ensures incremental delivery, and makes rollback easy.
- Think: "If I lose context right now, can the next session pick up from the last commit?"

### Rule 7: Progressive Disclosure

- Start simple. Add complexity only when needed.
- Build the minimal version first, then iterate.
- Do not over-engineer.

### Rule 8: Partial Completion Tracking

- Multi-step operations must track progress at task granularity.
- Status fields: `pending`, `in_progress`, `completed`, `failed`, `skipped`.
- If a session ends mid-work, the next session must be able to pick up by reading task state.

---

## Project Structure

```
mxo/
├── CLAUDE.md                              # This file (project rules)
├── docs/
│   └── reference/                         # Reference documentation
│       └── agent_native_guide.md          # Agent-native architecture guide
├── tasks/
│   ├── context.md                         # Task system docs + working memory
│   ├── templates/
│   │   └── task.json                      # Template for new tasks
│   └── {task_id}/                         # Entity-scoped task directories
│       ├── task.json                      # Task state (source of truth)
│       ├── notes.md                       # Human-readable description
│       └── agent_log.md                   # Agent reasoning and decisions
└── (future entity types as directories)
```

---

## How to Start Work

1. Read this file completely.
2. Read `tasks/context.md` for current project state.
3. Check for any `in_progress` tasks that need resuming.
4. Create or update a task for the work you are about to do.
5. Do the work in atomic increments, committing and pushing after each.
6. Update task status when done.
