# Operation: Optimize Route

## Objective

Reorder the stops in a route to minimize total travel distance and time, ensuring the driver completes a circular trip (origin → stops → origin) efficiently. The route is always scoped to a single **RGU** (Ruta Geográfica Unitaria) — all stops have already been grouped by geographic reachability before optimization.

## Key Principles

1. **Circular by default** — Every route is a round trip: starts at origin, visits all stops, returns to origin. The return leg is included in all distance/time calculations. Open routes (no return) are allowed only when `route.json` has `"return_to_origin": false`.
2. **RGU-scoped** — Stops in this route already belong to one RGU (isochrone zone). Optimization works within that zone, not across zones.
3. **Strategy-driven** — The optimization strategy is selected per route via `route.json` field `"optimization_strategy"`. If not set, default is `petalo`.

## When to Use

- After adding stops to a route (before starting execution)
- When stops are added or removed from an active route
- After `auto_assign_routes` groups shipments into RGU-based routes

## Inputs

1. Read `routes/{route_id}/route.json` for:
   - `origin_latitude`, `origin_longitude` (warehouse/depot)
   - `optimization_strategy` (default: `petalo`)
   - `return_to_origin` (default: `true`)
2. Read all files in `routes/{route_id}/stops/` for stop coordinates and status
3. Only optimize stops with status = `pending` (skip delivered/exception/skipped)
4. Read `config/optimization.json` for strategy parameters

## Distance Calculation: Haversine Formula

For any two coordinates (lat1, lon1) and (lat2, lon2):
```
R = 6371 (Earth radius in km)
dlat = lat2 - lat1 (in radians)
dlon = lon2 - lon1 (in radians)
a = sin²(dlat/2) + cos(lat1) * cos(lat2) * sin²(dlon/2)
c = 2 * atan2(√a, √(1-a))
distance = R * c
```

Apply **road detour factor** (default 1.3) to convert straight-line to estimated road distance:
```
road_distance = haversine_distance * detour_factor
```

---

## Strategies

### 1. `petalo` — Petal / Circular Clusters (DEFAULT)

Best for: Dense urban areas with many stops. Routes that cover a geographic sector.

The route forms a "petal" shape from the origin — like petals of a flower, each route covers a sector radiating out from the depot.

**Algorithm:**

1. Calculate the **bearing** (angle) from origin to each pending stop
2. Sort stops by bearing to form a natural circular sweep
3. Divide stops into **sectors** (petals) of ~60° each if more than 15 stops
4. Within each sector, order by distance from origin (nearest first going out, or farthest first coming back)
5. Sequence sectors clockwise (or counterclockwise, whichever minimizes the gap between first and last sector)
6. The driver sweeps out in an arc and returns naturally to the origin

```
        N
        |    · · stop
    · · |· ·
   ·  ╱─────╲  ·
  · ╱    ↑    ╲ ·        Driver follows
  ·│   ORIGIN  │·        a circular sweep
  · ╲    ↓    ╱ ·        through the petal
   ·  ╲─────╱  ·
    · · |· ·
        |
        S
```

**Why it works:** Minimizes backtracking. The driver naturally returns toward the origin after visiting the farthest points because the next sector starts closer to origin. Combined with RGU scoping, each petal stays within the time budget.

### 2. `zigzag` — Linear Sweep

Best for: Corridor routes along a highway, boulevard, or long road. Suburban/industrial zones with linear geography.

**Algorithm:**

1. Determine the **dominant axis** of the stops (the line that best fits their geographic spread — principal component)
2. Project all stops onto this axis
3. Sort stops by position along the axis
4. Alternate sides: if stops are on both sides of the axis, zigzag between them
5. Drive out along the axis, return along the same corridor

```
  Origin ──→ ·    ·    ·    ·    · (end)
              \  / \  / \  / \  /
               ·    ·    ·    ·
                                  ──→ return to origin
```

**Why it works:** When stops are spread along a road or corridor, circular strategies waste time. Zigzag follows the natural geography.

### 3. `nearest` — Nearest Neighbor

Best for: Few stops (<10), irregular/scattered distributions, fallback when other strategies produce poor results.

**Algorithm:**

1. Start at origin
2. Find the nearest unvisited pending stop → go there
3. From current stop, find the nearest unvisited pending stop → go there
4. Repeat until all stops visited
5. Return to origin (if `return_to_origin: true`)

```
  Origin → A → B → C → D → E → Origin
  (always picks closest next stop)
```

**Why it works:** Simple, predictable, easy to explain to drivers. Good enough for small routes. Not optimal for large routes (can produce crossings).

### 4. `farthest_first` — Farthest-First with Nearest Return

Best for: Spread-out routes where one stop is significantly farther than the rest. Ensures the long leg is done first when the driver is fresh.

**Algorithm:**

1. Start at origin
2. Find the **farthest** pending stop from origin → go there first
3. From there, apply nearest-neighbor to visit remaining stops
4. The driver naturally works their way back toward the origin
5. Return to origin (if `return_to_origin: true`)

```
  Origin ──────────────────→ Farthest
                               ↓
  Origin ← · ← · ← · ← · ← nearest-neighbor back
```

**Why it works:** Gets the worst drive out of the way first. The return trip collects nearby stops efficiently. Good when there's one outlier stop.

---

## Strategy Selection Guide

| Condition | Recommended Strategy |
|-----------|---------------------|
| Dense urban, many stops (>15) | `petalo` |
| Stops along a road/corridor | `zigzag` |
| Few stops (<10) | `nearest` |
| One far outlier + nearby cluster | `farthest_first` |
| Default / unknown | `petalo` |

If `route.json` has no `optimization_strategy`, use `petalo`.

An agent or operator can override by setting the field in `route.json` before running optimization.

---

## Circular Route Calculation

### When `return_to_origin: true` (default)

Total route distance includes the return leg:

```
total_distance = sum(distance between consecutive stops) + distance(last_stop → origin)
```

The return leg MUST be included in:
- `total_distance_km` on the route
- `optimization_log.md` comparisons
- ETA calculations (driver's shift ends when they return)

### When `return_to_origin: false`

Total route distance is only the delivery path:

```
total_distance = sum(distance between consecutive stops)
```

Use this for: end-of-day routes where the driver goes home, one-way transfers.

---

## Outputs

1. Update `sequence` field in each stop's JSON file with new order (1, 2, 3...)
2. Calculate `distance_from_prev_km` for each stop (using road detour factor)
3. Calculate `distance_to_origin_km` for the last stop (return leg distance)
4. Update `routes/{route_id}/route.json`:
   - `total_distance_km`: full circular distance (or open distance if no return)
   - `optimized_distance_km`: same, for comparison with pre-optimization
   - `optimization_strategy`: strategy used
   - `return_to_origin`: whether return was included
5. Append to `routes/{route_id}/optimization_log.md`:
   - Timestamp
   - Strategy used and why (auto-selected or manual)
   - Stop count
   - Before distance vs after distance
   - Percentage saved
   - New stop order with distances
   - Return leg distance (if applicable)

## Constraints

- Never reorder stops that are already `delivered` or `exception`
- If a stop has a `delivery_window`, respect it (schedule within window even if order is suboptimal)
- If optimization produces a worse result than current order, keep current order and log why
- Always include return-to-origin in distance comparison when `return_to_origin: true`
- Apply road detour factor (from `config/optimization.json`) to all distances

## Success Criteria

- All pending stops have updated sequence numbers
- Total circular distance decreased (or explanation logged if not)
- optimization_log.md has a new entry with strategy, distances, and stop order
- Return-to-origin distance is calculated and logged
