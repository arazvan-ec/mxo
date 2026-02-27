# Operation: Calculate Isochrone (RGU)

## Objective

Compute the geographic area reachable from an origin point within a given time budget. This creates an isochrone — the boundary of all points a vehicle can reach within X minutes. Used to define RGUs (Rutas Geográficas Unitarias) for efficient route grouping.

## What is an RGU?

A **RGU (Ruta Geográfica Unitaria)** is a delivery zone defined by travel time from an origin, not by arbitrary boundaries. It represents the area a single driver can cover in one trip.

## What is an Isochrone?

An **isochrone** is a contour line connecting all points reachable from an origin within a specific time. A 30-minute isochrone from a warehouse shows all addresses a driver can reach within 30 minutes.

## When to Use

- To define delivery zones for route planning
- To group shipments by geographic reachability before creating routes
- To evaluate driver productivity per zone
- To determine which stops fit within a driver's time budget

## Inputs

1. Origin coordinates (latitude, longitude) — typically a customer's warehouse
2. Time budget in minutes (e.g., 30, 45, 60)
3. Average speed in km/h (default: 30 km/h for urban, 50 km/h for suburban)
4. List of candidate delivery points to check (from pending shipments)

## Algorithm

### Simple Circle Approximation

1. `max_distance_km = (average_speed_kmh * time_budget_min) / 60`
2. For each candidate point, calculate Haversine distance from origin
3. Points within `max_distance_km` are "reachable"
4. Account for delivery time: subtract `stop_duration_min * estimated_stops` from driving time

### Enhanced: Road-Aware (future refinement)

For more accurate results, factor in:
- Road network detour factor (typically 1.3x straight-line distance)
- Traffic patterns by time of day
- One-way streets and highway access

## Outputs

1. Create or update `routes/{route_id}/context.md` with isochrone analysis
2. Return list of reachable shipment IDs with distance and estimated travel time
3. Return unreachable shipment IDs (too far for time budget)
4. Calculate zone statistics:
   - Number of reachable stops
   - Total weight/volume in zone
   - Estimated route time (travel + deliveries)

## Use for Route Planning

```
1. Read all unassigned shipments for a customer
2. Calculate isochrone from customer's warehouse with time budget
3. Group reachable shipments into a route
4. Check vehicle capacity for the group
5. If fits → create route. If not → split into multiple routes
6. Repeat for remaining unreachable shipments with adjusted origin or larger time budget
```

## Driver Productivity per RGU

After route execution, compare:
- **Planned**: X stops within isochrone, estimated Y minutes
- **Actual**: X-n stops delivered, Z minutes actual
- **Success rate**: (delivered / planned) per zone
- **Time accuracy**: actual vs estimated

## Success Criteria

- All candidate points classified as reachable or unreachable
- Distance and time calculations are correct
- Output is usable by `auto_assign_routes` operation
