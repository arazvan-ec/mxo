# Drivers — Context

## Purpose

Drivers are the people who execute delivery routes. They are assigned to vehicles and routes, confirm deliveries with proof of delivery (POD), and report exceptions.

## Directory Structure

```
drivers/{driver_id}/
├── driver.json           # Driver data (name, license, contact, assigned vehicle)
├── actions/              # Idempotency log (prevents duplicate actions)
│   └── {action_id}.json
└── context.md            # Working memory for this driver
```

## Schema: driver.json

| Field              | Type     | Required | Description                              |
|--------------------|----------|----------|------------------------------------------|
| id                 | string   | yes      | ULID, unique identifier                  |
| name               | string   | yes      | Full name                                |
| email              | string   | yes      | Email address                            |
| phone              | string   | no       | Phone number                             |
| license_number     | string   | no       | Driving license number                   |
| assigned_vehicle_id| string   | no       | Currently assigned vehicle               |
| customer_id        | string   | no       | If driver belongs to a specific customer |
| status             | string   | yes      | active, on_route, off_duty, inactive     |
| productivity_stats | object   | no       | Aggregated performance metrics           |
| created_at         | string   | yes      | ISO-8601 timestamp                       |
| updated_at         | string   | yes      | ISO-8601 timestamp                       |
| notes              | string   | no       | Free-text notes                          |

### productivity_stats Object

| Field                | Type   | Description                              |
|----------------------|--------|------------------------------------------|
| total_deliveries     | number | All-time delivered count                 |
| total_exceptions     | number | All-time exception count                 |
| success_rate         | number | Percentage (0-100)                       |
| avg_delivery_time_min| number | Average minutes per delivery             |
| last_updated         | string | ISO-8601 when stats were last calculated |

## Driver Actions (Idempotency)

Each action the driver takes is recorded to prevent duplicates:

```json
{
  "action_id": "ulid",
  "driver_id": "...",
  "route_id": "...",
  "stop_id": "...",
  "action_type": "deliver|exception|start_route|end_route",
  "timestamp": "ISO-8601",
  "idempotency_key": "unique-key-from-client"
}
```

Before processing a driver action, agents check if the `idempotency_key` already exists.

## CRUD Operations

- **Create**: Create `drivers/{id}/` directory, write `driver.json`, create `actions/` dir
- **Read**: Read `drivers/{id}/driver.json`
- **Update**: Modify fields, update `updated_at`
- **Delete**: Set status to `inactive` (soft delete)
