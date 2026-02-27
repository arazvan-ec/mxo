# Operation: Check Vehicle Capacity

## Objective

Validate that all parcels assigned to a route fit within the vehicle's weight and volume limits. This must pass before a route can start execution.

## When to Use

- Before transitioning a route from `planned` to `active`
- After adding new stops to a route
- When reassigning a vehicle to a route

## Inputs

1. Read `routes/{route_id}/route.json` for `vehicle_id`
2. Read `vehicles/{vehicle_id}/vehicle.json` for capacity limits
3. Read all stops from `routes/{route_id}/stops/`
4. For each stop, read linked shipment and its parcel_ids
5. For each parcel, read `parcels/{parcel_id}/parcel.json` for weight_kg and volume_m3

## Algorithm

1. Sum all parcel weights: `total_weight_kg`
2. Sum all parcel volumes: `total_volume_m3`
3. Count total parcels: `total_parcel_count`
4. Calculate utilization:
   - `weight_percent = (total_weight_kg / vehicle.max_weight_kg) * 100`
   - `volume_percent = (total_volume_m3 / vehicle.max_volume_m3) * 100`
   - `parcel_percent = (total_parcel_count / vehicle.max_parcels) * 100` (if max_parcels set)
5. Determine fit:
   - `fits = weight_percent <= 100 AND volume_percent <= 100 AND (parcel_percent <= 100 OR no limit)`

## Outputs

1. Update `routes/{route_id}/route.json`:
   - `total_weight_kg`
   - `total_volume_m3`
   - `vehicle_utilization.weight_percent`
   - `vehicle_utilization.volume_percent`
   - `vehicle_utilization.fits`
2. If doesn't fit, log details in route's `context.md`:
   - Which dimension exceeded (weight, volume, or both)
   - By how much
   - Suggestion (remove parcels, use larger vehicle)

## Constraints

- This check is mandatory before route activation
- If vehicle not assigned, operation cannot run (log error)
- If any parcel lacks weight/volume data, flag it as a warning

## Success Criteria

- `vehicle_utilization` field populated in route.json
- Clear pass/fail result
- If fail: actionable explanation
