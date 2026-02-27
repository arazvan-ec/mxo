#!/usr/bin/env python3
"""
Cost analysis: €/route, €/bulto, total costs by customer.

Usage:
    python3 tools/reports/cost_analysis.py [--customer_id=<cid>] [--cost_per_route=50] [--cost_per_package=2]
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
    parser.add_argument('--cost_per_route', type=float, default=50.0)
    parser.add_argument('--cost_per_package', type=float, default=2.0)
    args = parser.parse_args()

    project_root = get_project_root()
    routes_dir = os.path.join(project_root, 'routes')
    customers_dir = os.path.join(project_root, 'customers')

    from collections import defaultdict
    costs = defaultdict(lambda: {
        'routes': 0, 'packages': 0, 'delivered': 0,
        'weight_kg': 0, 'distance_km': 0
    })

    if os.path.isdir(routes_dir):
        for rid in os.listdir(routes_dir):
            rf = os.path.join(routes_dir, rid, 'route.json')
            if not os.path.isfile(rf):
                continue
            with open(rf) as f:
                route = json.load(f)
            cid = route.get('customer_id', '')
            if not cid:
                continue
            if args.customer_id and cid != args.customer_id:
                continue

            c = costs[cid]
            c['routes'] += 1
            c['distance_km'] += route.get('total_distance_km', 0)

            stops_dir = os.path.join(routes_dir, rid, 'stops')
            if os.path.isdir(stops_dir):
                for sid in os.listdir(stops_dir):
                    sf = os.path.join(stops_dir, sid, 'stop.json')
                    if not os.path.isfile(sf):
                        continue
                    with open(sf) as f:
                        stop = json.load(f)
                    ship_id = stop.get('shipment_id', '')
                    if ship_id:
                        ship_file = os.path.join(project_root, 'shipments', ship_id, 'shipment.json')
                        if os.path.isfile(ship_file):
                            with open(ship_file) as f:
                                ship = json.load(f)
                            c['packages'] += ship.get('total_packages', 0)
                            c['weight_kg'] += ship.get('total_weight_kg', 0)
                    if stop.get('status') == 'delivered':
                        c['delivered'] += 1

    results = []
    for cid, c in costs.items():
        cname = cid
        cfile = os.path.join(customers_dir, cid, 'customer.json')
        if os.path.isfile(cfile):
            with open(cfile) as f:
                cname = json.load(f).get('name', cid)

        route_cost = c['routes'] * args.cost_per_route
        package_cost = c['packages'] * args.cost_per_package
        total_cost = route_cost + package_cost

        results.append({
            'customer_id': cid,
            'customer_name': cname,
            'routes': c['routes'],
            'packages': c['packages'],
            'delivered': c['delivered'],
            'total_weight_kg': round(c['weight_kg'], 2),
            'total_distance_km': round(c['distance_km'], 2),
            'cost_breakdown': {
                'route_cost_eur': round(route_cost, 2),
                'package_cost_eur': round(package_cost, 2),
                'total_cost_eur': round(total_cost, 2),
            },
            'unit_costs': {
                'eur_per_route': args.cost_per_route,
                'eur_per_package': args.cost_per_package,
                'eur_per_delivery': round(total_cost / c['delivered'], 2) if c['delivered'] > 0 else 0,
                'eur_per_km': round(total_cost / c['distance_km'], 2) if c['distance_km'] > 0 else 0,
            }
        })

    results.sort(key=lambda r: r['cost_breakdown']['total_cost_eur'], reverse=True)
    grand_total = sum(r['cost_breakdown']['total_cost_eur'] for r in results)

    print(json.dumps({
        'grand_total_eur': round(grand_total, 2),
        'customers': results,
    }, indent=2))


if __name__ == '__main__':
    main()
