# Services — Entity Context

## Overview

Service types define what kind of delivery operation is performed. Each shipment is associated with a service type that determines requirements (pickup, return, signature, package fields).

## Schema

See `schemas/service.schema.json`

## Directory Structure

```
services/
├── context.md            # This file
└── {service_type}/
    └── service.json      # Service type configuration
```

## Predefined Service Types

| Type | Name | Pickup | Return | Description |
|------|------|--------|--------|-------------|
| entrega | Paquetería Entrega | No | No | Standard delivery from origin to destination |
| entrega_recogida | Paquetería Entrega y Recogida | Yes | No | Deliver and pick up items at destination |
| devolucion | Paquetería Devolución | No | Yes | Return shipment from destination to origin |

## Package Requirements

All service types require weight_kg and volume_m3 per package. EAN and description are optional but recommended.

## Current State

No services created yet. Will be seeded with predefined types.
