#!/usr/bin/env python3
"""
Auto-create routes from a set of shipments, respecting vehicle capacity.

Usage:
    python3 tools/routes/auto_create.py --customer_id=<cid> --vehicle_id=<vid> --driver_id=<did> \
        --origin_lat=<lat> --origin_lng=<lng> [--name_prefix=Ruta] [--apply] [--shipment_ids=id1,id2,...]

Algorithm (first-fit decreasing bin-packing):
1. Sort shipments by weight (heaviest first)
2. For each shipment, try to fit it in an existing route
3. If no route has capacity, create a new route
4. Optimize each route after packing

Output: JSON with routes created and shipment assignments
"""

import json
import os
import subprocess
import sys
import argparse

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'lib'))
from distance import nearest_neighbor_order, total_route_distance


def get_project_root():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


def run_tool(tool_path, *args):
    result = subprocess.run(
        ['bash', tool_path] + list(args),
        capture_output=True, text=True,
        cwd=get_project_root()
    )
    if result.returncode != 0:
        return None, result.stderr.strip()
    try:
        return json.loads(result.stdout), None
    except json.JSONDecodeError:
        return result.stdout.strip(), None


def main():
    parser = argparse.ArgumentParser(description='Auto-create routes from shipments')
    parser.add_argument('--customer_id', required=True)
    parser.add_argument('--vehicle_id', required=True)
    parser.add_argument('--driver_id', required=True)
    parser.add_argument('--origin_lat', required=True, type=float)
    parser.add_argument('--origin_lng', required=True, type=float)
    parser.add_argument('--name_prefix', default='Ruta')
    parser.add_argument('--shipment_ids', default='', help='Comma-separated shipment IDs (or all unassigned)')
    parser.add_argument('--apply', action='store_true', help='Actually create routes (default: preview)')
    args = parser.parse_args()

    project_root = get_project_root()
    tools_dir = os.path.join(project_root, 'tools')

    # Load vehicle capacity
    vehicle_file = os.path.join(project_root, 'vehicles', args.vehicle_id, 'vehicle.json')
    if not os.path.isfile(vehicle_file):
        print(json.dumps({'error': f'Vehicle {args.vehicle_id} not found'}), file=sys.stderr)
        sys.exit(1)
    with open(vehicle_file) as f:
        vehicle = json.load(f)
    cap_kg = vehicle['capacity_kg']
    cap_m3 = vehicle['capacity_m3']

    # Load shipments
    shipments = []
    if args.shipment_ids:
        sids = [s.strip() for s in args.shipment_ids.split(',') if s.strip()]
    else:
        # Find all unassigned shipments for this customer
        sids = []
        shipments_dir = os.path.join(project_root, 'shipments')
        if os.path.isdir(shipments_dir):
            for sid in os.listdir(shipments_dir):
                sfile = os.path.join(shipments_dir, sid, 'shipment.json')
                if not os.path.isfile(sfile):
                    continue
                with open(sfile) as f:
                    s = json.load(f)
                if s.get('customer_id') == args.customer_id and not s.get('route_id'):
                    sids.append(sid)

    for sid in sids:
        sfile = os.path.join(project_root, 'shipments', sid, 'shipment.json')
        if os.path.isfile(sfile):
            with open(sfile) as f:
                shipments.append(json.load(f))

    if not shipments:
        print(json.dumps({'message': 'No shipments to assign', 'routes': []}))
        return

    # Sort by weight descending (first-fit decreasing)
    shipments.sort(key=lambda s: s.get('total_weight_kg', 0), reverse=True)

    # Bin-packing
    routes = []  # Each: {weight, volume, shipments: [...]}

    for ship in shipments:
        w = ship.get('total_weight_kg', 0)
        v = ship.get('total_volume_m3', 0)

        placed = False
        for route in routes:
            if route['weight'] + w <= cap_kg and route['volume'] + v <= cap_m3:
                route['weight'] += w
                route['volume'] += v
                route['shipments'].append(ship)
                placed = True
                break

        if not placed:
            routes.append({
                'weight': w,
                'volume': v,
                'shipments': [ship]
            })

    # Build result
    result = {
        'customer_id': args.customer_id,
        'vehicle_id': args.vehicle_id,
        'driver_id': args.driver_id,
        'total_shipments': len(shipments),
        'total_routes': len(routes),
        'capacity_kg': cap_kg,
        'capacity_m3': cap_m3,
        'applied': False,
        'routes': []
    }

    for idx, route in enumerate(routes, 1):
        name = f"{args.name_prefix} {idx:03d}"

        # Calculate optimized order
        origin = [args.origin_lat, args.origin_lng]
        stop_points = [[s['lat'], s['lng']] for s in route['shipments']]
        optimized_order = nearest_neighbor_order(origin, stop_points)
        optimized_shipments = [route['shipments'][i] for i in optimized_order]
        optimized_points = [origin] + [stop_points[i] for i in optimized_order]
        distance = total_route_distance(optimized_points)

        route_info = {
            'name': name,
            'total_stops': len(route['shipments']),
            'total_weight_kg': round(route['weight'], 2),
            'total_volume_m3': round(route['volume'], 3),
            'weight_utilization_pct': round(route['weight'] / cap_kg * 100, 1),
            'volume_utilization_pct': round(route['volume'] / cap_m3 * 100, 1),
            'estimated_distance_km': round(distance, 2),
            'shipment_ids': [s['id'] for s in optimized_shipments],
        }

        if args.apply:
            # Create route
            route_result, err = run_tool(
                os.path.join(tools_dir, 'routes', 'create.sh'),
                f'name={name}',
                f'customer_id={args.customer_id}',
                f'driver_id={args.driver_id}',
                f'vehicle_id={args.vehicle_id}',
                f'origin_lat={args.origin_lat}',
                f'origin_lng={args.origin_lng}'
            )
            if err:
                route_info['error'] = err
            else:
                rid = route_result['id']
                route_info['route_id'] = rid

                # Add stops in optimized order
                for seq, ship in enumerate(optimized_shipments, 1):
                    run_tool(
                        os.path.join(tools_dir, 'routes', 'stops', 'create.sh'),
                        f'route_id={rid}',
                        f'shipment_id={ship["id"]}',
                        f'sequence={seq}'
                    )

        result['routes'].append(route_info)

    result['applied'] = args.apply
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
