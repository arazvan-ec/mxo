#!/usr/bin/env python3
"""
Assign shipments to zones based on geographic proximity.

Usage:
    python3 tools/zones/assign_shipment.py [--shipment_id=<sid>] [--apply]

Assigns each shipment to the closest zone whose radius contains it.
"""

import json
import os
import sys
import argparse

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'lib'))
from distance import haversine


def get_project_root():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--shipment_id', default='')
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()

    project_root = get_project_root()

    # Load zones
    zones = []
    zones_dir = os.path.join(project_root, 'zones')
    if os.path.isdir(zones_dir):
        for zid in os.listdir(zones_dir):
            zf = os.path.join(zones_dir, zid, 'zone.json')
            if os.path.isfile(zf):
                with open(zf) as f:
                    zones.append(json.load(f))

    if not zones:
        print(json.dumps({'message': 'No zones defined', 'assignments': []}))
        return

    # Load shipments
    shipments = []
    shipments_dir = os.path.join(project_root, 'shipments')
    if os.path.isdir(shipments_dir):
        for sid in os.listdir(shipments_dir):
            sf = os.path.join(shipments_dir, sid, 'shipment.json')
            if not os.path.isfile(sf):
                continue
            with open(sf) as f:
                ship = json.load(f)
            if args.shipment_id and ship['id'] != args.shipment_id:
                continue
            shipments.append(ship)

    assignments = []
    for ship in shipments:
        best_zone = None
        best_dist = float('inf')

        for zone in zones:
            dist = haversine(
                ship['lat'], ship['lng'],
                zone['center_lat'], zone['center_lng']
            )
            radius_km = zone.get('radius_km', 0)
            if dist <= radius_km and dist < best_dist:
                best_dist = dist
                best_zone = zone

        assignment = {
            'shipment_id': ship['id'],
            'reference': ship.get('reference', ''),
            'zone_id': best_zone['id'] if best_zone else None,
            'zone_name': best_zone['name'] if best_zone else None,
            'distance_to_center_km': round(best_dist, 2) if best_zone else None,
        }

        if args.apply and best_zone:
            sf = os.path.join(shipments_dir, ship['id'], 'shipment.json')
            ship['zone_id'] = best_zone['id']
            with open(sf, 'w') as f:
                json.dump(ship, f, indent=2)

        assignments.append(assignment)

    assigned = sum(1 for a in assignments if a['zone_id'])
    unassigned = len(assignments) - assigned

    print(json.dumps({
        'total_shipments': len(assignments),
        'assigned': assigned,
        'unassigned': unassigned,
        'applied': args.apply,
        'assignments': assignments,
    }, indent=2))


if __name__ == '__main__':
    main()
