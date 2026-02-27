#!/usr/bin/env python3
"""
Generate delivery statistics report.

Usage:
    python3 tools/reports/delivery_stats.py [--driver_id=<did>] [--customer_id=<cid>] [--date_from=YYYY-MM-DD] [--date_to=YYYY-MM-DD]

Output: JSON with delivery/exception counts, rates, and breakdowns.
"""

import json
import os
import sys
import argparse
from datetime import datetime


def get_project_root():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--driver_id', default='')
    parser.add_argument('--customer_id', default='')
    parser.add_argument('--date_from', default='')
    parser.add_argument('--date_to', default='')
    args = parser.parse_args()

    project_root = get_project_root()
    routes_dir = os.path.join(project_root, 'routes')

    total_routes = 0
    total_stops = 0
    delivered = 0
    exceptions = 0
    skipped = 0
    pending = 0
    exception_types = {}
    routes_by_status = {'planned': 0, 'active': 0, 'done': 0, 'cancelled': 0}

    if not os.path.isdir(routes_dir):
        print(json.dumps({'message': 'No routes found', 'total_routes': 0}))
        return

    for rid in os.listdir(routes_dir):
        route_file = os.path.join(routes_dir, rid, 'route.json')
        if not os.path.isfile(route_file):
            continue

        with open(route_file) as f:
            route = json.load(f)

        # Apply filters
        if args.driver_id and route.get('driver_id') != args.driver_id:
            continue
        if args.customer_id and route.get('customer_id') != args.customer_id:
            continue
        if args.date_from:
            created = route.get('created', '')
            if created < args.date_from:
                continue
        if args.date_to:
            created = route.get('created', '')
            if created > args.date_to + 'T23:59:59Z':
                continue

        total_routes += 1
        status = route.get('status', 'planned')
        routes_by_status[status] = routes_by_status.get(status, 0) + 1

        # Count stops
        stops_dir = os.path.join(routes_dir, rid, 'stops')
        if not os.path.isdir(stops_dir):
            continue

        for sid in os.listdir(stops_dir):
            stop_file = os.path.join(stops_dir, sid, 'stop.json')
            if not os.path.isfile(stop_file):
                continue

            with open(stop_file) as f:
                stop = json.load(f)

            total_stops += 1
            st = stop.get('status', 'pending')
            if st == 'delivered':
                delivered += 1
            elif st == 'exception':
                exceptions += 1
                exc_type = stop.get('exception', {}).get('type', 'unknown')
                exception_types[exc_type] = exception_types.get(exc_type, 0) + 1
            elif st == 'skipped':
                skipped += 1
            else:
                pending += 1

    completed = delivered + exceptions + skipped
    delivery_rate = round(delivered / completed * 100, 1) if completed > 0 else 0
    exception_rate = round(exceptions / completed * 100, 1) if completed > 0 else 0

    result = {
        'filters': {
            'driver_id': args.driver_id or 'all',
            'customer_id': args.customer_id or 'all',
            'date_from': args.date_from or 'all',
            'date_to': args.date_to or 'all',
        },
        'routes': {
            'total': total_routes,
            'by_status': routes_by_status,
        },
        'stops': {
            'total': total_stops,
            'delivered': delivered,
            'exceptions': exceptions,
            'skipped': skipped,
            'pending': pending,
        },
        'rates': {
            'delivery_rate_pct': delivery_rate,
            'exception_rate_pct': exception_rate,
        },
        'exception_breakdown': exception_types,
        'generated_at': datetime.now().strftime('%Y-%m-%dT%H:%M:%SZ'),
    }

    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
