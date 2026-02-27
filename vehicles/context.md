# Vehicles — Context

## Purpose

Vehicles are the fleet units that execute deliveries. Each vehicle has a type (determining capacity), GPS tracking capability, and assignment to routes.

## Directory Structure

```
vehicles/{vehicle_id}/
├── vehicle.json          # Vehicle data (plate, type, capacity, GPS device)
├── positions/            # GPS position history (one file per day)
│   └── {YYYY-MM-DD}.json
└── context.md            # Working memory for this vehicle
```

## Schema: vehicle.json

| Field              | Type     | Required | Description                                  |
|--------------------|----------|----------|----------------------------------------------|
| id                 | string   | yes      | ULID, unique identifier                      |
| name               | string   | yes      | Display name (e.g. "Van-01")                 |
| plate              | string   | yes      | License plate number                         |
| vehicle_type       | string   | yes      | Key from config/vehicle_types.json           |
| max_weight_kg      | number   | yes      | Max load weight (override or from type)      |
| max_volume_m3      | number   | yes      | Max load volume (override or from type)      |
| max_parcels        | number   | no       | Max parcel count (optional limit)            |
| traccar_device_id  | string   | no       | Traccar GPS device identifier                |
| current_driver_id  | string   | no       | Currently assigned driver                    |
| status             | string   | yes      | available, in_route, maintenance, inactive   |
| last_position      | object   | no       | Latest known GPS position                    |
| created_at         | string   | yes      | ISO-8601 timestamp                           |
| updated_at         | string   | yes      | ISO-8601 timestamp                           |
| notes              | string   | no       | Free-text notes                              |

### last_position Object

| Field     | Type   | Description                  |
|-----------|--------|------------------------------|
| latitude  | number | GPS latitude                 |
| longitude | number | GPS longitude                |
| speed_kmh | number | Speed in km/h                |
| heading   | number | Heading in degrees (0-360)   |
| timestamp | string | ISO-8601 when position taken |

## Position History

Daily files at `vehicles/{id}/positions/{YYYY-MM-DD}.json`:

```json
{
  "date": "2026-02-27",
  "vehicle_id": "...",
  "positions": [
    {"latitude": 40.4168, "longitude": -3.7038, "speed_kmh": 35, "heading": 90, "timestamp": "2026-02-27T08:30:00Z"}
  ]
}
```

## CRUD Operations

- **Create**: Create `vehicles/{id}/` directory, write `vehicle.json` from template, populate capacity from `config/vehicle_types.json`
- **Read**: Read `vehicles/{id}/vehicle.json`
- **Update**: Modify fields in `vehicle.json`, update `updated_at`
- **Delete**: Set status to `inactive` (soft delete)

## Capacity Validation

Before assigning parcels to a vehicle, agents must:
1. Read `vehicle.json` for `max_weight_kg` and `max_volume_m3`
2. Sum all assigned parcels' weight and volume
3. Verify totals don't exceed vehicle limits
