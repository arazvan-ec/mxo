# Drivers — Entity Context

## Overview

Delivery drivers execute routes. They can be assigned to a specific customer or be general. Each driver has a performance history tracked over time.

## Schema

See `schemas/driver.schema.json`

## Directory Structure

```
drivers/
├── context.md         # This file
└── {driver_id}/
    ├── driver.json    # Driver data
    └── performance/   # Performance metrics (created by reporting tools)
```

## Key Fields

- **customer_id**: Optional association with a specific customer
- **vehicle_id**: Currently assigned vehicle
- **status**: active | inactive | on_route

## Current State

No drivers created yet.
