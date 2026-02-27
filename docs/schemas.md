# mxo-track — Entity Relationship Map

## Entities

```
Customer ─────────────────────────────────────────────
  │
  ├── has many → Shipment (customer_id)
  │                  │
  │                  ├── has many → Package (inline)
  │                  └── has many → Event (events.json)
  │
  ├── has many → Route (customer_id)
  │                  │
  │                  └── has many → RouteStop
  │                       └── links to → Shipment
  │
  └── has many → ImportRun (customer_id)

Vehicle ──────────────────────────────────────────────
  └── assigned to → Route (vehicle_id)
       └── capacity validates against → Route totals

Driver ───────────────────────────────────────────────
  ├── optionally → Customer (customer_id)
  └── assigned to → Route (driver_id)

Service ──────────────────────────────────────────────
  └── configures → Shipment (service_type)
```

## Entity Directories

| Entity | Path | Key File |
|--------|------|----------|
| Customer | `customers/{id}/` | `customer.json` |
| Vehicle | `vehicles/{id}/` | `vehicle.json` |
| Driver | `drivers/{id}/` | `driver.json` |
| Service | `services/{type}/` | `service.json` |
| Shipment | `shipments/{id}/` | `shipment.json`, `events.json` |
| Route | `routes/{id}/` | `route.json` |
| RouteStop | `routes/{id}/stops/{stop_id}/` | `stop.json` |
| ImportRun | `imports/{id}/` | `import.json` |

## Schemas

All JSON Schemas in `schemas/`:
- `customer.schema.json`
- `vehicle.schema.json`
- `driver.schema.json`
- `service.schema.json`
- `shipment.schema.json`
- `route.schema.json`
- `route_stop.schema.json`
- `import_run.schema.json`
