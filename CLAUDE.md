# CLAUDE.md — Project Rules and Guidelines

## Project Identity

**mxo-track** is an agent-native last-mile logistics platform. It manages fleets, routes, shipments, and deliveries for B2B customers. The entire system is built on files as the universal interface — agents and humans share the same workspace.

Reference: `docs/reference/agent_native_guide.md`
Domain architecture: `docs/domain/architecture.md`

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
│   ├── domain/
│   │   └── architecture.md               # Domain model and entity relationships
│   └── reference/
│       └── agent_native_guide.md          # Agent-native architecture guide
├── config/
│   ├── roles.json                         # Role definitions and access scopes
│   ├── service_types.json                 # Logistics service types
│   ├── statuses.json                      # Status values and valid transitions
│   ├── vehicle_types.json                 # Vehicle capacity templates
│   └── context.md                         # Config documentation
├── customers/{id}/                        # B2B tenant companies
│   ├── customer.json
│   ├── locations/{loc_id}.json            # Warehouses, depots
│   └── context.md
├── vehicles/{id}/                         # Fleet vehicles
│   ├── vehicle.json
│   ├── positions/{YYYY-MM-DD}.json        # GPS history
│   └── context.md
├── drivers/{id}/                          # Delivery drivers
│   ├── driver.json
│   ├── actions/{action_id}.json           # Idempotency log
│   └── context.md
├── services/{id}/                         # Customer service requests
│   ├── service.json
│   ├── parcels/{parcel_id}.json           # Parcels in this service
│   └── context.md
├── parcels/{id}/                          # Individual parcels (bultos)
│   └── parcel.json
├── shipments/{id}/                        # Individual deliveries
│   ├── shipment.json
│   ├── events/{event_id}.json             # Lifecycle events
│   └── context.md
├── routes/{id}/                           # Delivery routes
│   ├── route.json
│   ├── stops/{stop_id}.json               # Ordered delivery stops
│   ├── optimization_log.md
│   ├── delivery_note.md                   # Generated albarán
│   └── context.md
├── tracking/{TRK-XXXX-XXXX}/             # Public tracking
│   └── tracking.json
├── notifications/{id}/                    # Notification events
│   └── notification.json
├── audit/{id}/                            # Audit trail
│   └── audit.json
├── imports/{id}/                          # CSV import runs
│   ├── import.json
│   ├── source.csv
│   └── errors.json
├── operations/                            # Agent operation prompts
│   ├── optimize_route/prompt.md
│   ├── calculate_eta/prompt.md
│   ├── generate_delivery_note/prompt.md
│   ├── import_csv/prompt.md
│   ├── check_vehicle_capacity/prompt.md
│   ├── calculate_isochrone/prompt.md
│   ├── analyze_driver_productivity/prompt.md
│   ├── billing_summary/prompt.md
│   ├── auto_assign_routes/prompt.md
│   └── context.md
└── tasks/                                 # Task tracking system
    ├── context.md
    ├── templates/task.json
    └── {task_id}/
        ├── task.json
        ├── notes.md
        └── agent_log.md
```

---

## Domain Rules (mxo-track Specific)

### Entity Types

| Entity       | Directory              | Key file        | Description                    |
|--------------|------------------------|-----------------|--------------------------------|
| Customer     | `customers/{id}/`      | customer.json   | B2B tenant company             |
| Vehicle      | `vehicles/{id}/`       | vehicle.json    | Fleet vehicle with capacity    |
| Driver       | `drivers/{id}/`        | driver.json     | Delivery driver                |
| Service      | `services/{id}/`       | service.json    | Customer logistics request     |
| Parcel       | `parcels/{id}/`        | parcel.json     | Individual package (bulto)     |
| Shipment     | `shipments/{id}/`      | shipment.json   | Delivery to a recipient        |
| Route        | `routes/{id}/`         | route.json      | Planned delivery route         |
| Tracking     | `tracking/{token}/`    | tracking.json   | Public shipment tracking       |
| Notification | `notifications/{id}/`  | notification.json | Event notification            |
| Audit        | `audit/{id}/`          | audit.json      | Immutable audit entry          |
| Import       | `imports/{id}/`        | import.json     | CSV import run                 |

### Status Transitions

Always validate status transitions against `config/statuses.json` before changing any entity status. Invalid transitions must be rejected.

### Multi-Tenancy

- Customer role users see only their `customer_id` data
- Driver role users see only their assigned routes
- Agents must filter data by role scope when operating on behalf of a user
- Admin/Operator roles have global access

### Operations (Composable Agent Capabilities)

Operations are prompts, not code. To execute an operation:
1. Read `operations/{name}/prompt.md`
2. Gather inputs as described
3. Execute the logic
4. Write outputs as described
5. Update `operations/{name}/context.md` with lessons learned

Available operations: `optimize_route`, `calculate_eta`, `generate_delivery_note`, `import_csv`, `check_vehicle_capacity`, `calculate_isochrone`, `analyze_driver_productivity`, `billing_summary`, `auto_assign_routes`

### Business Flow

```
Service Request → Parcels → Shipments → Route Planning → Capacity Check → Optimization → Execution → Delivery/Exception → Tracking → Reporting
```

Every step in this flow is an agent operation that reads and writes files.

---

## How to Start Work

1. Read this file completely.
2. Read `tasks/context.md` for current project state.
3. Read `docs/domain/architecture.md` for domain understanding.
4. Check for any `in_progress` tasks that need resuming.
5. Create or update a task for the work you are about to do.
6. Do the work in atomic increments, committing and pushing after each.
7. Update task status when done.
