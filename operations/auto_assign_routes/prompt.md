# Operation: Auto-Assign Routes

## Objective

Given unassigned shipments, available vehicles, and available drivers, automatically create optimized circular routes grouped by RGU. This is the **main planning operation** — it orchestrates the full pipeline:

```
Shipments → RGU Grouping → Vehicle Matching → Route Creation → Optimization → ETA → Delivery Note
```

## When to Use

- After a CSV import creates many shipments
- Daily route planning (process all pending shipments for a date)
- When a customer uploads a batch of orders

## Inputs

1. Unassigned shipments (no `route_id`, status = `created` or `picked_up`)
2. Available vehicles (status = `available`)
3. Available drivers (status = `active`)
4. Customer's warehouse location (origin for routes)
5. Planning parameters:
   - `time_budget_min`: Max round-trip time per route (default: 120 min)
   - `stop_duration_min`: Time per delivery stop (default: 3 min)
   - `average_speed_kmh`: Default 25 (urban), 40 (suburban), 60 (rural)
   - `optimization_strategy`: Default `petalo` (or per-route override)
   - `return_to_origin`: Default `true`
   - `planned_date`: Date for the routes

## Algorithm

### Phase 1: Calculate RGUs (uses `calculate_isochrone`)

1. Read customer's default warehouse location for origin coordinates
2. Read `config/optimization.json` for default parameters
3. Run `calculate_isochrone` with:
   - Origin = warehouse coordinates
   - Time budget = `time_budget_min`
   - All unassigned shipments as candidates
4. Result: shipments grouped by RGU zone + sectors

```
800 shipments → calculate_isochrone → 4 RGU zones:
  Zone NE: 230 shipments
  Zone SE: 180 shipments
  Zone SW: 210 shipments
  Zone NW: 150 shipments
  Unreachable: 30 shipments (flag for review)
```

### Phase 2: Split Zones by Vehicle Capacity

For each RGU zone:
1. Calculate total weight and volume of all parcels in the zone
2. Find the largest available vehicle that fits
3. If no single vehicle fits → split the zone:
   - Order shipments by bearing within the sector
   - Split into sub-groups that each fit a vehicle
4. Each sub-group becomes one route

```
Zone NE (230 shipments, 3,200 kg):
  Van 1 capacity: 1,500 kg → Route NE-1 (110 shipments)
  Van 2 capacity: 1,500 kg → Route NE-2 (120 shipments)
```

### Phase 3: Match Vehicles and Drivers

For each route:
1. Assign the best-fit vehicle (minimize wasted capacity)
2. Assign an available driver
3. Run `check_vehicle_capacity` to validate the assignment
4. If validation fails → split further

Priority rules for assignment:
- **Super-frequent customers**: Assign their dedicated driver/vehicle if configured
- **Very-frequent customers**: Prefer consistent driver assignment (same driver same zone)
- **Frequent/not-frequent**: Assign by availability

### Phase 4: Create and Optimize Routes

For each route:
1. **Create** route entity at `routes/{id}/route.json` with:
   - `customer_id`, `vehicle_id`, `driver_id`
   - `origin_latitude`, `origin_longitude`
   - `optimization_strategy` (from config or parameter)
   - `return_to_origin` (from config or parameter)
   - `planned_date`
   - `status: "planned"`
2. **Create stops** at `routes/{id}/stops/{stop_id}.json` from shipments
3. **Optimize**: Run `optimize_route` with the selected strategy
4. **ETA**: Run `calculate_eta` to set arrival times per stop
5. **Validate**: Run `check_vehicle_capacity` for final confirmation
6. **Delivery note**: Run `generate_delivery_note` to create albarán

### Phase 5: Handle Unreachable Shipments

For shipments outside all RGU zones:
1. Flag as `unassignable` with reason (distance, no vehicle available)
2. Suggest alternatives:
   - Different origin (another depot)
   - Larger time budget
   - Dedicated single-shipment route
   - Schedule for another day
3. Log in planning output for operator review

### Phase 6: Summary for Operator Review

Present a planning summary:

```
═══ Route Planning Summary — 2026-02-28 ═══

Customer: Raul Logistics
Origin: Warehouse Madrid Centro (40.4168, -3.7038)
Strategy: petalo (circular clusters)

Routes created: 8
  Route RT-001 (NE-1): 45 stops, Van-L (#1234), Driver Juan
    Distance: 38.2 km (circular), Est. time: 1h52m
    Weight: 1,280 kg / 1,500 kg (85%), Volume: 4.2 m³ / 8.0 m³ (53%)

  Route RT-002 (NE-2): 42 stops, Van-M (#5678), Driver María
    Distance: 35.1 km (circular), Est. time: 1h48m
    ...

Total shipments assigned: 770 / 800
Unreachable: 30 (flagged for review)
Vehicles used: 8 / 12 available
═══════════════════════════════════════════
```

All routes are created in `planned` status. Operator reviews and activates.

## Outputs

1. Created routes at `routes/{id}/` with optimized stops
2. Updated shipments with `route_id` and `route_stop_id`
3. Generated delivery notes for each route
4. Planning summary report
5. List of unassignable shipments with reasons

## Strategy Auto-Selection

If no strategy is specified, the agent selects based on geography:

| Zone shape | Auto-selected strategy |
|------------|----------------------|
| Circular/fan-shaped sector | `petalo` |
| Elongated along a road/corridor | `zigzag` |
| Few stops (<10) in this route | `nearest` |
| One far outlier + nearby cluster | `farthest_first` |

The agent logs the selection reason in each route's `optimization_log.md`.

## Constraints

- Never assign more parcels than vehicle capacity allows
- Always validate circular distance (including return to origin)
- Leave routes in `planned` status for human review
- Log all decisions in route `context.md` files
- Respect delivery windows when assigning stops to routes
- Respect customer frequency classification for driver/vehicle consistency

## Success Criteria

- All assignable shipments grouped by RGU and assigned to routes
- Vehicle capacity validated for every route
- Routes optimized with named strategy and circular distance calculated
- ETAs calculated for all stops
- Delivery notes generated
- Unreachable shipments flagged with reasons
- Operator can review before activation
