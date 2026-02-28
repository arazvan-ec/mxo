# Operation: Calculate Isochrone (RGU)

## Objective

Compute **RGUs** (Rutas Geográficas Unitarias) — delivery zones defined by travel time from an origin. Each RGU represents the area a single driver can cover in one round trip. RGUs are the foundation of route planning: shipments are grouped by RGU BEFORE routes are created and optimized.

## Key Concepts

### RGU (Ruta Geográfica Unitaria)

A delivery zone defined by **reachable travel time**, not arbitrary boundaries. One RGU = one route = one driver + one vehicle for one trip.

Properties of a well-defined RGU:
- All stops are reachable from origin within the time budget
- Total delivery time (travel + stops) fits within the driver's shift
- Total parcel weight/volume fits within one vehicle
- The driver can complete the round trip (out + deliveries + return) within the budget

### Isochrone

A contour connecting all points reachable from an origin within a specific time. A 60-minute isochrone from a warehouse shows all addresses a driver can reach and return from within 2 hours (60 min out + 60 min back).

### RGU vs Route

```
RGU = geographic zone (calculated BEFORE route exists)
Route = specific sequence of stops within an RGU (created AFTER grouping)

Flow:  Shipments → Group by RGU → Create Route per RGU → Optimize stop order
```

## When to Use

- **Daily planning**: Before creating any routes, calculate RGUs to group shipments
- **New shipment assignment**: Determine which existing RGU a new shipment belongs to
- **Zone analysis**: Evaluate delivery density and coverage per area
- **Capacity planning**: How many vehicles/drivers needed for a geographic area

## Inputs

1. Origin coordinates (latitude, longitude) — customer's warehouse or depot
2. Time budget in minutes (default: 120 min = 2-hour round trip)
3. Average speed in km/h:
   - Urban: 25 km/h (default)
   - Suburban: 40 km/h
   - Highway/rural: 60 km/h
4. Stop duration in minutes (default: 3 min per delivery)
5. List of candidate shipments with coordinates (from pending unassigned shipments)
6. Road detour factor (default: 1.3 — from `config/optimization.json`)

## Algorithm

### Phase 1: Calculate Maximum Radius

```
effective_driving_time = time_budget - (estimated_stops * stop_duration)
one_way_time = effective_driving_time / 2    ← ROUND TRIP: half out, half back
max_distance_km = (average_speed * one_way_time) / 60
max_road_distance = max_distance_km / detour_factor   ← Convert road to straight-line
```

**Critical**: Divide by 2 for round trip. A 120-min budget with 20 stops × 3 min = 60 min driving. That's 30 min out, 30 min back = ~12.5 km radius at 25 km/h.

### Phase 2: Classify Shipments

For each candidate shipment:
1. Calculate Haversine distance from origin
2. If distance ≤ `max_road_distance` → **reachable** (belongs to this RGU)
3. If distance > `max_road_distance` → **unreachable** (needs a different RGU or larger budget)

### Phase 3: Sector Division (for large RGUs)

If a single RGU has too many stops for one vehicle:

1. Calculate bearing from origin to each reachable stop
2. Divide the RGU into **sectors** (angular slices, typically 60°-90° each)
3. Each sector becomes a sub-RGU → one route
4. This aligns naturally with the `petalo` optimization strategy

```
         N (0°)
         |
   NW ·  |  · NE        Sector 1: 0°-90° (NE) → Route A
      ·  |  ·           Sector 2: 90°-180° (SE) → Route B
  W ──── O ──── E       Sector 3: 180°-270° (SW) → Route C
      ·  |  ·           Sector 4: 270°-360° (NW) → Route D
   SW ·  |  · SE
         |
         S (180°)
```

### Phase 4: Validate Each Sub-RGU

For each sector/sub-RGU, verify:
1. **Time fit**: total travel + (stops × stop_duration) ≤ time_budget
2. **Capacity fit**: total weight/volume of parcels ≤ vehicle capacity
3. If either fails → split further or reassign stops to adjacent sector

## Outputs

1. List of RGU zones, each containing:
   - Zone ID (e.g., `RGU-{origin_id}-{bearing_start}-{bearing_end}`)
   - Origin coordinates
   - Radius km
   - Bearing range (sector)
   - Shipment IDs in this zone
   - Stop count
   - Total weight/volume
   - Estimated route time (travel + deliveries + return)
2. List of unreachable shipments with:
   - Distance from origin
   - Reason (too far, outside time budget)
   - Suggested action (larger vehicle, different origin, separate trip)
3. Zone statistics summary:
   - Total RGUs needed
   - Vehicles needed
   - Coverage: assigned vs unassigned shipments
4. Write results to `routes/{route_id}/context.md` or a planning output file

## Integration with Route Creation

The output of this operation feeds directly into `auto_assign_routes`:

```
calculate_isochrone          auto_assign_routes           optimize_route
┌──────────────┐            ┌──────────────────┐         ┌──────────────┐
│ Shipments →  │            │ RGU zone →       │         │ Route stops →│
│ Group by RGU │───────────▶│ Create route +   │────────▶│ Order by     │
│ and sector   │            │ assign vehicle + │         │ strategy     │
│              │            │ driver           │         │ (petalo etc) │
└──────────────┘            └──────────────────┘         └──────────────┘
```

## Driver Productivity per RGU

After route execution, compare per zone:
- **Planned**: X stops within RGU, estimated Y minutes
- **Actual**: delivered count, actual minutes
- **Success rate**: delivered / planned per zone
- **Time accuracy**: actual vs estimated

Store in `routes/{route_id}/context.md` for continuous improvement.

## Success Criteria

- All candidate shipments classified as reachable or unreachable
- Round-trip time budget respected (not just one-way)
- Sectors created when stop count exceeds vehicle capacity
- Output is directly usable by `auto_assign_routes`
- Distance calculations use road detour factor
