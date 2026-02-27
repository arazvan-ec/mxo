# Task 003: API-Only Backend

## Objective

Build a REST API that sits on top of the file-based data layer. The API is the parity layer — whatever agents do by reading/writing files, the API exposes as HTTP endpoints.

## Design Decisions

- **Hono** — Lightweight, fast, TypeScript-native web framework. Runs on Node.js.
- **File-based storage** — No database. API reads/writes the same JSON files in entity directories.
- **Generic CRUD engine** — One function handles CRUD for all entity types. No per-entity boilerplate.
- **ULID for IDs** — Sortable, unique, URL-safe identifiers.
- **Status validation** — All status changes validated against `config/statuses.json`.

## API Structure

```
api/
├── package.json
├── tsconfig.json
├── src/
│   ├── index.ts              # Entry point, Hono app
│   ├── storage/
│   │   └── file_store.ts     # Generic file-based CRUD engine
│   ├── middleware/
│   │   ├── auth.ts           # Authentication + role extraction
│   │   └── tenant.ts         # Multi-tenancy filtering
│   ├── routes/
│   │   ├── customers.ts
│   │   ├── vehicles.ts
│   │   ├── drivers.ts
│   │   ├── services.ts
│   │   ├── parcels.ts
│   │   ├── shipments.ts
│   │   ├── routes.ts
│   │   ├── tracking.ts
│   │   ├── notifications.ts
│   │   ├── imports.ts
│   │   └── operations.ts     # Trigger agent operations
│   └── lib/
│       ├── ulid.ts           # ULID generation
│       └── status.ts         # Status transition validation
```

## Endpoints Pattern (per entity)

```
GET    /api/{entity}           # List all (filtered by role)
GET    /api/{entity}/{id}      # Get one
POST   /api/{entity}           # Create
PATCH  /api/{entity}/{id}      # Update
DELETE /api/{entity}/{id}      # Soft delete (set status)
```

## Micro-Plan

1. Init Node.js project with Hono + TypeScript
2. Build file_store.ts — generic CRUD over JSON files
3. Build ULID + status validation helpers
4. Build auth + tenant middleware
5. Implement customer routes
6. Implement vehicle routes
7. Implement driver routes
8. Implement service + parcel routes
9. Implement shipment routes
10. Implement route + stop routes
11. Implement tracking routes
12. Implement notification routes
13. Implement import routes
14. Implement operations trigger routes
15. Add server entry point and run script
16. Update CLAUDE.md
