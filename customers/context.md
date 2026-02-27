# Customers — Context

## Purpose

Customers are B2B tenant companies that use mxo-track for their logistics. Each customer has their own shipments, routes, locations, and services. Multi-tenancy is enforced by filtering on `customer_id`.

## Directory Structure

```
customers/{customer_id}/
├── customer.json         # Company data (name, tax_id, contact, webhook)
├── context.md            # Working memory for this customer
└── locations/            # Customer's warehouses and depots
    └── {location_id}.json
```

## Schema: customer.json

| Field              | Type     | Required | Description                            |
|--------------------|----------|----------|----------------------------------------|
| id                 | string   | yes      | ULID, unique identifier                |
| name               | string   | yes      | Company legal name                     |
| tax_id             | string   | no       | CIF/NIF for billing                    |
| contact_name       | string   | yes      | Primary contact person                 |
| contact_email      | string   | yes      | Primary contact email                  |
| contact_phone      | string   | no       | Primary contact phone                  |
| address            | string   | no       | Company address                        |
| webhook_url        | string   | no       | URL for event webhooks                 |
| webhook_secret     | string   | no       | HMAC-SHA256 secret for webhook signing |
| frequency_class    | string   | no       | One of: not_frequent, frequent, very_frequent, super_frequent |
| delivery_preferences | object | no       | Preferred delivery windows (morning/afternoon) |
| status             | string   | yes      | active, suspended, inactive            |
| created_at         | string   | yes      | ISO-8601 timestamp                     |
| updated_at         | string   | yes      | ISO-8601 timestamp                     |
| notes              | string   | no       | Free-text notes                        |

## CRUD Operations

- **Create**: Create `customers/{id}/` directory, write `customer.json`, create `context.md`
- **Read**: Read `customers/{id}/customer.json`
- **Update**: Modify fields in `customer.json`, update `updated_at`
- **Delete**: Set status to `inactive` (soft delete preferred)

## Location Sub-Entity

Locations are customer's warehouses/depots (origins for routes).

| Field       | Type   | Required | Description                    |
|-------------|--------|----------|--------------------------------|
| id          | string | yes      | ULID                           |
| name        | string | yes      | Location name (e.g. "Warehouse Madrid") |
| address     | string | yes      | Full address                   |
| latitude    | number | yes      | GPS latitude                   |
| longitude   | number | yes      | GPS longitude                  |
| type        | string | yes      | warehouse, depot, office       |
| is_default  | boolean| no       | Default origin for routes      |

Stored at `customers/{customer_id}/locations/{location_id}.json`
