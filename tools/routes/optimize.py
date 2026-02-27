#!/usr/bin/env python3
"""
Optimize route stop order to minimize total distance.

Usage:
    python3 tools/routes/optimize.py <route_id> [--apply] [--preview]

Strategy: Farthest-first + nearest-neighbor
1. Start from route origin
2. Go to the farthest point first
3. From there, always visit nearest unvisited point
4. This creates a natural return-to-origin path

Output: JSON with optimization results (original vs optimized distance)
"""

import json
import os
import sys

# Add lib to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'lib'))
from distance import haversine, nearest_neighbor_order, total_route_distance


def get_project_root():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


def main():
    if len(sys.argv) < 2:
        print("Usage: optimize.py <route_id> [--apply] [--preview]", file=sys.stderr)
        sys.exit(1)

    route_id = sys.argv[1]
    apply_changes = '--apply' in sys.argv
    preview = '--preview' in sys.argv or not apply_changes

    project_root = get_project_root()

    # Load route
    route_file = os.path.join(project_root, 'routes', route_id, 'route.json')
    if not os.path.isfile(route_file):
        print(json.dumps({'error': f'Route {route_id} not found'}), file=sys.stderr)
        sys.exit(1)

    with open(route_file) as f:
        route = json.load(f)

    if route.get('status') != 'planned':
        print(json.dumps({'error': f'Cannot optimize route with status {route["status"]}'}), file=sys.stderr)
        sys.exit(1)

    origin = [route['origin_lat'], route['origin_lng']]

    # Load stops
    stops_dir = os.path.join(project_root, 'routes', route_id, 'stops')
    stops = []
    stop_files = {}

    if os.path.isdir(stops_dir):
        for sid in sorted(os.listdir(stops_dir)):
            stop_file = os.path.join(stops_dir, sid, 'stop.json')
            if os.path.isfile(stop_file):
                with open(stop_file) as f:
                    stop = json.load(f)
                stops.append(stop)
                stop_files[stop['id']] = stop_file

    if len(stops) < 2:
        print(json.dumps({
            'route_id': route_id,
            'message': 'Nothing to optimize (less than 2 stops)',
            'total_stops': len(stops)
        }))
        return

    # Calculate original distance
    original_points = [origin] + [[s['lat'], s['lng']] for s in stops]
    original_distance = total_route_distance(original_points)

    # Optimize
    stop_points = [[s['lat'], s['lng']] for s in stops]
    optimized_order = nearest_neighbor_order(origin, stop_points)

    # Calculate optimized distance
    optimized_points = [origin] + [stop_points[i] for i in optimized_order]
    optimized_distance = total_route_distance(optimized_points)

    savings = round(original_distance - optimized_distance, 3)
    savings_pct = round((savings / original_distance * 100), 1) if original_distance > 0 else 0

    # Build result
    optimized_stops = [stops[i] for i in optimized_order]
    result = {
        'route_id': route_id,
        'total_stops': len(stops),
        'original_distance_km': original_distance,
        'optimized_distance_km': optimized_distance,
        'savings_km': savings,
        'savings_pct': savings_pct,
        'applied': False,
        'new_order': [
            {
                'sequence': idx + 1,
                'stop_id': s['id'],
                'recipient_name': s.get('recipient_name', ''),
                'address': s.get('address', ''),
                'distance_from_previous_km': round(
                    haversine(
                        optimized_points[idx][0], optimized_points[idx][1],
                        optimized_points[idx + 1][0], optimized_points[idx + 1][1]
                    ), 3
                )
            }
            for idx, s in enumerate(optimized_stops)
        ]
    }

    if apply_changes:
        from datetime import datetime, timezone
        now = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

        # Update stop sequences and distances
        for idx, orig_idx in enumerate(optimized_order):
            stop = stops[orig_idx]
            stop_file = stop_files[stop['id']]
            stop['sequence'] = idx + 1
            stop['distance_from_previous_km'] = round(
                haversine(
                    optimized_points[idx][0], optimized_points[idx][1],
                    optimized_points[idx + 1][0], optimized_points[idx + 1][1]
                ), 3
            )
            stop['updated'] = now
            with open(stop_file, 'w') as f:
                json.dump(stop, f, indent=2)

        # Update route total distance
        route['total_distance_km'] = optimized_distance
        route['updated'] = now
        with open(route_file, 'w') as f:
            json.dump(route, f, indent=2)

        # Write optimization log
        log_file = os.path.join(project_root, 'routes', route_id, 'optimization_log.md')
        log_entry = f"""
## Optimization: {now}

- **Original distance**: {original_distance} km
- **Optimized distance**: {optimized_distance} km
- **Savings**: {savings} km ({savings_pct}%)
- **Strategy**: Farthest-first + nearest-neighbor
- **Applied**: Yes
"""
        with open(log_file, 'a') as f:
            f.write(log_entry)

        result['applied'] = True

    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
