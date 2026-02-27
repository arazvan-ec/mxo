#!/usr/bin/env python3
"""
Generate per-customer report (billing-ready).

Usage:
    python3 tools/reports/customer_report.py [--customer_id=<cid>] [--date_from=YYYY-MM-DD]

Output: JSON with per-customer shipment counts, delivery rates, and billing summary.
"""

import json
import os
import sys
import argparse


def get_project_root():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--customer_id', default='')
    parser.add_argument('--date_from', default='')
    args = parser.parse_args()

    project_root = get_project_root()
    customers_dir = os.path.join(project_root, 'customers')
    shipments_dir = os.path.join(project_root, 'shipments')
    routes_dir = os.path.join(project_root, 'routes')

    stats = {}

    # Count shipments per customer
    if os.path.isdir(shipments_dir):
        for sid in os.listdir(shipments_dir):
            sf = os.path.join(shipments_dir, sid, 'shipment.json')
            if not os.path.isfile(sf):
                continue
            with open(sf) as f:
                ship = json.load(f)
            cid = ship.get('customer_id', '')
            if not cid:
                continue
            if args.customer_id and cid != args.customer_id:
                continue
            if args.date_from and ship.get('created', '') < args.date_from:
                continue

            if cid not in stats:
                cname = cid
                cfile = os.path.join(customers_dir, cid, 'customer.json')
                if os.path.isfile(cfile):
                    with open(cfile) as f:
                        cname = json.load(f).get('name', cid)
                stats[cid] = {
                    'customer_id': cid,
                    'customer_name': cname,
                    'total_shipments': 0,
                    'total_packages': 0,
                    'total_weight_kg': 0,
                    'total_volume_m3': 0,
                    'by_status': {},
                    'routes': 0,
                    'routes_completed': 0,
                }
            stats[cid]['total_shipments'] += 1
            stats[cid]['total_packages'] += ship.get('total_packages', 0)
            stats[cid]['total_weight_kg'] += ship.get('total_weight_kg', 0)
            stats[cid]['total_volume_m3'] += ship.get('total_volume_m3', 0)
            st = ship.get('status', 'unknown')
            stats[cid]['by_status'][st] = stats[cid]['by_status'].get(st, 0) + 1

    # Count routes per customer
    if os.path.isdir(routes_dir):
        for rid in os.listdir(routes_dir):
            rf = os.path.join(routes_dir, rid, 'route.json')
            if not os.path.isfile(rf):
                continue
            with open(rf) as f:
                route = json.load(f)
            cid = route.get('customer_id', '')
            if cid in stats:
                stats[cid]['routes'] += 1
                if route.get('status') == 'done':
                    stats[cid]['routes_completed'] += 1

    customers = list(stats.values())
    for c in customers:
        delivered = c['by_status'].get('delivered', 0)
        total = c['total_shipments']
        c['delivery_rate_pct'] = round(delivered / total * 100, 1) if total > 0 else 0
        c['total_weight_kg'] = round(c['total_weight_kg'], 2)
        c['total_volume_m3'] = round(c['total_volume_m3'], 3)

    customers.sort(key=lambda c: c['total_shipments'], reverse=True)

    print(json.dumps({
        'total_customers': len(customers),
        'customers': customers
    }, indent=2))


if __name__ == '__main__':
    main()
