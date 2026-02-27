#!/usr/bin/env python3
"""
Generate statistics per zone: shipment counts, delivery rates, avg distance.

Usage:
    python3 tools/zones/zone_stats.py [--zone_id=<zid>]
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
    parser.add_argument('--zone_id', default='')
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
                    z = json.load(f)
                if args.zone_id and z['id'] != args.zone_id:
                    continue
                zones[z['id']] = {
                    'zone_id': z['id'],
                    'zone_name': z['name'],
                    'center_lat': z['center_lat'],
                    'center_lng': z['center_lng'],
                    'radius_km': z.get('radius_km', 0),
                    'shipments': 0,
                    'delivered': 0,
                    'exceptions': 0,
                    'total_weight_kg': 0,
                    'distances': [],
                }

    # Count shipments per zone
    shipments_dir = os.path.join(project_root, 'shipments')
    if os.path.isdir(shipments_dir):
        for sid in os.listdir(shipments_dir):
            sf = os.path.join(shipments_dir, sid, 'shipment.json')
            if not os.path.isfile(sf):
                continue
            with open(sf) as f:
                ship = json.load(f)
            zid = ship.get('zone_id', '')
            if zid and zid in zones:
                z = zones[zid]
                z['shipments'] += 1
                z['total_weight_kg'] += ship.get('total_weight_kg', 0)
                st = ship.get('status', '')
                if st == 'delivered':
                    z['delivered'] += 1
                elif st == 'exception':
                    z['exceptions'] += 1
                dist = haversine(ship['lat'], ship['lng'], z['center_lat'], z['center_lng'])
                z['distances'].append(dist)

    results = []
    for zid, z in zones.items():
        completed = z['delivered'] + z['exceptions']
        z['delivery_rate_pct'] = round(z['delivered'] / completed * 100, 1) if completed > 0 else 0
        z['avg_distance_km'] = round(sum(z['distances']) / len(z['distances']), 2) if z['distances'] else 0
        z['total_weight_kg'] = round(z['total_weight_kg'], 2)
        del z['distances']
        del z['center_lat']
        del z['center_lng']
        results.append(z)

    results.sort(key=lambda z: z['shipments'], reverse=True)
    print(json.dumps({'zones': results}, indent=2))


if __name__ == '__main__':
    main()
