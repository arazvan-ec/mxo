# Operation: Auto-Assign Routes

## Objective

Given a set of unassigned shipments, available vehicles, and available drivers, automatically create routes that distribute deliveries efficiently. This is the main planning operation — it composes multiple other operations.

## When to Use

- After a CSV import creates many shipments
- Daily route planning (process all pending shipments for tomorrow)
- When a customer like "Raul" creates 800 orders and routes need to be created

## Inputs

1. List of unassigned shipments (no `route_id` set, status = `created` or `picked_up`)
2. Available vehicles (status = `available`)
3. Available drivers (status = `active`)
4. Customer's warehouse location (origin for routes)
5. Configuration:
   - Max stops per route (optional, or use vehicle capacity)
   - Time budget per route (optional, for isochrone-based grouping)
   - Planned date

## Algorithm

### Phase 1: Group Shipments by Zone (Isochrone)

1. Read customer's default warehouse location for origin coordinates
2. Use `calculate_isochrone` with time budget to find reachable shipments
3. Group shipments within isochrone radius
4. If too many shipments for one vehicle, split into sub-groups by proximity

### Phase 2: Match Groups to Vehicles

1. For each group, calculate total weight and volume (sum of parcels)
2. Find a vehicle that fits (use `check_vehicle_capacity` logic)
3. If no vehicle fits, split the group further
4. Assign vehicle to group

### Phase 3: Create Routes

For each group:
1. Create route entity with customer, vehicle, origin
2. Create stops from shipments in the group
3. Assign a driver to the route
4. Run `optimize_route` to order stops efficiently
5. Run `calculate_eta` to set ETAs
6. Run `check_vehicle_capacity` to validate fit
7. Run `generate_delivery_note` to create albarán

### Phase 4: Review Before Confirmation

1. Present summary of proposed routes:
   - Route count, stops per route, vehicles assigned
   - Total distance, weight, volume per route
   - Vehicle utilization percentages
2. Routes are created in `planned` status — operator reviews before activating

## Outputs

1. Created routes at `routes/{id}/` with all stops
2. Updated shipments with `route_id` and `route_stop_id`
3. Generated delivery notes for each route
4. Summary report for operator review

## Demo Scenario: Customer "Raul" with 800 Orders

```
1. Raul uploads CSV with 800 shipments → operations/import_csv processes them
2. Agent reads all 800 unassigned shipments
3. Agent reads Raul's warehouse location
4. Agent uses calculate_isochrone to group by zone (~30 min zones)
5. Each zone group → check vehicle capacity → assign vehicle
6. ~800 shipments / ~80 per van = ~10 routes
7. Each route → optimize_route → calculate_eta → delivery_note
8. Agent presents: "10 routes proposed, review before activating"
9. Operator adjusts if needed, then activates routes
```

## Constraints

- Never assign more parcels than vehicle capacity allows
- Prefer distributing stops evenly across routes
- Leave routes in `planned` status for human review
- Log all decisions in route context.md files

## Success Criteria

- All input shipments assigned to routes (or flagged as unassignable with reason)
- Vehicle capacity validated for each route
- Routes optimized and ETAs calculated
- Delivery notes generated
- Operator can review before activation
