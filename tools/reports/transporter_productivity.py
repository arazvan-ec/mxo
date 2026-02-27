#!/usr/bin/env python3
"""
Transporter (driver) productivity analysis.

Usage:
    python3 tools/reports/transporter_productivity.py [--driver_id=<did>] [--zone_id=<zid>] [--date_from=YYYY-MM-DD]

Metrics: success rate per zone, deliveries/day, €/route, €/package.
"""

import json
import os
import sys
import argparse
from collections import defaultdict
from datetime import datetime


def get_project_root():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--driver_id', default='')
    parser.add_argument('--zone_id', default='')
    parser.add_argument('--date_from', default='')
    parser.add_argument('--cost_per_route', type=float, default=50.0)
    parser.add_argument('--cost_per_package', type=float, default=2.0)
    args = parser.parse_args()

    project_root = get_project_root()
    routes_dir = os.path.join(project_root, 'routes')
    drivers_dir = os.path.join(project_root, 'drivers')

    drivers = defaultdict(lambda: {
        'routes': 0, 'routes_completed': 0,
        'total_stops': 0, 'delivered': 0, 'exceptions': 0,
        'total_packages': 0, 'total_weight_kg': 0,
        'days': set(), 'zone_stats': defaultdict(lambda: {'delivered': 0, 'exceptions': 0}),
    })

    if not os.path.isdir(routes_dir):
        print(json.dumps({'drivers': []}))
        return

    for rid in os.listdir(routes_dir):
        rf = os.path.join(routes_dir, rid, 'route.json')
        if not os.path.isfile(rf):
            continue
        with open(rf) as f:
            route = json.load(f)

        did = route.get('driver_id', '')
        if not did:
            continue
        if args.driver_id and did != args.driver_id:
            continue
        if args.date_from and route.get('created', '') < args.date_from:
            continue

        d = drivers[did]
        d['routes'] += 1
        if route.get('status') == 'done':
            d['routes_completed'] += 1

        day = route.get('created', '')[:10]
        if day:
            d['days'].add(day)

        stops_dir = os.path.join(routes_dir, rid, 'stops')
        if not os.path.isdir(stops_dir):
            continue

        for sid in os.listdir(stops_dir):
            sf = os.path.join(stops_dir, sid, 'stop.json')
            if not os.path.isfile(sf):
                continue
            with open(sf) as f:
                stop = json.load(f)

            d['total_stops'] += 1
            st = stop.get('status')

            # Get shipment for zone and package info
            ship_id = stop.get('shipment_id', '')
            zone_id = ''
            if ship_id:
                ship_file = os.path.join(project_root, 'shipments', ship_id, 'shipment.json')
                if os.path.isfile(ship_file):
                    with open(ship_file) as f:
                        ship = json.load(f)
                    zone_id = ship.get('zone_id', '')
                    d['total_packages'] += ship.get('total_packages', 0)
                    d['total_weight_kg'] += ship.get('total_weight_kg', 0)

            if args.zone_id and zone_id != args.zone_id:
                continue

            if st == 'delivered':
                d['delivered'] += 1
                if zone_id:
                    d['zone_stats'][zone_id]['delivered'] += 1
            elif st == 'exception':
                d['exceptions'] += 1
                if zone_id:
                    d['zone_stats'][zone_id]['exceptions'] += 1

    results = []
    for did, d in drivers.items():
        dname = did
        dfile = os.path.join(drivers_dir, did, 'driver.json')
        if os.path.isfile(dfile):
            with open(dfile) as f:
                dname = json.load(f).get('name', did)

        completed = d['delivered'] + d['exceptions']
        active_days = len(d['days'])

        entry = {
            'driver_id': did,
            'driver_name': dname,
            'routes': d['routes'],
            'routes_completed': d['routes_completed'],
            'total_stops': d['total_stops'],
            'delivered': d['delivered'],
            'exceptions': d['exceptions'],
            'success_rate_pct': round(d['delivered'] / completed * 100, 1) if completed > 0 else 0,
            'total_packages': d['total_packages'],
            'total_weight_kg': round(d['total_weight_kg'], 2),
            'active_days': active_days,
            'deliveries_per_day': round(d['delivered'] / active_days, 1) if active_days > 0 else 0,
            'cost_per_route_eur': args.cost_per_route,
            'cost_per_package_eur': args.cost_per_package,
            'total_route_cost_eur': round(d['routes'] * args.cost_per_route, 2),
            'total_package_cost_eur': round(d['total_packages'] * args.cost_per_package, 2),
            'avg_cost_per_delivery_eur': round(
                (d['routes'] * args.cost_per_route) / d['delivered'], 2
            ) if d['delivered'] > 0 else 0,
        }

        # Zone breakdown
        if d['zone_stats']:
            entry['zone_performance'] = []
            for zid, zs in d['zone_stats'].items():
                zt = zs['delivered'] + zs['exceptions']
                entry['zone_performance'].append({
                    'zone_id': zid,
                    'delivered': zs['delivered'],
                    'exceptions': zs['exceptions'],
                    'success_rate_pct': round(zs['delivered'] / zt * 100, 1) if zt > 0 else 0,
                })

        results.append(entry)

    results.sort(key=lambda d: d['success_rate_pct'], reverse=True)
    for i, r in enumerate(results, 1):
        r['rank'] = i

    print(json.dumps({
        'total_drivers': len(results),
        'drivers': results,
    }, indent=2))


if __name__ == '__main__':
    main()
