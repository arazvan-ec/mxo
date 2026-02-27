# Routes — Entity Context

## Overview

A route is a planned sequence of delivery stops assigned to a driver and vehicle. Routes go through a lifecycle: planned → active → done/cancelled. Before starting, capacity is validated (packages must fit in the vehicle).

## Schemas

- `schemas/route.schema.json` — Route entity
- `schemas/route_stop.schema.json` — Individual stop within a route

## Directory Structure

```
routes/
├── context.md                    # This file
└── {route_id}/
    ├── route.json                # Route data (status, totals, driver, vehicle)
    ├── stops/
    │   └── {stop_id}/
    │       └── stop.json         # Stop data (sequence, status, POD, exception)
    ├── optimization_log.md       # History of optimization runs
    └── execution_log.md          # Execution events log
```

## Route Lifecycle

```
PLANNED ──→ ACTIVE ──→ DONE
   │           │
   └──→ CANCELLED ←──┘
```

- **PLANNED**: Route created, stops added, can be optimized and validated
- **ACTIVE**: Driver has started, deliveries in progress
- **DONE**: All stops processed (delivered/exception/skipped)
- **CANCELLED**: Route cancelled before or during execution

## Stop Lifecycle

```
PENDING ──→ ARRIVED ──→ DELIVERED (with POD)
                  │
                  ├──→ EXCEPTION (with reason)
                  │
                  └──→ SKIPPED
```

## Capacity Validation

Before PLANNED → ACTIVE:
- Sum all package weights across all stops
- Sum all package volumes across all stops
- Compare against vehicle capacity_kg and capacity_m3
- FAIL if either exceeds vehicle capacity

## Optimization

The optimizer reorders stops to minimize total distance:
1. Start from route origin
2. Farthest-first strategy: begin from the farthest point
3. Nearest-neighbor within the return path
4. Log distance before/after in optimization_log.md

## Current State

No routes created yet.
