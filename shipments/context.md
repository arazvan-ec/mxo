# Shipments — Entity Context

## Overview

A shipment is a delivery from a customer to a recipient. Each shipment contains one or more packages (bultos) with mandatory weight and volume. Shipments have a lifecycle tracked via events and a public tracking token (TRK-XXXX-XXXX).

## Schema

See `schemas/shipment.schema.json`

## Directory Structure

```
shipments/
├── context.md             # This file
└── {shipment_id}/
    ├── shipment.json      # Shipment data including packages[]
    └── events.json        # Lifecycle events array
```

## Package (Bulto) Requirements

Each package must have:
- **weight_kg** (mandatory): Weight in kilograms
- **volume_m3** (mandatory): Volume in cubic meters
- **ean** (optional): EAN barcode
- **description** (optional): Package description
- **status**: pending → cargado → en_ruta → entregado | ausencia | devuelto

Shipment numbering: package 1/5, 2/5, etc. based on total_packages.

## Lifecycle Events (Flexible)

Events are stored in `events.json` as an array. Common event types:
- CREATED, PICKED_UP, IN_TRANSIT, OUT_FOR_DELIVERY, DELIVERED, EXCEPTION
- Additional event types can be created as needed (agent-native flexibility)

## Tracking

Each shipment gets a unique token: `TRK-XXXX-XXXX` (uppercase alphanumeric).
Public tracking shows timeline of events + approximate vehicle position.

## Current State

No shipments created yet.
