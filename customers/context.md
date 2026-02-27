# Customers — Entity Context

## Overview

Customers are the B2B clients that use the logistics platform. Each customer is a company with shipments to deliver. Multi-tenant: customers only see their own data.

## Schema

See `schemas/customer.schema.json`

## Directory Structure

```
customers/
├── context.md          # This file
└── {customer_id}/
    └── customer.json   # Customer data
```

## Key Fields

- **id**: Unique identifier (generated)
- **name**: Company name (required)
- **locations**: Array of warehouses/offices used as route origins
- **webhook_url**: For receiving event notifications
- **frequency_category**: no_frecuente | frecuente | muy_frecuente | super_frecuente

## CRUD Tools

- `tools/customers/create.sh` — Create new customer
- `tools/customers/read.sh` — Read customer by ID
- `tools/customers/update.sh` — Update customer fields
- `tools/customers/delete.sh` — Delete customer
- `tools/customers/list.sh` — List all customers

## Current State

No customers created yet.
