# Routes — Context

## Purpose

A Route is a planned delivery sequence: a driver, a vehicle, an origin location, and an ordered list of stops. Routes go through a lifecycle (planned → active → done) and support optimization, ETA calculation, capacity validation, and delivery note generation.

## Directory Structure

```
routes/{route_id}/
├── route.json              # Route metadata (status, driver, vehicle, customer, origin)
├── stops/                  # Ordered delivery stops
│   └── {stop_id}.json      # Individual stop (address, shipment, sequence, status, POD)
├── optimization_log.md     # History of optimization runs
├── delivery_note.md        # Generated albarán (delivery note)
└── context.md              # Working memory for this route
```

## Schema: route.json

| Field              | Type     | Required | Description                                  |
|--------------------|----------|----------|----------------------------------------------|
| id                 | string   | yes      | ULID, unique identifier                      |
| name               | string   | yes      | Display name (e.g. "Ruta Madrid Centro AM")  |
| customer_id        | string   | yes      | Customer who owns this route                 |
| driver_id          | string   | no       | Assigned driver                              |
| vehicle_id         | string   | no       | Assigned vehicle                             |
| origin_location_id | string   | no       | Starting point (customer's warehouse/depot)  |
| origin_address     | string   | no       | Origin address (for display)                 |
| origin_latitude    | number   | no       | Origin GPS latitude                          |
| origin_longitude   | number   | no       | Origin GPS longitude                         |
| status             | string   | yes      | planned, active, done, cancelled             |
| total_stops        | number   | no       | Count of stops                               |
| completed_stops    | number   | no       | Count of delivered/exception stops           |
| total_distance_km  | number   | no       | Estimated total route distance               |
| optimized_distance_km | number | no      | Distance after optimization                  |
| total_weight_kg    | number   | no       | Sum of all parcels in route                  |
| total_volume_m3    | number   | no       | Sum of all parcels in route                  |
| vehicle_utilization| object   | no       | Weight and volume utilization percentages    |
| planned_date       | string   | no       | Date the route is planned for                |
| started_at         | string   | no       | When driver started the route                |
| completed_at       | string   | no       | When driver finished the route               |
| created_at         | string   | yes      | ISO-8601 timestamp                           |
| updated_at         | string   | yes      | ISO-8601 timestamp                           |
| notes              | string   | no       | Free-text notes                              |

### vehicle_utilization Object

| Field         | Type   | Description                        |
|---------------|--------|------------------------------------|
| weight_percent| number | (total_weight / max_weight) * 100  |
| volume_percent| number | (total_volume / max_volume) * 100  |
| fits          | boolean| Both percentages <= 100            |

## Schema: stop.json (in stops/ directory)

| Field              | Type     | Required | Description                                  |
|--------------------|----------|----------|----------------------------------------------|
| id                 | string   | yes      | ULID, unique identifier                      |
| route_id           | string   | yes      | Parent route                                 |
| shipment_id        | string   | yes      | Shipment being delivered at this stop        |
| sequence           | number   | yes      | Order in route (1, 2, 3...)                  |
| address            | string   | yes      | Delivery address                             |
| latitude           | number   | no       | GPS latitude                                 |
| longitude          | number   | no       | GPS longitude                                |
| recipient_name     | string   | yes      | Who to deliver to                            |
| status             | string   | yes      | pending, delivered, exception, skipped       |
| delivery_window    | object   | no       | Time window for this stop                    |
| eta                | string   | no       | Estimated time of arrival (ISO-8601)         |
| arrived_at         | string   | no       | Actual arrival time                          |
| completed_at       | string   | no       | When stop was completed                      |
| pod                | object   | no       | Proof of delivery (same as shipment POD)     |
| exception_type     | string   | no       | If exception: absent, wrong_address, etc.    |
| exception_notes    | string   | no       | Exception details                            |
| distance_from_prev_km | number | no      | Distance from previous stop                  |
| time_from_prev_min | number   | no       | Estimated time from previous stop            |

### delivery_window Object

| Field | Type   | Description              |
|-------|--------|--------------------------|
| from  | string | Window start (HH:MM)     |
| to    | string | Window end (HH:MM)       |

## Route Lifecycle

```
1. PLAN    → Create route, add stops, assign driver + vehicle
2. VALIDATE → Check vehicle capacity (weight + volume vs limits)
3. OPTIMIZE → Reorder stops for minimum distance (agent operation)
4. GENERATE → Create delivery note (albarán) with all stops and parcels
5. START   → Driver begins route (planned → active)
6. EXECUTE → Driver visits stops in order, confirms delivery or reports exception
7. CLOSE   → Driver finishes (active → done)
```

## Optimization History

`optimization_log.md` records each optimization run:
```
## 2026-02-27T10:00:00Z
**Algorithm**: farthest_first
**Before**: 45.2 km total distance
**After**: 32.1 km total distance
**Saved**: 13.1 km (29%)
**New order**: [stop_3, stop_1, stop_5, stop_2, stop_4]
```

## Delivery Note (Albarán)

`delivery_note.md` is a human-readable document generated before route execution:
- Route summary (driver, vehicle, date, origin)
- Stop list with sequence, address, recipient, parcels
- Total weight and volume
- Vehicle capacity check

## CRUD Operations

- **Create**: Create `routes/{id}/` dir, write `route.json`, create `stops/` dir
- **Read**: Read `routes/{id}/route.json`, list stops from `stops/`
- **Update**: Modify fields, update `updated_at`, validate status transition
- **Delete**: Set status to `cancelled` (soft delete)

## Adding Stops

1. Create `stops/{stop_id}.json` from template
2. Update `route.json` total_stops count
3. Recalculate total_weight_kg and total_volume_m3 from all stops' parcels
4. Recalculate vehicle_utilization

## Pre-Route Validation

Before a route can move from `planned` to `active`:
1. Must have a driver assigned
2. Must have a vehicle assigned
3. Vehicle capacity must be sufficient (fits = true)
4. All stops must have valid addresses
