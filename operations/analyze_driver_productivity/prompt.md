# Operation: Analyze Driver Productivity

## Objective

Generate a performance report for a driver over a date range, including delivery success rate, average times, exception patterns, and productivity per RGU/zone.

## When to Use

- Periodic performance reviews (weekly, monthly)
- When investigating delivery failures
- To rank drivers and identify training needs
- To calibrate RGU time budgets based on real performance

## Inputs

1. Read `drivers/{driver_id}/driver.json` for driver info
2. Read all routes assigned to this driver within date range (scan `routes/*/route.json` where `driver_id` matches)
3. For each route, read all stops and their outcomes
4. Date range: `from_date` and `to_date` (ISO-8601 dates)

## Metrics to Calculate

### Delivery Metrics
- **Total stops assigned**: count of all stops in matched routes
- **Delivered**: stops with status = `delivered`
- **Exceptions**: stops with status = `exception`, broken down by type
- **Skipped**: stops with status = `skipped`
- **Success rate**: `(delivered / total_stops) * 100`

### Time Metrics
- **Total routes**: count of routes
- **Avg stops per route**: total stops / total routes
- **Avg route duration**: mean(completed_at - started_at) per route
- **Avg time per delivery**: total route time / total delivered stops

### Exception Analysis
- Breakdown by exception type (absent, wrong_address, refused, damaged, other)
- Most common exception type
- Percentage of each type

### Productivity per Zone (if isochrone data available)
- Success rate per RGU/zone
- Average time per stop per zone
- Zones where driver excels vs struggles

## Outputs

1. Update `drivers/{driver_id}/driver.json` → `productivity_stats`
2. Generate report at `drivers/{driver_id}/reports/{YYYY-MM-DD}_productivity.md`:

```markdown
# Driver Productivity Report

**Driver**: {name}
**Period**: {from_date} to {to_date}
**Generated**: {now}

## Summary
| Metric              | Value     |
|---------------------|-----------|
| Total routes        | X         |
| Total stops         | X         |
| Delivered           | X (Y%)   |
| Exceptions          | X (Y%)   |
| Skipped             | X (Y%)   |
| Avg route duration  | X min     |
| Avg time/delivery   | X min     |

## Exception Breakdown
| Type           | Count | Percentage |
|----------------|-------|------------|
| Absent         | X     | Y%         |
| Wrong address  | X     | Y%         |
| ...            |       |            |

## Trend
(comparison with previous period if data available)
```

## Success Criteria

- All metrics calculated accurately from route/stop data
- Report file generated
- Driver stats updated in driver.json
