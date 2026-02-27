#!/usr/bin/env python3
"""
Calculate ETA for each pending stop in a route.

Usage:
    python3 tools/tracking/eta.py <route_id> [--current_lat=<lat> --current_lng=<lng>]

If no current position given, uses route origin.
Uses config defaults: avg_speed_kmh=30, stop_time_min=2
"""

import json
import os
import sys
from datetime import datetime, timezone, timedelta

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'lib'))
from distance import haversine


def get_project_root():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


def main():
    if len(sys.argv) < 2:
        print("Usage: eta.py <route_id> [--current_lat=<lat> --current_lng=<lng>]", file=sys.stderr)
        sys.exit(1)

    route_id = sys.argv[1]
    project_root = get_project_root()

    # Parse optional current position
    current_lat = None
    current_lng = None
    for arg in sys.argv[2:]:
        if arg.startswith('--current_lat='):
            current_lat = float(arg.split('=')[1])
        elif arg.startswith('--current_lng='):
            current_lng = float(arg.split('=')[1])

    # Load config
    config_file = os.path.join(project_root, 'config', 'defaults.json')
    config = {}
    if os.path.isfile(config_file):
        with open(config_file) as f:
            config = json.load(f)

    avg_speed = config.get('avg_speed_kmh', 30)
    stop_time = config.get('stop_time_min', 2)

    # Load route
    route_file = os.path.join(project_root, 'routes', route_id, 'route.json')
    if not os.path.isfile(route_file):
        print(json.dumps({'error': f'Route {route_id} not found'}), file=sys.stderr)
        sys.exit(1)

    with open(route_file) as f:
        route = json.load(f)

    # Use current position or origin
    if current_lat is None:
        current_lat = route['origin_lat']
        current_lng = route['origin_lng']

    # Load stops sorted by sequence
    stops_dir = os.path.join(project_root, 'routes', route_id, 'stops')
    stops = []
    if os.path.isdir(stops_dir):
        for sid in os.listdir(stops_dir):
            sf = os.path.join(stops_dir, sid, 'stop.json')
            if os.path.isfile(sf):
                with open(sf) as f:
                    stops.append(json.load(f))
    stops.sort(key=lambda s: s.get('sequence', 0))

    # Calculate ETAs for pending/arrived stops
    now = datetime.now(timezone.utc)
    cumulative_time = 0  # minutes
    prev_lat, prev_lng = current_lat, current_lng
    etas = []

    for stop in stops:
        if stop.get('status') in ('delivered', 'exception', 'skipped'):
            continue

        dist = haversine(prev_lat, prev_lng, stop['lat'], stop['lng'])
        travel_time = (dist / avg_speed) * 60  # minutes
        cumulative_time += travel_time

        eta_time = now + timedelta(minutes=cumulative_time)

        etas.append({
            'stop_id': stop['id'],
            'sequence': stop.get('sequence'),
            'recipient_name': stop.get('recipient_name', ''),
            'address': stop.get('address', ''),
            'distance_km': round(dist, 2),
            'travel_time_min': round(travel_time, 1),
            'cumulative_time_min': round(cumulative_time, 1),
            'eta': eta_time.strftime('%Y-%m-%dT%H:%M:%SZ'),
        })

        # Add stop time for next calculation
        cumulative_time += stop_time
        prev_lat, prev_lng = stop['lat'], stop['lng']

    result = {
        'route_id': route_id,
        'current_position': {'lat': current_lat, 'lng': current_lng},
        'avg_speed_kmh': avg_speed,
        'stop_time_min': stop_time,
        'pending_stops': len(etas),
        'total_remaining_time_min': round(cumulative_time, 1),
        'etas': etas
    }

    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
