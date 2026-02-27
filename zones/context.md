# Zones (RGU / Isochrones) — Entity Context

## Overview

Zones represent geographic areas for delivery organization. An isochrone (iso = equal, chrone = time) defines the area reachable within a given time from a center point. Zones help organize routes by geographic proximity and measure transporter productivity per area.

## What is an RGU?

An RGU (Ruta Geográfica Unificada) is a standardized geographic route unit — a zone defined by an isochrone from a depot. It represents the area a vehicle can serve within a time budget.

## Schema

Zones are defined by:
- **center_lat/center_lng**: Center point (typically a depot/warehouse)
- **radius_minutes**: Time radius defining the isochrone
- **radius_km**: Approximate distance radius (calculated from avg speed)
- **name**: Zone display name (e.g., "Madrid Centro 30min")

## Directory Structure

```
zones/
├── context.md           # This file
└── {zone_id}/
    └── zone.json        # Zone data
```

## Current State

No zones created yet.
