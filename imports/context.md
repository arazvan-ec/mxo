# Imports — Entity Context

## Overview

Records of CSV import operations. Each import creates shipments for a customer from a CSV file. Tracks success/skip/error counts for audit.

## Schema

See `schemas/import_run.schema.json`

## Directory Structure

```
imports/
├── context.md            # This file
└── {import_id}/
    ├── import.json       # Import run record
    └── source.csv        # Copy of original CSV (optional)
```

## CSV Format

Expected columns: `reference,recipient_name,address,lat,lng,phone,notes,weight_kg,volume_m3,ean,description`

- `reference` is used for deduplication (unique per customer)
- `lat,lng` are validated as numeric coordinates
- `weight_kg,volume_m3` create a single package per row (for multi-package, use tools)

## Current State

No imports executed yet.
