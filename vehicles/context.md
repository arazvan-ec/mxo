# Vehicles — Entity Context

## Overview

Fleet vehicles used for deliveries. Each vehicle has capacity constraints (weight in kg, volume in m3) that determine how many packages can be loaded. Routes are validated against vehicle capacity before starting.

## Schema

See `schemas/vehicle.schema.json`

## Directory Structure

```
vehicles/
├── context.md          # This file
└── {vehicle_id}/
    └── vehicle.json    # Vehicle data
```

## Key Fields

- **capacity_kg**: Maximum weight in kilograms (required, used for route validation)
- **capacity_m3**: Maximum volume in cubic meters (required, used for route validation)
- **traccar_device_id**: Links to Traccar GPS tracking server
- **status**: available | in_route | maintenance | inactive

## Capacity Validation

Before a route starts, total weight and volume of all packages must be <= vehicle capacity. See `tools/routes/validate_capacity.sh`.

## Current State

No vehicles created yet.
