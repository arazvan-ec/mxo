#!/usr/bin/env python3
"""
Generate driver performance report.

Usage:
    python3 tools/reports/driver_performance.py [--driver_id=<did>] [--date_from=YYYY-MM-DD]

Output: JSON with per-driver metrics: routes, deliveries, exceptions, rate, avg stops/route.
"""

import json
import os
import sys
import argparse


def get_project_root():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--driver_id', default='')
    parser.add_argument('--date_from', default='')
    args = parser.parse_args()

    project_root = get_project_root()
    routes_dir = os.path.join(project_root, 'routes')
    drivers_dir = os.path.join(project_root, 'drivers')

    # Collect per-driver stats
    stats = {}

    if os.path.isdir(routes_dir):
        for rid in os.listdir(routes_dir):
            route_file = os.path.join(routes_dir, rid, 'route.json')
            if not os.path.isfile(route_file):
                continue
            with open(route_file) as f:
                route = json.load(f)

            did = route.get('driver_id', '')
            if not did:
                continue
            if args.driver_id and did != args.driver_id:
                continue
            if args.date_from and route.get('created', '') < args.date_from:
                continue

            if did not in stats:
                # Load driver name
                dname = did
                dfile = os.path.join(drivers_dir, did, 'driver.json')
                if os.path.isfile(dfile):
                    with open(dfile) as f:
                        dname = json.load(f).get('name', did)
                stats[did] = {
                    'driver_id': did,
                    'driver_name': dname,
                    'routes': 0,
                    'routes_completed': 0,
                    'total_stops': 0,
                    'delivered': 0,
                    'exceptions': 0,
                    'skipped': 0,
                }

            stats[did]['routes'] += 1
            if route.get('status') == 'done':
                stats[did]['routes_completed'] += 1

            stops_dir = os.path.join(routes_dir, rid, 'stops')
            if os.path.isdir(stops_dir):
                for sid in os.listdir(stops_dir):
                    sf = os.path.join(stops_dir, sid, 'stop.json')
                    if not os.path.isfile(sf):
                        continue
                    with open(sf) as f:
                        stop = json.load(f)
                    stats[did]['total_stops'] += 1
                    st = stop.get('status')
                    if st == 'delivered':
                        stats[did]['delivered'] += 1
                    elif st == 'exception':
                        stats[did]['exceptions'] += 1
                    elif st == 'skipped':
                        stats[did]['skipped'] += 1

    # Calculate rates and ranking
    drivers = []
    for did, s in stats.items():
        completed = s['delivered'] + s['exceptions'] + s['skipped']
        s['delivery_rate_pct'] = round(s['delivered'] / completed * 100, 1) if completed > 0 else 0
        s['avg_stops_per_route'] = round(s['total_stops'] / s['routes'], 1) if s['routes'] > 0 else 0
        drivers.append(s)

    # Sort by delivery rate descending
    drivers.sort(key=lambda d: d['delivery_rate_pct'], reverse=True)

    # Add ranking
    for i, d in enumerate(drivers, 1):
        d['rank'] = i

    print(json.dumps({
        'total_drivers': len(drivers),
        'drivers': drivers
    }, indent=2))


if __name__ == '__main__':
    main()
