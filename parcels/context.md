# Parcels — Context

## Purpose

A Parcel (bulto) is an individual physical package within a service or shipment. Each parcel has mandatory weight and volume, and an optional EAN code. Parcels track their own status through the delivery lifecycle.

Parcels are a top-level entity because they need independent tracking — a service with 5 parcels (1/5, 2/5, 3/5, etc.) may have parcels delivered at different times or to different routes.

## Directory Structure

```
parcels/{parcel_id}/
├── parcel.json           # Parcel data (weight, volume, EAN, status)
└── context.md            # Working memory (rarely needed for individual parcels)
```

## Schema: parcel.json

| Field            | Type     | Required | Description                                    |
|------------------|----------|----------|------------------------------------------------|
| id               | string   | yes      | ULID, unique identifier                        |
| service_id       | string   | yes      | Parent service this parcel belongs to           |
| shipment_id      | string   | no       | Assigned shipment (set during processing)       |
| sequence         | string   | yes      | Position in service (e.g. "1/5", "2/5")        |
| weight_kg        | number   | yes      | Weight in kilograms (MANDATORY)                |
| volume_m3        | number   | yes      | Volume in cubic meters (MANDATORY)             |
| ean              | string   | no       | EAN barcode                                    |
| description      | string   | no       | Content description                            |
| status           | string   | yes      | registered, loaded, in_transit, delivered, exception, returned |
| exception_type   | string   | no       | If status=exception: absent, wrong_address, refused, damaged, other |
| exception_notes  | string   | no       | Details about the exception                    |
| created_at       | string   | yes      | ISO-8601 timestamp                             |
| updated_at       | string   | yes      | ISO-8601 timestamp                             |

## CRUD Operations

- **Create**: Create `parcels/{id}/` dir, write `parcel.json`
- **Read**: Read `parcels/{id}/parcel.json`
- **Update**: Modify fields (especially status), update `updated_at`, validate status transition via `config/statuses.json`
- **Delete**: Typically not deleted — set status to `returned` or remove from service

## Capacity Calculation

When assigning parcels to a vehicle/route, agents sum:
- `total_weight = sum(parcel.weight_kg for all parcels in route)`
- `total_volume = sum(parcel.volume_m3 for all parcels in route)`

Then compare against `vehicle.max_weight_kg` and `vehicle.max_volume_m3`.
