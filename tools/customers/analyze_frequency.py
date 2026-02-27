#!/usr/bin/env python3
"""
Analyze customer delivery frequency and categorize.

Usage:
    python3 tools/customers/analyze_frequency.py [--customer_id=<cid>] [--apply]

Categories (based on shipments per month):
- super_frecuente: >= 100 shipments/month
- muy_frecuente: >= 30 shipments/month
- frecuente: >= 10 shipments/month
- no_frecuente: < 10 shipments/month
"""

import json
import os
import sys
import argparse
from datetime import datetime, timezone, timedelta
from collections import defaultdict


def get_project_root():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--customer_id', default='')
    parser.add_argument('--apply', action='store_true', help='Update customer frequency_category')
    args = parser.parse_args()

    project_root = get_project_root()
    shipments_dir = os.path.join(project_root, 'shipments')
    customers_dir = os.path.join(project_root, 'customers')

    # Count shipments per customer per month
    customer_monthly = defaultdict(lambda: defaultdict(int))

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
            created = ship.get('created', '')
            if created:
                month = created[:7]  # YYYY-MM
                customer_monthly[cid][month] += 1

    results = []
    for cid, months in customer_monthly.items():
        if not months:
            continue

        total = sum(months.values())
        num_months = len(months)
        avg_per_month = round(total / num_months, 1)

        if avg_per_month >= 100:
            category = 'super_frecuente'
        elif avg_per_month >= 30:
            category = 'muy_frecuente'
        elif avg_per_month >= 10:
            category = 'frecuente'
        else:
            category = 'no_frecuente'

        # Load customer name
        cname = cid
        cfile = os.path.join(customers_dir, cid, 'customer.json')
        if os.path.isfile(cfile):
            with open(cfile) as f:
                cdata = json.load(f)
            cname = cdata.get('name', cid)

            if args.apply:
                cdata['frequency_category'] = category
                cdata['updated'] = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
                with open(cfile, 'w') as f:
                    json.dump(cdata, f, indent=2)

        results.append({
            'customer_id': cid,
            'customer_name': cname,
            'total_shipments': total,
            'active_months': num_months,
            'avg_per_month': avg_per_month,
            'frequency_category': category,
            'monthly_breakdown': dict(months),
        })

    results.sort(key=lambda r: r['avg_per_month'], reverse=True)

    print(json.dumps({
        'total_customers': len(results),
        'applied': args.apply,
        'customers': results
    }, indent=2))


if __name__ == '__main__':
    main()
