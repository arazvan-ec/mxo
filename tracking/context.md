# Tracking — Context

## Purpose

Public tracking entries provide an anonymized, unauthenticated view of a shipment's progress. Each tracking entry is keyed by the shipment's TRK-XXXX-XXXX token, allowing end recipients to track their delivery without logging in.

## Directory Structure

```
tracking/{tracking_token}/
└── tracking.json         # Public-safe shipment view
```

## Schema: tracking.json

| Field              | Type     | Required | Description                                  |
|--------------------|----------|----------|----------------------------------------------|
| token              | string   | yes      | TRK-XXXX-XXXX format                         |
| shipment_id        | string   | yes      | Internal shipment reference                  |
| status             | string   | yes      | Current shipment status                      |
| recipient_name     | string   | yes      | Recipient (may be partially masked)          |
| estimated_delivery | string   | no       | Estimated delivery date/time                 |
| timeline           | array    | yes      | List of public-facing events                 |
| vehicle_position   | object   | no       | Anonymized position (~500m radius)           |
| updated_at         | string   | yes      | Last update timestamp                        |

### timeline Entry

| Field     | Type   | Description                    |
|-----------|--------|--------------------------------|
| event     | string | Event label (e.g. "En reparto")|
| timestamp | string | ISO-8601                        |
| detail    | string | Optional detail text           |

### vehicle_position Object (Anonymized)

| Field     | Type   | Description                        |
|-----------|--------|------------------------------------|
| latitude  | number | Approximate (rounded to ~500m)     |
| longitude | number | Approximate (rounded to ~500m)     |
| timestamp | string | When position was captured          |

## CRUD Operations

- **Create**: Created automatically when a shipment is created (agent operation)
- **Read**: Read `tracking/{token}/tracking.json`
- **Update**: Updated whenever shipment status changes (agent syncs from shipment events)
- **Delete**: Removed when shipment is completed + retention period expires

## Privacy

- Vehicle position is anonymized: coordinates rounded to ~500m resolution
- No driver information exposed
- No internal IDs exposed (only tracking token)
