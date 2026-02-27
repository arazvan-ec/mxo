# Services — Context

## Purpose

A Service is a request from a customer to perform logistics work. It is the entry point of the business flow — before shipments, before routes. A customer initiates a service via API, CSV upload, phone call, SMS, or email.

## Directory Structure

```
services/{service_id}/
├── service.json          # Service request data
├── parcels/              # Individual parcels (bultos) in this service
│   └── {parcel_id}.json
└── context.md            # Working memory for this service
```

## Schema: service.json

| Field              | Type     | Required | Description                                  |
|--------------------|----------|----------|----------------------------------------------|
| id                 | string   | yes      | ULID, unique identifier                      |
| customer_id        | string   | yes      | Customer who requested this service          |
| service_type       | string   | yes      | Key from config/service_types.json           |
| status             | string   | yes      | draft, confirmed, processing, completed, cancelled |
| reference          | string   | no       | Customer's own reference number              |
| origin_location_id | string   | no       | Pickup location (from customer's locations)  |
| destination_address| string   | yes      | Delivery address                             |
| destination_latitude | number | no       | GPS latitude of destination                  |
| destination_longitude| number | no       | GPS longitude of destination                 |
| recipient_name     | string   | yes      | Name of the recipient                        |
| recipient_phone    | string   | no       | Recipient phone for notifications            |
| recipient_email    | string   | no       | Recipient email for notifications            |
| total_parcels      | number   | yes      | Number of parcels (bultos) in this service   |
| total_weight_kg    | number   | no       | Sum of all parcel weights                    |
| total_volume_m3    | number   | no       | Sum of all parcel volumes                    |
| estimated_delivery_date | string | no    | Proposed delivery date (ISO-8601 date)       |
| delivery_window    | object   | no       | Preferred delivery time window               |
| shipment_ids       | array    | no       | Generated shipment IDs from this service     |
| created_at         | string   | yes      | ISO-8601 timestamp                           |
| updated_at         | string   | yes      | ISO-8601 timestamp                           |
| notes              | string   | no       | Special instructions                         |

### delivery_window Object

| Field | Type   | Description                |
|-------|--------|----------------------------|
| from  | string | Start time (HH:MM)         |
| to    | string | End time (HH:MM)           |
| preference | string | morning, afternoon, any |

## How a Service is Initiated

1. **API call** — customer sends JSON to create service
2. **CSV upload** — batch import via `operations/import_csv/`
3. **Phone/SMS/Email** — operator creates service manually from customer request

## Service → Shipment Flow

When a service is confirmed:
1. Agent reads service.json and its parcels
2. Agent creates one or more Shipments (one per delivery address)
3. Each Shipment references back to the service
4. Service status moves to `processing`
5. When all shipments are delivered/completed, service status moves to `completed`

## CRUD Operations

- **Create**: Create `services/{id}/` dir, write `service.json`, create `parcels/` dir
- **Read**: Read `services/{id}/service.json`
- **Update**: Modify fields, update `updated_at`, validate status transition
- **Delete**: Set status to `cancelled` (soft delete)
