# Shipments — Context

## Purpose

A Shipment represents a single delivery to a recipient. Shipments are generated from Services and assigned to Routes. Each shipment has a public tracking token (TRK-XXXX-XXXX) for end-recipient visibility.

## Directory Structure

```
shipments/{shipment_id}/
├── shipment.json         # Shipment data (reference, recipient, address, tracking)
├── events/               # Lifecycle events
│   └── {event_id}.json   # Individual event (status change with timestamp)
└── context.md            # Working memory
```

## Schema: shipment.json

| Field              | Type     | Required | Description                                  |
|--------------------|----------|----------|----------------------------------------------|
| id                 | string   | yes      | ULID, unique identifier                      |
| customer_id        | string   | yes      | Customer who owns this shipment              |
| service_id         | string   | no       | Parent service that generated this shipment  |
| reference          | string   | yes      | Unique reference code (customer-facing)      |
| tracking_token     | string   | yes      | Public token TRK-XXXX-XXXX for tracking      |
| status             | string   | yes      | created, picked_up, in_transit, out_for_delivery, delivered, exception |
| recipient_name     | string   | yes      | Name of the delivery recipient               |
| recipient_phone    | string   | no       | Recipient phone                              |
| recipient_email    | string   | no       | Recipient email                              |
| address            | string   | yes      | Full delivery address                        |
| latitude           | number   | no       | GPS latitude of delivery address             |
| longitude          | number   | no       | GPS longitude of delivery address            |
| parcel_ids         | array    | no       | IDs of parcels in this shipment              |
| total_weight_kg    | number   | no       | Sum of parcel weights                        |
| total_volume_m3    | number   | no       | Sum of parcel volumes                        |
| route_id           | string   | no       | Assigned route                               |
| route_stop_id      | string   | no       | Assigned stop within route                   |
| exception_type     | string   | no       | If exception: absent, wrong_address, refused, damaged, other |
| exception_notes    | string   | no       | Details about exception                      |
| pod                | object   | no       | Proof of delivery (set on successful delivery) |
| estimated_delivery_date | string | no    | Proposed date                                |
| delivered_at       | string   | no       | Actual delivery timestamp                    |
| created_at         | string   | yes      | ISO-8601 timestamp                           |
| updated_at         | string   | yes      | ISO-8601 timestamp                           |
| notes              | string   | no       | Special delivery instructions                |

### pod Object (Proof of Delivery)

| Field                | Type    | Description                              |
|----------------------|---------|------------------------------------------|
| signed_by_name       | string  | Name of person who signed               |
| recipient_id_encoded | string  | Encoded ID of the recipient             |
| confirmed_by_driver  | boolean | Driver explicitly confirmed delivery    |
| timestamp            | string  | ISO-8601 when POD was captured          |
| ip_address           | string  | IP of device that captured POD          |
| user_agent           | string  | Device user-agent string                |

### Tracking Token Format

Format: `TRK-XXXX-XXXX` where X is alphanumeric uppercase.
Generated at shipment creation. Used for public tracking without authentication.

## Shipment Events

Events record the lifecycle of a shipment. Stored in `events/` subdirectory.

```json
{
  "id": "ulid",
  "shipment_id": "...",
  "event_type": "created|picked_up|in_transit|out_for_delivery|delivered|exception",
  "timestamp": "ISO-8601",
  "location": { "latitude": 40.0, "longitude": -3.0 },
  "actor_id": "driver/operator who triggered this",
  "notes": ""
}
```

## CRUD Operations

- **Create**: Create `shipments/{id}/` dir, write `shipment.json`, generate tracking token, create initial event
- **Read**: Read `shipments/{id}/shipment.json`, read events from `events/`
- **Update**: Modify fields, create new event, update `updated_at`, validate status transition
- **Delete**: Set status to `exception` with type and notes (soft delete)

## Public Tracking

The tracking token maps to a tracking entity at `tracking/{TRK-XXXX-XXXX}/tracking.json` which contains an anonymized, public-safe view of the shipment.
