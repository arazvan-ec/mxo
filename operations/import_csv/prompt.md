# Operation: Import CSV

## Objective

Process a CSV file uploaded by a customer, creating services and/or shipments from each row. Track the import run with statistics and error reporting.

## When to Use

- When a customer uploads a CSV with delivery data
- When batch-creating shipments from external data

## Inputs

1. The CSV file path (saved at `imports/{import_id}/source.csv`)
2. The customer_id of the uploading customer
3. Read `imports/{import_id}/import.json` for import metadata

## Algorithm

1. Read the CSV file, parse headers
2. For each row:
   a. Validate required fields: reference, recipient_name, address
   b. Check for duplicate reference within this customer's existing shipments
   c. If `weight_kg` and `volume_m3` present, create a parcel
   d. Create a service (type from CSV or default `delivery`)
   e. Create a shipment from the service
   f. Generate tracking token (TRK-XXXX-XXXX)
   g. Create tracking entry
3. Track counts: created, skipped (duplicates), errors (validation failures)
4. Write errors to `imports/{import_id}/errors.json`

## Expected CSV Columns

| Column          | Required | Description                |
|-----------------|----------|----------------------------|
| reference       | yes      | Unique shipment reference  |
| recipient_name  | yes      | Delivery recipient         |
| address         | yes      | Delivery address           |
| latitude        | no       | GPS latitude               |
| longitude       | no       | GPS longitude              |
| phone           | no       | Recipient phone            |
| email           | no       | Recipient email            |
| weight_kg       | no       | Parcel weight              |
| volume_m3       | no       | Parcel volume              |
| notes           | no       | Special instructions       |
| service_type    | no       | delivery/delivery_pickup/return |

## Outputs

1. Created service entities at `services/{id}/`
2. Created shipment entities at `shipments/{id}/`
3. Created parcel entities at `parcels/{id}/` (if weight/volume provided)
4. Created tracking entities at `tracking/{token}/`
5. Updated `imports/{import_id}/import.json` with final stats
6. Created `imports/{import_id}/errors.json` with any validation errors

## Error Handling

Errors per row are recorded but don't stop processing. Format:
```json
{
  "errors": [
    { "row": 5, "reference": "REF-123", "error": "Missing required field: address" },
    { "row": 12, "reference": "REF-456", "error": "Duplicate reference" }
  ]
}
```

## Success Criteria

- All valid rows created as services + shipments
- Duplicates correctly identified and skipped
- Import stats accurate (total = created + skipped + errors)
- Import status set to `completed` or `failed`
