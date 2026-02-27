# Operation: Calculate ETA

## Objective

Calculate the Estimated Time of Arrival (ETA) for each pending stop in a route, based on current vehicle position, stop distances, and estimated delivery time per stop.

## When to Use

- When a route is active and the driver is on the road
- When a customer or recipient asks for delivery time
- After route optimization (to update ETAs with new stop order)

## Inputs

1. Read `routes/{route_id}/route.json` for vehicle_id
2. Read `vehicles/{vehicle_id}/vehicle.json` for `last_position`
3. Read all pending stops from `routes/{route_id}/stops/`
4. Parameters:
   - `average_speed_kmh`: Default 30 km/h (urban last-mile)
   - `stop_duration_min`: Default 2 minutes per delivery stop

## Algorithm

1. Start from current vehicle position (or origin if route not started)
2. For each pending stop in sequence order:
   a. Calculate Haversine distance from previous point
   b. `travel_time_min = distance_km / average_speed_kmh * 60`
   c. `eta = previous_eta + travel_time_min + stop_duration_min`
3. The first stop's ETA starts from now + travel time to reach it

## Outputs

1. Update each pending stop's `eta` field with ISO-8601 timestamp
2. Update `time_from_prev_min` for each stop
3. Log calculation in route's `context.md`

## Constraints

- Only calculate for `pending` stops
- If no vehicle position available, use route origin as starting point
- ETAs are estimates — recalculate periodically as vehicle moves

## Success Criteria

- All pending stops have an `eta` value
- ETAs are in chronological order matching stop sequence
