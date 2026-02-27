# Imports — Context

## Purpose

Imports track CSV/batch uploads from customers. Each import run records what was created, skipped, or errored, and preserves the original source file.

## Directory Structure

```
imports/{import_id}/
├── import.json           # Import run metadata and stats
├── source.csv            # Original uploaded file
├── errors.json           # Validation errors (if any)
└── context.md            # Working memory
```

## Schema: import.json

| Field            | Type     | Required | Description                              |
|------------------|----------|----------|------------------------------------------|
| id               | string   | yes      | ULID                                     |
| customer_id      | string   | yes      | Customer who uploaded                    |
| file_name        | string   | yes      | Original file name                       |
| status           | string   | yes      | pending, processing, completed, failed   |
| total_rows       | number   | no       | Total rows in CSV                        |
| created_count    | number   | no       | Shipments/services created               |
| skipped_count    | number   | no       | Duplicates or invalid rows skipped       |
| error_count      | number   | no       | Rows with errors                         |
| created_shipment_ids | array | no      | IDs of created shipments                 |
| created_service_ids  | array | no      | IDs of created services                  |
| started_at       | string   | no       | Processing start time                    |
| completed_at     | string   | no       | Processing end time                      |
| created_at       | string   | yes      | ISO-8601                                 |
| updated_at       | string   | yes      | ISO-8601                                 |

## CSV Expected Columns

| Column          | Required | Description                |
|-----------------|----------|----------------------------|
| reference       | yes      | Unique shipment reference  |
| recipient_name  | yes      | Delivery recipient name    |
| address         | yes      | Delivery address           |
| latitude        | no       | GPS latitude               |
| longitude       | no       | GPS longitude              |
| phone           | no       | Recipient phone            |
| email           | no       | Recipient email            |
| weight_kg       | no       | Parcel weight              |
| volume_m3       | no       | Parcel volume              |
| notes           | no       | Special instructions       |
| service_type    | no       | delivery, delivery_pickup, return |

## CRUD Operations

- **Create**: Create `imports/{id}/` dir, write `import.json`, save `source.csv`
- **Read**: Read `imports/{id}/import.json`, read `errors.json` for details
- **Update**: Update stats during processing, set final status
- **Delete**: Remove after retention period
