# Operation: Optimize Route

## Objective

Reorder the stops in a route to minimize total travel distance and time, ensuring efficient delivery execution.

## When to Use

- After adding stops to a route (before starting execution)
- When a route's stop order seems suboptimal
- When stops are added or removed from an active route

## Inputs

1. Read `routes/{route_id}/route.json` for origin coordinates
2. Read all files in `routes/{route_id}/stops/` for stop coordinates and status
3. Only optimize stops with status = `pending` (skip delivered/exception/skipped)

## Algorithm

### Strategy: Farthest-First with Nearest-Neighbor Return

1. Start from the origin point (route's origin_latitude, origin_longitude)
2. Find the farthest pending stop from the origin — this is the first destination
3. From that farthest point, apply nearest-neighbor: always go to the closest unvisited stop
4. Continue until all stops are sequenced
5. This ensures the driver goes out far first and works their way back efficiently

### Distance Calculation: Haversine Formula

For any two coordinates (lat1, lon1) and (lat2, lon2):
```
R = 6371 (Earth radius in km)
dlat = lat2 - lat1 (in radians)
dlon = lon2 - lon1 (in radians)
a = sin²(dlat/2) + cos(lat1) * cos(lat2) * sin²(dlon/2)
c = 2 * atan2(√a, √(1-a))
distance = R * c
```

### Alternative Strategies (for refinement)

- **Pure nearest-neighbor**: from origin, always go to closest. Simple but misses the "work your way back" efficiency.
- **Cluster-based**: group stops by geographic proximity, optimize within clusters, then sequence clusters.
- **Isochrone-based**: use `calculate_isochrone` to group stops by time reachability.

## Outputs

1. Update `sequence` field in each stop's JSON file with new order (1, 2, 3...)
2. Calculate `distance_from_prev_km` for each stop
3. Calculate total route distance (before and after optimization)
4. Update `routes/{route_id}/route.json`:
   - Set `total_distance_km` (if not set) or `optimized_distance_km`
5. Append to `routes/{route_id}/optimization_log.md`:
   - Timestamp, algorithm used, before/after distance, percentage saved, new stop order

## Constraints

- Never reorder stops that are already `delivered` or `exception`
- If a stop has a `delivery_window`, respect it (try to fit within window)
- If optimization produces a worse result than current order, keep current order and log why

## Success Criteria

- All pending stops have updated sequence numbers
- Total distance decreased (or explanation logged if not)
- optimization_log.md has a new entry
