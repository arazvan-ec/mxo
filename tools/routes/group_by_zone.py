#!/usr/bin/env python3
"""
Group shipments by zone and suggest route creation per zone.

Usage:
    python3 tools/routes/group_by_zone.py --customer_id=<cid>

Shows how many shipments fall in each zone and suggests routes.
"""

import json
import os
import sys
import argparse
from collections import defaultdict

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'lib'))
from distance import haversine


def get_project_root():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--customer_id', required=True)
    args = parser.parse_args()

    project_root = get_project_root()

    # Load zones
    zones = {}
    zones_dir = os.path.join(project_root, 'zones')
    if os.path.isdir(zones_dir):
        for zid in os.listdir(zones_dir):
            zf = os.path.join(zones_dir, zid, 'zone.json')
            if os.path.isfile(zf):
                with open(zf) as f:
                    zones[json.load(f)['id']] = json.load(open(zf))

    # Group unassigned shipments by zone
    groups = defaultdict(list)
    unzoned = []

    shipments_dir = os.path.join(project_root, 'shipments')
    if os.path.isdir(shipments_dir):
        for sid in os.listdir(shipments_dir):
            sf = os.path.join(shipments_dir, sid, 'shipment.json')
            if not os.path.isfile(sf):
                continue
            with open(sf) as f:
                ship = json.load(f)
            if ship.get('customer_id') != args.customer_id:
                continue
            if ship.get('route_id'):
                continue  # Already assigned to route

            zid = ship.get('zone_id', '')
            if zid and zid in zones:
                groups[zid].append(ship)
            else:
                # Try to find best zone
                best_zone = None
                best_dist = float('inf')
                for z in zones.values():
                    dist = haversine(ship['lat'], ship['lng'], z['center_lat'], z['center_lng'])
                    if dist <= z.get('radius_km', 0) and dist < best_dist:
                        best_dist = dist
                        best_zone = z
                if best_zone:
                    groups[best_zone['id']].append(ship)
                else:
                    unzoned.append(ship)

    result = {
        'customer_id': args.customer_id,
        'zones': [],
        'unzoned_shipments': len(unzoned),
    }

    for zid, ships in groups.items():
        zone = zones[zid]
        total_kg = sum(s.get('total_weight_kg', 0) for s in ships)
        total_m3 = sum(s.get('total_volume_m3', 0) for s in ships)

        result['zones'].append({
            'zone_id': zid,
            'zone_name': zone['name'],
            'shipments': len(ships),
            'total_weight_kg': round(total_kg, 2),
            'total_volume_m3': round(total_m3, 3),
            'shipment_ids': [s['id'] for s in ships],
        })

    result['zones'].sort(key=lambda z: z['shipments'], reverse=True)
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
