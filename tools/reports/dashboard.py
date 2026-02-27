#!/usr/bin/env python3
"""
Generate operational dashboard data.

Usage:
    python3 tools/reports/dashboard.py

Output: JSON with KPIs for the dashboard view.
"""

import json
import os
import sys
from datetime import datetime, timezone


def get_project_root():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


def count_entities(entity_dir):
    if not os.path.isdir(entity_dir):
        return 0
    return sum(1 for d in os.listdir(entity_dir) if os.path.isdir(os.path.join(entity_dir, d)))


def main():
    project_root = get_project_root()
    now = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

    # Count entities
    customers = count_entities(os.path.join(project_root, 'customers'))
    vehicles = count_entities(os.path.join(project_root, 'vehicles'))
    drivers = count_entities(os.path.join(project_root, 'drivers'))

    # Route stats
    routes_dir = os.path.join(project_root, 'routes')
    route_stats = {'planned': 0, 'active': 0, 'done': 0, 'cancelled': 0}
    total_delivered = 0
    total_exceptions = 0
    total_pending = 0

    if os.path.isdir(routes_dir):
        for rid in os.listdir(routes_dir):
            rf = os.path.join(routes_dir, rid, 'route.json')
            if not os.path.isfile(rf):
                continue
            with open(rf) as f:
                route = json.load(f)
            st = route.get('status', 'planned')
            route_stats[st] = route_stats.get(st, 0) + 1
            total_delivered += route.get('stops_delivered', 0)
            total_exceptions += route.get('stops_exception', 0)
            total_pending += route.get('stops_pending', 0)

    # Shipment stats
    shipments_dir = os.path.join(project_root, 'shipments')
    shipment_stats = {}
    total_shipments = 0
    total_packages = 0
    total_weight = 0

    if os.path.isdir(shipments_dir):
        for sid in os.listdir(shipments_dir):
            sf = os.path.join(shipments_dir, sid, 'shipment.json')
            if not os.path.isfile(sf):
                continue
            with open(sf) as f:
                ship = json.load(f)
            total_shipments += 1
            total_packages += ship.get('total_packages', 0)
            total_weight += ship.get('total_weight_kg', 0)
            st = ship.get('status', 'unknown')
            shipment_stats[st] = shipment_stats.get(st, 0) + 1

    completed = total_delivered + total_exceptions
    delivery_rate = round(total_delivered / completed * 100, 1) if completed > 0 else 0

    dashboard = {
        'generated_at': now,
        'entities': {
            'customers': customers,
            'vehicles': vehicles,
            'drivers': drivers,
            'shipments': total_shipments,
            'total_packages': total_packages,
            'total_weight_kg': round(total_weight, 2),
        },
        'routes': {
            'by_status': route_stats,
            'total': sum(route_stats.values()),
        },
        'deliveries': {
            'delivered': total_delivered,
            'exceptions': total_exceptions,
            'pending': total_pending,
            'delivery_rate_pct': delivery_rate,
        },
        'shipments_by_status': shipment_stats,
    }

    print(json.dumps(dashboard, indent=2))


if __name__ == '__main__':
    main()
