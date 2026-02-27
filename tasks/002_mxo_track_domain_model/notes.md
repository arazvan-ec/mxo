# Task 002: mxo-track Agent-Native Domain Model

## Objective

Design and implement the complete mxo-track logistics SaaS platform following agent-native architecture. The system manages last-mile delivery: fleets, routes, shipments, tracking, and proof of delivery.

## Key Decision: Agent-Native, Not Traditional SaaS

This is NOT a PHP/Symfony application. The entire system is modeled as:

- **Files as data** — every entity is a directory with JSON + Markdown
- **Agents as operators** — agents read files, compose operations, and write results
- **Prompts as features** — new capabilities emerge from prompt descriptions, not code
- **Humans and agents share the same workspace** — no separate APIs needed

## Domain Entities (File-Based)

### Core Entities
- `customers/{id}/` — Client companies (B2B tenants)
- `vehicles/{id}/` — Fleet vehicles with capacity config
- `drivers/{id}/` — Delivery drivers
- `shipments/{id}/` — Individual packages/deliveries
- `routes/{id}/` — Planned delivery routes with stops
- `services/{id}/` — Service requests (what triggers routes)

### Supporting Entities
- `locations/{id}/` — Warehouses, depots, customer sites
- `parcels/{id}/` — Individual parcels within a shipment (weight, volume, EAN)
- `tracking/{token}/` — Public tracking by token
- `notifications/{id}/` — Notification events
- `audit/{id}/` — Audit trail entries
- `imports/{id}/` — CSV import runs

### Configuration
- `config/service_types.json` — Service type definitions
- `config/vehicle_types.json` — Vehicle type capacity templates
- `config/statuses.json` — All valid status transitions
- `config/roles.json` — Role definitions and permissions

### Agent Capabilities (Prompts, not code)
- `operations/` — Directory of composable operation prompts
  - `operations/optimize_route/` — Route optimization
  - `operations/calculate_eta/` — ETA calculation
  - `operations/generate_delivery_note/` — Albarán generation
  - `operations/import_csv/` — CSV processing
  - `operations/assign_routes/` — Auto-assign shipments to routes
  - `operations/check_vehicle_capacity/` — Validate load fits vehicle
  - `operations/calculate_isochrone/` — RGU/isochrone calculation
  - `operations/analyze_driver_productivity/` — Driver performance analysis
  - `operations/billing_summary/` — Generate billing for customer

## Micro-Plan (each step = 1 commit + push)

1. Domain architecture doc (entity map + relationships)
2. Config schemas (service types, roles, statuses, vehicle types)
3. Customer entity schema + context.md
4. Vehicle entity schema + context.md
5. Driver entity schema + context.md
6. Location entity schema + context.md
7. Shipment entity schema + context.md
8. Parcel entity schema + context.md (weight, volume, EAN per bulto)
9. Service entity schema + context.md (service request from client)
10. Route entity schema + context.md (with stops as embedded data)
11. Tracking entity schema + context.md
12. Notification entity schema + context.md
13. Audit entity schema + context.md
14. Import entity schema + context.md
15. Operations: route optimization prompt
16. Operations: ETA calculation prompt
17. Operations: delivery note (albarán) generation prompt
18. Operations: CSV import prompt
19. Operations: vehicle capacity check prompt
20. Operations: isochrone/RGU calculation prompt
21. Operations: driver productivity analysis prompt
22. Operations: billing summary prompt
23. Operations: auto-assign routes prompt
24. Update CLAUDE.md with mxo-track domain rules
25. Update tasks/context.md with completion
