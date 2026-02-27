#!/usr/bin/env python3
"""
Analyze delivery trends over time (weekly/monthly).

Usage:
    python3 tools/reports/trends.py [--customer_id=<cid>] [--period=monthly]

Periods: weekly, monthly
"""

import json
import os
import sys
import argparse
from collections import defaultdict
from datetime import datetime, timedelta


def get_project_root():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


def get_week_key(date_str):
    """Get ISO week key from date string."""
    try:
        dt = datetime.fromisoformat(date_str.replace('Z', '+00:00'))
        return f"{dt.isocalendar()[0]}-W{dt.isocalendar()[1]:02d}"
    except (ValueError, AttributeError):
        return 'unknown'


def get_month_key(date_str):
    """Get month key from date string."""
    try:
        return date_str[:7]
    except (TypeError, IndexError):
        return 'unknown'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--customer_id', default='')
    parser.add_argument('--period', default='monthly', choices=['weekly', 'monthly'])
    args = parser.parse_args()

    project_root = get_project_root()
    routes_dir = os.path.join(project_root, 'routes')

    key_fn = get_month_key if args.period == 'monthly' else get_week_key

    periods = defaultdict(lambda: {
        'routes': 0, 'stops': 0, 'delivered': 0, 'exceptions': 0,
        'packages': 0, 'weight_kg': 0, 'distance_km': 0,
    })

    if os.path.isdir(routes_dir):
        for rid in os.listdir(routes_dir):
            rf = os.path.join(routes_dir, rid, 'route.json')
            if not os.path.isfile(rf):
                continue
            with open(rf) as f:
                route = json.load(f)

            if args.customer_id and route.get('customer_id') != args.customer_id:
                continue

            key = key_fn(route.get('created', ''))
            p = periods[key]
            p['routes'] += 1
            p['distance_km'] += route.get('total_distance_km', 0)

            stops_dir = os.path.join(routes_dir, rid, 'stops')
            if os.path.isdir(stops_dir):
                for sid in os.listdir(stops_dir):
                    sf = os.path.join(stops_dir, sid, 'stop.json')
                    if not os.path.isfile(sf):
                        continue
                    with open(sf) as f:
                        stop = json.load(f)
                    p['stops'] += 1
                    st = stop.get('status')
                    if st == 'delivered':
                        p['delivered'] += 1
                    elif st == 'exception':
                        p['exceptions'] += 1

                    ship_id = stop.get('shipment_id', '')
                    if ship_id:
                        ship_file = os.path.join(project_root, 'shipments', ship_id, 'shipment.json')
                        if os.path.isfile(ship_file):
                            with open(ship_file) as f:
                                ship = json.load(f)
                            p['packages'] += ship.get('total_packages', 0)
                            p['weight_kg'] += ship.get('total_weight_kg', 0)

    # Build sorted results
    trend_data = []
    for key in sorted(periods.keys()):
        p = periods[key]
        completed = p['delivered'] + p['exceptions']
        trend_data.append({
            'period': key,
            'routes': p['routes'],
            'stops': p['stops'],
            'delivered': p['delivered'],
            'exceptions': p['exceptions'],
            'delivery_rate_pct': round(p['delivered'] / completed * 100, 1) if completed > 0 else 0,
            'packages': p['packages'],
            'weight_kg': round(p['weight_kg'], 2),
            'distance_km': round(p['distance_km'], 2),
        })

    # Calculate period-over-period changes
    for i in range(1, len(trend_data)):
        prev = trend_data[i - 1]
        curr = trend_data[i]
        if prev['delivered'] > 0:
            curr['delivery_change_pct'] = round(
                (curr['delivered'] - prev['delivered']) / prev['delivered'] * 100, 1
            )
        else:
            curr['delivery_change_pct'] = 0

    print(json.dumps({
        'period_type': args.period,
        'customer_id': args.customer_id or 'all',
        'total_periods': len(trend_data),
        'trends': trend_data,
    }, indent=2))


if __name__ == '__main__':
    main()
