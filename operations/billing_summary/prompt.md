# Operation: Billing Summary

## Objective

Generate a billing report for a customer over a date range, showing total shipments, deliveries, exceptions, and costs.

## When to Use

- Monthly billing cycle
- Customer requests billing overview
- Admin reviews revenue per customer

## Inputs

1. Read `customers/{customer_id}/customer.json` for customer info
2. Scan all shipments where `customer_id` matches within date range
3. Scan all routes where `customer_id` matches within date range
4. Date range: `from_date` and `to_date` (ISO-8601 dates)
5. Pricing config (if defined — otherwise just count metrics)

## Metrics to Calculate

### Shipment Metrics
- **Total shipments**: count within date range
- **Delivered**: status = `delivered`
- **Exceptions**: status = `exception`
- **In progress**: other statuses
- **Delivery rate**: `(delivered / total) * 100`

### Route Metrics
- **Total routes**: count within date range
- **Completed routes**: status = `done`
- **Total stops across routes**: sum of all stops
- **Total parcels**: sum of all parcels
- **Total weight delivered**: sum of delivered parcel weights
- **Total volume delivered**: sum of delivered parcel volumes

### Cost Metrics (if pricing available)
- **Cost per route**: €/ruta
- **Cost per parcel**: €/bulto
- **Total cost**: sum of all route costs

## Outputs

1. Generate report at `customers/{customer_id}/billing/{YYYY-MM}_billing.md`:

```markdown
# Billing Summary

**Customer**: {name}
**Period**: {from_date} to {to_date}
**Generated**: {now}

## Shipment Summary
| Metric          | Count | Percentage |
|-----------------|-------|------------|
| Total shipments | X     | 100%       |
| Delivered       | X     | Y%         |
| Exceptions      | X     | Y%         |
| In progress     | X     | Y%         |

## Route Summary
| Metric          | Value    |
|-----------------|----------|
| Total routes    | X        |
| Total stops     | X        |
| Total parcels   | X        |
| Total weight    | X kg     |
| Total volume    | X m³     |

## Cost Summary
| Concept          | Value    |
|------------------|----------|
| Routes × €/ruta  | €X       |
| Bultos × €/bulto | €X       |
| **Total**         | **€X**  |
```

2. Also create `customers/{customer_id}/billing/{YYYY-MM}_billing.json` with structured data for integration.

## Success Criteria

- All metrics calculated from actual entity data
- Both markdown and JSON reports generated
- Totals are mathematically correct
